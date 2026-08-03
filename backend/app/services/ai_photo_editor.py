import asyncio
import base64
import binascii
import json
import os
import re
import uuid
from dataclasses import dataclass
from io import BytesIO

from fastapi import HTTPException
from PIL import Image

from ..config import settings
from ..schemas.ai_editor import AiAnalyzeResponse, AiEditResponse
from .r2_storage import build_media_url, owned_media_key, r2_client


_ALLOWED_OPERATIONS = {
    "auto",
    "enhance",
    "portrait",
    "background",
    "object_removal",
    "magic_eraser",
    "upscale",
    "crop",
    "colorize",
    "restore",
    "filter",
    "prompt",
}


@dataclass(frozen=True)
class _ImagePayload:
    data: bytes
    mime_type: str
    width: int | None
    height: int | None


class AiPhotoEditorService:
    async def edit(
        self,
        *,
        user_id: str,
        image_url: str,
        operation: str,
        prompt: str,
        product_name: str,
        selected_size: str,
        mask_image_base64: str | None,
        previous_interaction_id: str | None,
        rights_confirmed: bool,
        public_base_url: str,
    ) -> AiEditResponse:
        operation = operation.strip().lower().replace("-", "_")
        if operation in {"auto", "prompt"}:
            operation = _classify_prompt_operation(prompt)
        if operation not in _ALLOWED_OPERATIONS:
            raise HTTPException(status_code=400, detail="Unsupported AI edit operation.")
        if "watermark" in prompt.lower() and not rights_confirmed:
            raise HTTPException(
                status_code=400,
                detail="Confirm that you own this image and have the right to remove the watermark.",
            )

        source = await self._download_owned_image(image_url, user_id)
        edit_prompt = self._build_edit_prompt(
            operation=operation,
            prompt=prompt,
            product_name=product_name,
            selected_size=selected_size,
            has_mask=bool(mask_image_base64),
        )
        try:
            result = await asyncio.to_thread(
                self._run_gemini_edit,
                source,
                edit_prompt,
                mask_image_base64,
                previous_interaction_id,
            )
            public_url = await asyncio.to_thread(
                self._store_result,
                user_id,
                result["image_bytes"],
                result["mime_type"],
                public_base_url,
            )
        except HTTPException:
            raise
        except Exception as exc:
            raise HTTPException(
                status_code=502,
                detail="The AI editing service is temporarily unavailable.",
            ) from exc
        return AiEditResponse(
            edited_image_url=public_url,
            interaction_id=result.get("interaction_id"),
            operation=operation,
            summary=result.get("summary", ""),
        )

    async def analyze(
        self,
        *,
        user_id: str,
        image_url: str,
        product_name: str,
        selected_size: str,
    ) -> AiAnalyzeResponse:
        source = await self._download_owned_image(image_url, user_id)
        baseline = self._baseline_analysis(source, product_name, selected_size)
        try:
            gemini = await asyncio.to_thread(
                self._run_gemini_analysis,
                source,
                product_name,
                selected_size,
            )
        except HTTPException:
            gemini = {}
        except Exception:
            gemini = {}
        return self._merge_analysis(baseline, gemini)

    async def _download_owned_image(self, image_url: str, user_id: str) -> _ImagePayload:
        key = owned_media_key(image_url, str(user_id))
        if key is None:
            raise HTTPException(status_code=403, detail="You do not have access to this image.")
        try:
            result = await asyncio.to_thread(
                r2_client().get_object,
                Bucket=settings.r2_bucket_name,
                Key=key,
            )
            data = await asyncio.to_thread(result["Body"].read, settings.ai_max_source_bytes + 1)
            result["Body"].close()
        except Exception as exc:
            raise HTTPException(status_code=400, detail="Could not fetch the selected image.") from exc
        if len(data) > settings.ai_max_source_bytes:
            raise HTTPException(status_code=413, detail="Image is too large for AI editing.")
        mime_type = str(result.get("ContentType", "")).split(";", 1)[0]
        if mime_type not in {"image/jpeg", "image/png", "image/webp"}:
            raise HTTPException(status_code=400, detail="Could not fetch the selected image.")
        try:
            with Image.open(BytesIO(data)) as image:
                width, height = image.size
                image.verify()
        except (OSError, RuntimeError, ValueError) as exc:
            raise HTTPException(status_code=400, detail="The selected image is corrupt.") from exc
        if width * height > settings.ai_max_source_pixels:
            raise HTTPException(status_code=413, detail="Image dimensions exceed the AI limit.")
        return _ImagePayload(
            data=data,
            mime_type=mime_type,
            width=width,
            height=height,
        )

    def _run_gemini_edit(
        self,
        source: _ImagePayload,
        prompt: str,
        mask_image_base64: str | None,
        previous_interaction_id: str | None,
    ) -> dict:
        client = self._client()
        input_parts: list[dict] = [
            {"type": "text", "text": prompt},
            {
                "type": "image",
                "data": base64.b64encode(source.data).decode("utf-8"),
                "mime_type": source.mime_type,
            },
        ]
        if mask_image_base64:
            input_parts.append(
                {
                    "type": "image",
                    "data": _strip_data_url(mask_image_base64),
                    "mime_type": "image/png",
                }
            )

        kwargs = {
            "model": settings.gemini_image_model,
            "input": input_parts,
            "response_format": {
                "type": "image",
                "mime_type": "image/jpeg",
                "image_size": "4K",
            },
        }
        if previous_interaction_id:
            kwargs["previous_interaction_id"] = previous_interaction_id

        interaction = client.interactions.create(**kwargs)
        image_block = getattr(interaction, "output_image", None)
        if image_block is None:
            raise HTTPException(status_code=502, detail="Gemini did not return an edited image.")

        encoded = getattr(image_block, "data", None)
        if not encoded:
            raise HTTPException(status_code=502, detail="Gemini image response was empty.")

        try:
            image_bytes = base64.b64decode(encoded, validate=True)
        except (binascii.Error, TypeError, ValueError) as exc:
            raise HTTPException(status_code=502, detail="Gemini returned invalid image data.") from exc

        return {
            "image_bytes": image_bytes,
            "mime_type": getattr(image_block, "mime_type", None) or "image/jpeg",
            "interaction_id": getattr(interaction, "id", None),
            "summary": getattr(interaction, "output_text", "") or "",
        }

    def _run_gemini_analysis(
        self,
        source: _ImagePayload,
        product_name: str,
        selected_size: str,
    ) -> dict:
        client = self._client()
        prompt = (
            "Analyze this customer photo for professional photo printing. "
            "Return compact JSON only with keys: score, blur, noise, exposure, faces, "
            "crop_recommendation, suggestions. "
            f"Product: {product_name or 'photo print'}. Size: {selected_size or 'not selected'}."
        )
        interaction = client.interactions.create(
            model=settings.gemini_text_model,
            input=[
                {"type": "text", "text": prompt},
                {
                    "type": "image",
                    "data": base64.b64encode(source.data).decode("utf-8"),
                    "mime_type": source.mime_type,
                },
            ],
        )
        text = getattr(interaction, "output_text", "") or ""
        start = text.find("{")
        end = text.rfind("}")
        if start == -1 or end == -1:
            return {}
        return json.loads(text[start : end + 1])

    def _store_result(
        self,
        user_id: str,
        image_bytes: bytes,
        mime_type: str,
        public_base_url: str,
    ) -> str:
        if not image_bytes or len(image_bytes) > settings.ai_max_source_bytes:
            raise HTTPException(status_code=502, detail="AI returned an invalid image size.")
        expected_format = {"image/jpeg": "JPEG", "image/png": "PNG"}.get(mime_type)
        if expected_format is None:
            raise HTTPException(status_code=502, detail="AI returned an unsupported image type.")
        try:
            with Image.open(BytesIO(image_bytes)) as image:
                image_format = image.format
                width, height = image.size
                image.verify()
        except (OSError, RuntimeError, ValueError) as exc:
            raise HTTPException(status_code=502, detail="AI returned a corrupt image.") from exc
        if image_format != expected_format or width * height > settings.ai_max_source_pixels:
            raise HTTPException(status_code=502, detail="AI returned an invalid image.")
        ext = "png" if mime_type == "image/png" else "jpg"
        key = f"ai-edits/{user_id}/{uuid.uuid4()}.{ext}"
        r2_client().put_object(
            Bucket=settings.r2_bucket_name,
            Key=key,
            Body=image_bytes,
            ContentType=mime_type,
            CacheControl="private, max-age=31536000, immutable",
        )
        return build_media_url(public_base_url, key)

    def _client(self):
        api_key = settings.google_api_key or settings.gemini_api_key
        if not api_key and not os.getenv("GOOGLE_API_KEY") and not os.getenv("GEMINI_API_KEY"):
            raise HTTPException(status_code=503, detail="Gemini AI editor is not configured.")
        if api_key and not os.getenv("GOOGLE_API_KEY") and not os.getenv("GEMINI_API_KEY"):
            os.environ["GEMINI_API_KEY"] = api_key
        try:
            from google import genai
        except ImportError as exc:
            raise HTTPException(
                status_code=503,
                detail="google-genai is not installed on the backend.",
            ) from exc
        return genai.Client()

    def _build_edit_prompt(
        self,
        *,
        operation: str,
        prompt: str,
        product_name: str,
        selected_size: str,
        has_mask: bool,
    ) -> str:
        base = (
            "Edit the provided customer-owned photo for premium photo printing. "
            "Preserve the important people, faces, identity, composition intent, and natural realism. "
            "Avoid adding text, logos, watermarks, or artifacts. Return a high-quality print-ready photo."
        )
        context = f" Product: {product_name or 'photo product'}. Target size: {selected_size or 'not selected'}."
        prompts = {
            "enhance": "One-tap enhance: improve sharpness, lighting, color, contrast, saturation, dynamic range, haze, and overall quality naturally.",
            "portrait": "Create a professional portrait look: natural skin smoothing, face clarity, eye detail, subtle teeth whitening, hair detail, and tasteful background blur.",
            "background": f"Replace or refine the background as requested: {prompt or 'use a clean premium studio background'}. Keep subjects realistic.",
            "object_removal": f"Remove unwanted people, objects, wires, dust, text, or photobombers requested by the user: {prompt}. Reconstruct the background naturally.",
            "magic_eraser": (
                "Use the second image as a red/painted mask showing the areas to remove. "
                "Remove only the masked unwanted content and reconstruct the background naturally."
                if has_mask
                else f"Remove the unwanted content requested by the user: {prompt}."
            ),
            "upscale": f"Upscale for printing with detail restoration and noise reduction. Requested level: {prompt or '2x print-quality enhancement'}.",
            "crop": f"Suggest and apply a print-safe crop for {product_name or 'the selected print product'} while keeping faces and key subjects inside the crop.",
            "colorize": "Colorize this black-and-white or faded photograph into a realistic, historically plausible color photo.",
            "restore": "Restore this old or damaged photograph: repair scratches, faded areas, torn edges, stains, and print damage while preserving authenticity.",
            "filter": f"Apply a premium filter style: {prompt or 'luxury'}. Keep it suitable for professional printing.",
            "prompt": prompt or "Make this suitable for a premium photo print.",
        }
        return f"{base}{context} {prompts[operation]}"

    def _baseline_analysis(
        self,
        source: _ImagePayload,
        product_name: str,
        selected_size: str,
    ) -> dict:
        width = source.width or 0
        height = source.height or 0
        megapixels = (width * height) / 1_000_000 if width and height else 0
        score = 82
        suggestions: list[str] = []
        if megapixels and megapixels < 2:
            score -= 24
            suggestions.append("Use AI upscaling before ordering larger prints.")
        if source.mime_type == "image/webp":
            suggestions.append("Export final print files as JPEG for broad lab compatibility.")
        if not width or not height:
            score -= 8
            suggestions.append("Could not read image dimensions; run print analysis again after upload.")
        if "passport" in product_name.lower():
            suggestions.append("Use AI crop to keep the face centered with a clean white background.")
        if selected_size:
            suggestions.append(f"Preview the crop carefully for {selected_size}.")

        return {
            "score": max(0, min(100, score)),
            "resolution": f"{width} x {height}px" if width and height else "Unknown",
            "dpi_estimate": _estimate_dpi(width, height, selected_size),
            "blur": "Needs AI check",
            "noise": "Needs AI check",
            "exposure": "Needs AI check",
            "faces": "Needs AI check",
            "crop_recommendation": "Keep key faces away from trim edges.",
            "suggestions": suggestions or ["Image looks ready for standard photo printing."],
        }

    def _merge_analysis(self, baseline: dict, gemini: dict) -> AiAnalyzeResponse:
        suggestions = gemini.get("suggestions") or baseline["suggestions"]
        if isinstance(suggestions, str):
            suggestions = [suggestions]
        return AiAnalyzeResponse(
            score=max(0, min(100, int(gemini.get("score") or baseline["score"]))),
            resolution=baseline["resolution"],
            dpi_estimate=baseline["dpi_estimate"],
            blur=str(gemini.get("blur") or baseline["blur"]),
            noise=str(gemini.get("noise") or baseline["noise"]),
            exposure=str(gemini.get("exposure") or baseline["exposure"]),
            faces=str(gemini.get("faces") or baseline["faces"]),
            crop_recommendation=str(
                gemini.get("crop_recommendation") or baseline["crop_recommendation"]
            ),
            suggestions=[str(item) for item in suggestions][:5],
        )


