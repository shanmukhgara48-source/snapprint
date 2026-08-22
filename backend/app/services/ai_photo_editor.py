import asyncio
import base64
import json
import logging
import re
import uuid
from dataclasses import dataclass
from io import BytesIO

from fastapi import HTTPException
from PIL import Image

from ..config import settings
from ..schemas.ai_editor import AiAnalyzeResponse, AiEditResponse
from .r2_storage import build_media_url, owned_media_key, r2_client

logger = logging.getLogger(__name__)

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
    # Extended 12-category operations
    "style_transfer",
    "scene_transform",
    "fashion_edit",
    "interior_design",
    "text_graphic",
    "multi_image",
    "color_lighting",
    "photo_enhance",
}

# In-memory conversation context for multi-turn editing sessions
_CONVERSATION_CONTEXT: dict[str, dict] = {}


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

        # Build conversation context for multi-turn editing
        conversation_history = ""
        if previous_interaction_id and previous_interaction_id in _CONVERSATION_CONTEXT:
            ctx = _CONVERSATION_CONTEXT[previous_interaction_id]
            conversation_history = ctx.get("history", "")

        edit_prompt = self._build_edit_prompt(
            operation=operation,
            prompt=prompt,
            product_name=product_name,
            selected_size=selected_size,
            has_mask=bool(mask_image_base64),
            conversation_history=conversation_history,
        )
        try:
            result = await asyncio.to_thread(
                self._run_hf_edit,
                source,
                edit_prompt,
                mask_image_base64,
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

        # Track conversation for multi-turn editing
        interaction_id = str(uuid.uuid4())
        prev_history = f"{conversation_history} | " if conversation_history else ""
        _CONVERSATION_CONTEXT[interaction_id] = {
            "operation": operation,
            "prompt": prompt,
            "history": f"{prev_history}{operation}: {prompt[:200]}",
        }
        # Limit context store size
        if len(_CONVERSATION_CONTEXT) > 500:
            oldest = list(_CONVERSATION_CONTEXT.keys())[:100]
            for key in oldest:
                _CONVERSATION_CONTEXT.pop(key, None)

        return AiEditResponse(
            edited_image_url=public_url,
            interaction_id=interaction_id,
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
            hf_analysis = await asyncio.to_thread(
                self._run_hf_analysis,
                source,
                product_name,
                selected_size,
            )
        except Exception:
            hf_analysis = {}
        return self._merge_analysis(baseline, hf_analysis)

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

    # -------------------------------------------------------------------------
    # Hugging Face: Image Editing
    # -------------------------------------------------------------------------
    # Strategy: Use Gemma-3 (vision) to describe the source image, then use
    # FLUX.1-schnell to generate the edited version guided by the description
    # plus the user's edit instruction. This works on HF's free tier.
    # -------------------------------------------------------------------------

    def _run_hf_edit(
        self,
        source: _ImagePayload,
        prompt: str,
        mask_image_base64: str | None,
    ) -> dict:
        client = self._hf_client()

        # Step 1: Describe the source image using vision model
        b64_image = base64.b64encode(source.data).decode("utf-8")
        mime = source.mime_type

        # Use detailed description for operations that need to preserve more
        needs_detail = any(kw in prompt.lower() for kw in [
            "style", "anime", "cartoon", "painting", "sketch", "scene",
            "night", "season", "sunset", "fashion", "outfit", "interior",
            "room", "furniture", "composite", "blend",
        ])
        detail_level = "detailed" if needs_detail else "standard"
        description = self._describe_image(client, b64_image, mime, detail_level)

        # Step 2: Build a generation prompt that combines description + edit
        gen_prompt = (
            f"A professional high-quality photograph. "
            f"Original scene: {description}. "
            f"Edit applied: {prompt}. "
            f"Photorealistic, sharp, vibrant, print-ready quality."
        )

        # Step 3: Generate with FLUX.1-schnell
        target_w = min(source.width or 1024, 1024)
        target_h = min(source.height or 1024, 1024)
        # FLUX requires dimensions divisible by 8
        target_w = (target_w // 8) * 8
        target_h = (target_h // 8) * 8

        result_image = client.text_to_image(
            prompt=gen_prompt,
            model=settings.hf_edit_model,
            width=target_w,
            height=target_h,
        )

        buf = BytesIO()
        result_image.save(buf, format="JPEG", quality=95)
        image_bytes = buf.getvalue()

        return {
            "image_bytes": image_bytes,
            "mime_type": "image/jpeg",
            "summary": f"Applied: {prompt[:100]}",
        }

    def _describe_image(self, client, b64_image: str, mime_type: str, detail_level: str = "standard") -> str:
        """Use Gemma-3 vision model to describe the source image."""
        if detail_level == "detailed":
            instruction = (
                "Describe this photograph in comprehensive detail for an AI image generator. "
                "Include: every subject (people, animals, objects), their exact poses, expressions, "
                "clothing with colors and patterns, background elements and setting, "
                "lighting direction and quality, color palette, composition and framing, "
                "camera angle, depth of field, mood and atmosphere. "
                "Be extremely specific about spatial relationships. Four sentences maximum."
            )
            max_tokens = 300
        else:
            instruction = (
                "Describe this photograph in detail for an AI image generator. "
                "Include: subjects, poses, expressions, clothing, background, "
                "lighting, colors, composition, mood. Be specific and concise. "
                "Two sentences maximum."
            )
            max_tokens = 150
        try:
            result = client.chat_completion(
                model=settings.hf_vision_model,
                messages=[{
                    "role": "user",
                    "content": [
                        {
                            "type": "image_url",
                            "image_url": {"url": f"data:{mime_type};base64,{b64_image}"},
                        },
                        {
                            "type": "text",
                            "text": instruction,
                        },
                    ],
                }],
                max_tokens=max_tokens,
            )
            return result.choices[0].message.content.strip()
        except Exception:
            return "a photograph"

    # -------------------------------------------------------------------------
    # Hugging Face: Image Analysis (Gemma-3 vision)
    # -------------------------------------------------------------------------

    def _run_hf_analysis(
        self,
        source: _ImagePayload,
        product_name: str,
        selected_size: str,
    ) -> dict:
        client = self._hf_client()
        b64_image = base64.b64encode(source.data).decode("utf-8")
        mime = source.mime_type

        try:
            result = client.chat_completion(
                model=settings.hf_vision_model,
                messages=[{
                    "role": "user",
                    "content": [
                        {
                            "type": "image_url",
                            "image_url": {"url": f"data:{mime};base64,{b64_image}"},
                        },
                        {
                            "type": "text",
                            "text": (
                                "Analyze this photo for professional printing quality. "
                                "Return ONLY valid JSON with these keys: "
                                "blur (string: Low/Medium/High + detail), "
                                "noise (string: Low/Medium/High + detail), "
                                "exposure (string: assessment), "
                                "faces (string: count and quality), "
                                "crop_recommendation (string: advice for print cropping), "
                                "score (int 0-100: overall print readiness), "
                                "suggestions (array of 2-3 improvement tips). "
                                f"Product: {product_name or 'photo print'}. "
                                f"Size: {selected_size or 'standard'}. "
                                "JSON only, no markdown."
                            ),
                        },
                    ],
                }],
                max_tokens=300,
            )
            text = result.choices[0].message.content.strip()
            # Extract JSON from response
            start = text.find("{")
            end = text.rfind("}")
            if start == -1 or end == -1:
                return {}
            return json.loads(text[start : end + 1])
        except Exception:
            return {}

    # -------------------------------------------------------------------------
    # Hugging Face Client
    # -------------------------------------------------------------------------

    def _hf_client(self):
        token = settings.hf_api_token
        if not token:
            raise HTTPException(
                status_code=503,
                detail="AI editor is not configured. Set HF_API_TOKEN in server environment.",
            )
        try:
            from huggingface_hub import InferenceClient
        except ImportError as exc:
            raise HTTPException(
                status_code=503,
                detail="huggingface_hub is not installed on the backend.",
            ) from exc
        return InferenceClient(token=token)

    # -------------------------------------------------------------------------
    # Result storage
    # -------------------------------------------------------------------------

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

    # -------------------------------------------------------------------------
    # Prompt building
    # -------------------------------------------------------------------------

    def _build_edit_prompt(
        self,
        *,
        operation: str,
        prompt: str,
        product_name: str,
        selected_size: str,
        has_mask: bool,
        conversation_history: str = "",
    ) -> str:
        context_suffix = ""
        if conversation_history:
            context_suffix = f" Previous edits in this session: {conversation_history}. Continue editing consistently."

        prompts = {
            "enhance": "Enhance this photo: improve sharpness, lighting, color balance, contrast, and overall quality. Make it look professional and print-ready.",
            "portrait": "Make this a professional portrait: smooth skin naturally, enhance face clarity, improve eye detail, add subtle background blur. Keep it realistic.",
            "background": f"Change the background: {prompt or 'use a clean studio background'}. Keep the subject unchanged and realistic.",
            "object_removal": f"Remove the following from the photo: {prompt}. Fill the area naturally with the surrounding background.",
            "magic_eraser": (
                "Remove the masked/highlighted areas and reconstruct the background naturally."
                if has_mask
                else f"Remove: {prompt}. Reconstruct the background naturally."
            ),
            "upscale": "Upscale and enhance this photo: improve resolution, sharpen details, reduce noise. Make it suitable for large-format printing.",
            "crop": f"Improve the composition of this photo for {product_name or 'printing'}. Center the main subject.",
            "colorize": "Colorize this black-and-white photograph with realistic, natural colors.",
            "restore": "Restore this old or damaged photo: fix scratches, faded areas, torn edges, and stains while keeping it authentic.",
            "filter": f"Apply a {prompt or 'professional'} style filter to this photo. Keep it print-quality.",
            # Extended 12-category operations
            "style_transfer": f"Transform this photo into {prompt or 'an artistic style'}. Maintain the composition, subjects, and poses exactly. Apply the style consistently across the entire image. High quality, detailed result.",
            "scene_transform": f"Transform the scene: {prompt or 'change the time of day to golden hour'}. Keep all subjects and objects exactly as they are. Only change the environment, lighting, and atmosphere.",
            "fashion_edit": f"Edit the clothing/fashion: {prompt or 'change to a professional outfit'}. Keep the person's face, pose, and body proportions exactly the same. Only modify the clothing realistically.",
            "interior_design": f"Redesign the interior space: {prompt or 'modern minimalist style'}. Keep the room structure and layout. Change furniture, decor, colors, and styling as specified.",
            "text_graphic": f"Add text or graphic overlay: {prompt or 'add elegant title text'}. Place it naturally within the composition. Use professional typography that complements the image.",
            "multi_image": f"Composite/blend instruction: {prompt or 'combine elements seamlessly'}. Create a natural-looking result with consistent lighting and perspective.",
            "color_lighting": f"Apply color grading and lighting: {prompt or 'cinematic color grading with dramatic lighting'}. Preserve the subjects and composition. Only modify colors, tones, and lighting atmosphere.",
            "photo_enhance": f"Professional photo enhancement: {prompt or 'maximize quality for printing'}. Reduce noise, enhance details, improve dynamic range, correct lens distortion. Print-ready at {selected_size or 'any size'}.",
            "prompt": prompt or "Make this photo look professional and print-ready.",
        }
        base = prompts.get(operation, prompt or "Enhance this photo.")
        return base + context_suffix

    # -------------------------------------------------------------------------
    # Baseline analysis (works without any AI model)
    # -------------------------------------------------------------------------

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

    def _merge_analysis(self, baseline: dict, hf_result: dict) -> AiAnalyzeResponse:
        suggestions = hf_result.get("suggestions") or baseline["suggestions"]
        if isinstance(suggestions, str):
            suggestions = [suggestions]
        return AiAnalyzeResponse(
            score=max(0, min(100, int(hf_result.get("score") or baseline["score"]))),
            resolution=baseline["resolution"],
            dpi_estimate=baseline["dpi_estimate"],
            blur=str(hf_result.get("blur") or baseline["blur"]),
            noise=str(hf_result.get("noise") or baseline["noise"]),
            exposure=str(hf_result.get("exposure") or baseline["exposure"]),
            faces=str(hf_result.get("faces") or baseline["faces"]),
            crop_recommendation=str(
                hf_result.get("crop_recommendation") or baseline["crop_recommendation"]
            ),
            suggestions=[str(item) for item in suggestions][:5],
        )


def _classify_prompt_operation(prompt: str) -> str:
    text = " ".join(prompt.lower().strip().split())
    if not text:
        return "prompt"

    # --- Background editing ---
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

    # --- Object editing / removal ---
    if _has_any(
        text,
        "remove people",
        "remove person",
        "remove object",
        "remove objects",
        "remove the",
        "remove chair",
        "remove wire",
        "remove wires",
        "remove text",
        "photobomber",
        "watermark",
        "erase",
        "delete",
        "get rid of",
        "take out",
        "clean up",
    ):
        return "object_removal"

    # --- Style transfer (artistic) ---
    if _has_any(
        text,
        "anime",
        "pixar",
        "disney",
        "ghibli",
        "cartoon",
        "pencil sketch",
        "watercolor",
        "oil painting",
        "pop art",
        "comic book",
        "comic",
        "clay",
        "plasticine",
        "lego",
        "minecraft",
        "cyberpunk",
        "vaporwave",
        "steampunk",
        "art deco",
        "impressionist",
        "baroque",
        "surreal",
        "3d render",
        "low poly",
        "pixel art",
        "ukiyo-e",
        "art nouveau",
        "turn into",
        "make it look like",
        "in the style of",
        "style of",
    ):
        return "style_transfer"

    # --- Scene transformation ---
    if _has_any(
        text,
        "day to night",
        "night to day",
        "make it night",
        "make it day",
        "summer",
        "winter",
        "autumn",
        "fall season",
        "spring",
        "sunset",
        "sunrise",
        "golden hour",
        "rainy",
        "rain",
        "snowy",
        "snow",
        "foggy",
        "fog",
        "underwater",
        "apocalyptic",
        "change season",
        "change time",
        "time of day",
        "add clouds",
        "starry sky",
        "northern lights",
        "aurora",
    ):
        return "scene_transform"

    # --- Fashion editing ---
    if _has_any(
        text,
        "change outfit",
        "change clothes",
        "change clothing",
        "wearing",
        "dress",
        "suit",
        "casual wear",
        "formal wear",
        "t-shirt",
        "hoodie",
        "jacket",
        "uniform",
        "costume",
        "swap outfit",
        "different outfit",
        "wedding dress",
        "traditional",
        "saree",
        "kurta",
    ):
        return "fashion_edit"

    # --- Interior design ---
    if _has_any(
        text,
        "redesign room",
        "redecorate",
        "change furniture",
        "living room",
        "bedroom",
        "kitchen",
        "bathroom",
        "modern style",
        "minimalist room",
        "change wallpaper",
        "different decor",
        "interior",
        "room makeover",
        "home design",
        "scandinavian",
        "industrial style",
        "bohemian",
    ):
        return "interior_design"

    # --- Text & graphic overlay ---
    if _has_any(
        text,
        "add text",
        "write text",
        "put text",
        "overlay text",
        "add logo",
        "caption",
        "title",
        "label",
        "add watermark",
        "add stamp",
        "add date",
        "typography",
        "lettering",
    ):
        return "text_graphic"

    # --- Color & lighting ---
    if _has_any(
        text,
        "color grade",
        "color grading",
        "warm tone",
        "cool tone",
        "dramatic lighting",
        "neon",
        "moody",
        "film grain",
        "desaturate",
        "cross process",
        "split toning",
        "teal and orange",
        "cinematic color",
        "noir",
        "sepia",
        "bleach bypass",
    ):
        return "color_lighting"

    # --- Photo enhancement ---
    if _has_any(
        text,
        "upscale",
        "4k",
        "super resolution",
        "increase quality",
        "sharpen",
        "deblur",
        "denoise",
        "noise reduction",
        "clarity",
        "detail enhancement",
        "hdr",
    ):
        return "photo_enhance"

    # --- Colorize ---
    if _has_any(text, "colorize", "colourize"):
        return "colorize"

    # --- Restore ---
    if _has_any(
        text,
        "restore",
        "scratch",
        "scratches",
        "faded",
        "torn",
        "old photo",
        "repair",
        "damaged",
        "cracked",
    ):
        return "restore"

    # --- Portrait editing ---
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
        "skin",
        "complexion",
        "makeup",
        "age",
        "younger",
        "older",
        "beard",
        "glasses",
        "freckles",
    ):
        return "portrait"

    # --- Legacy filter (catch local-handlable styles) ---
    if _has_any(
        text,
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
        "vibrant",
    ):
        return "filter"

    # --- General enhance ---
    if _has_any(
        text,
        "enhance",
        "brightness",
        "contrast",
        "saturation",
        "professional",
        "improve",
        "better quality",
        "make it pop",
    ):
        return "enhance"

    # --- Multi-image ---
    if _has_any(
        text,
        "combine",
        "merge",
        "collage",
        "side by side",
        "blend images",
        "composite",
        "double exposure",
    ):
        return "multi_image"

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
