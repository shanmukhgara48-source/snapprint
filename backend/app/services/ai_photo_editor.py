import asyncio
import base64
import json
import os
import struct
import uuid
from dataclasses import dataclass
from io import BytesIO
from urllib.parse import urlparse

import boto3
import httpx
from fastapi import HTTPException

from ..config import settings
from ..schemas.ai_editor import AiAnalyzeResponse, AiEditResponse


_ALLOWED_OPERATIONS = {
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
    def __init__(self) -> None:
        self._public_base = settings.r2_public_url.rstrip("/")

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
    ) -> AiEditResponse:
        operation = operation.strip().lower().replace("-", "_")
        if operation not in _ALLOWED_OPERATIONS:
            raise HTTPException(status_code=400, detail="Unsupported AI edit operation.")
        if "watermark" in prompt.lower() and not rights_confirmed:
            raise HTTPException(
                status_code=400,
                detail="Confirm that you own this image and have the right to remove the watermark.",
            )

        source = await self._download_owned_image(image_url)
        edit_prompt = self._build_edit_prompt(
            operation=operation,
            prompt=prompt,
            product_name=product_name,
            selected_size=selected_size,
            has_mask=bool(mask_image_base64),
        )
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
        )
        return AiEditResponse(
            edited_image_url=public_url,
            interaction_id=result.get("interaction_id"),
            operation=operation,
            summary=result.get("summary", ""),
        )

    async def analyze(
        self,
        *,
        image_url: str,
        product_name: str,
        selected_size: str,
    ) -> AiAnalyzeResponse:
        source = await self._download_owned_image(image_url)
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

    async def _download_owned_image(self, image_url: str) -> _ImagePayload:
        if not self._public_base:
            raise HTTPException(status_code=500, detail="R2_PUBLIC_URL is not configured.")
        parsed = urlparse(image_url)
        allowed = urlparse(self._public_base)
        if parsed.scheme not in {"https", "http"} or parsed.netloc != allowed.netloc:
            raise HTTPException(status_code=400, detail="Only SnapPrint-hosted images can be edited.")

        async with httpx.AsyncClient(timeout=30.0, follow_redirects=False) as client:
            response = await client.get(image_url)
        if response.status_code >= 400:
            raise HTTPException(status_code=400, detail="Could not fetch the selected image.")

        mime_type = response.headers.get("content-type", "image/jpeg").split(";")[0]
        if mime_type not in {"image/jpeg", "image/png", "image/webp"}:
            raise HTTPException(status_code=400, detail="Only JPEG, PNG and WebP images can be edited.")
        if len(response.content) > 12 * 1024 * 1024:
            raise HTTPException(status_code=413, detail="Image is too large for AI editing.")

        width, height = _read_image_size(response.content)
        return _ImagePayload(
            data=response.content,
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
                "image_size": "2K",
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

        return {
            "image_bytes": base64.b64decode(encoded),
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

    def _store_result(self, user_id: str, image_bytes: bytes, mime_type: str) -> str:
        ext = "png" if mime_type == "image/png" else "jpg"
        key = f"ai-edits/{user_id}/{uuid.uuid4()}.{ext}"
        client = boto3.client(
            "s3",
            endpoint_url=f"https://{settings.r2_account_id}.r2.cloudflarestorage.com",
            aws_access_key_id=settings.r2_access_key_id,
            aws_secret_access_key=settings.r2_secret_access_key,
            region_name="auto",
        )
        client.put_object(
            Bucket=settings.r2_bucket_name,
            Key=key,
            Body=image_bytes,
            ContentType=mime_type,
        )
        return f"{self._public_base}/{key}"

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
            score=int(gemini.get("score") or baseline["score"]),
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


def _read_image_size(data: bytes) -> tuple[int | None, int | None]:
    if data.startswith(b"\x89PNG\r\n\x1a\n") and len(data) >= 24:
        return struct.unpack(">II", data[16:24])
    if data.startswith(b"\xff\xd8"):
        stream = BytesIO(data)
        stream.read(2)
        while True:
            marker_prefix = stream.read(1)
            if marker_prefix != b"\xff":
                return None, None
            marker = stream.read(1)
            while marker == b"\xff":
                marker = stream.read(1)
            if marker in {b"\xc0", b"\xc2"}:
                block = stream.read(7)
                height, width = struct.unpack(">HH", block[1:5])
                return width, height
            length_bytes = stream.read(2)
            if len(length_bytes) != 2:
                return None, None
            length = struct.unpack(">H", length_bytes)[0]
            stream.seek(length - 2, 1)
    return None, None


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