def _strip_data_url(value: str) -> str:
    return value.split(",", 1)[1] if "," in value else value


def _classify_prompt_operation(prompt: str) -> str:
    text = " ".join(prompt.lower().strip().split())
    if not text:
        return "prompt"
    if _has_any(
        text,
        "remove background",
        "remove the background",
        "transparent background",
        "make the background transparent",
        "cut out",
        "cutout",
        "replace background",
        "replace the background",
        "change background",
        "change the background",
        "blur background",
        "replace the sky",
        "change the sky",
        "sky with",
        "blue sky",
        "beach",
        "mountain",
        "forest",
        "office",
        "cafe",
        "space",
        "moon",
    ):
        return "background"
    if _has_any(
        text,
        "remove people",
        "remove person",
        "remove object",
        "remove objects",
        "remove chair",
        "chair",
        "car",
        "dog",
        "cat",
        "remove wire",
        "remove wires",
        "remove text",
        "photobomber",
        "watermark",
    ):
        return "object_removal"
    if _has_any(
        text,
        "upscale",
        "4k",
        "super resolution",
        "increase quality",
        "sharpen",
        "deblur",
        "denoise",
    ):
        return "upscale"
    if _has_any(text, "colorize", "colourize"):
        return "colorize"
    if _has_any(
        text,
        "restore",
        "scratch",
        "scratches",
        "faded",
        "torn",
        "old photo",
        "repair",
    ):
        return "restore"
    if _has_any(
        text,
        "face",
        "smile",
        "acne",
        "wrinkle",
        "teeth",
        "eye",
        "hair",
        "portrait",
    ):
        return "portrait"
    if _has_any(
        text,
        "anime",
        "pixar",
        "disney",
        "ghibli",
        "cartoon",
        "pencil",
        "sketch",
        "watercolor",
        "oil painting",
        "pop art",
        "comic",
        "clay",
        "lego",
        "minecraft",
        "cyberpunk",
        "vaporwave",
        "cinematic",
        "vintage",
        "matte",
        "film",
        "warm",
        "cool",
        "black and white",
        "black & white",
        "grayscale",
        "monochrome",
    ):
        return "filter"
    if _has_any(
        text,
        "enhance",
        "hdr",
        "brightness",
        "contrast",
        "saturation",
        "professional",
    ):
        return "enhance"
    return "prompt"


def _has_any(text: str, *needles: str) -> bool:
    return any(
        re.search(rf"(?<![a-z0-9]){re.escape(needle)}(?![a-z0-9])", text)
        for needle in needles
    )


def _estimate_dpi(width: int, height: int, selected_size: str) -> str:
    if not width or not height or "x" not in selected_size.lower():
        return "Select a size for DPI estimate"
    try:
        size = selected_size.lower().replace("in", "").split()[0]
        w_in, h_in = [float(part) for part in size.split("x", 1)]
    except Exception:
        return "Could not estimate from selected size"
    dpi = int(min(width / max(w_in, 0.1), height / max(h_in, 0.1)))
    return f"~{dpi} DPI"
