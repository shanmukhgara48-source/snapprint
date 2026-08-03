import asyncio
import io
import re
import time
import uuid
from dataclasses import dataclass

import httpx
import numpy as np
from fastapi import HTTPException
from PIL import Image, ImageEnhance, ImageFilter, ImageOps

from ..config import settings
from ..schemas.ai_editor import (
    AiExportRequest,
    AiExportResponse,
    BackgroundRemovalRequest,
    BackgroundRemovalResponse,
    NormalizedRect,
)
from .r2_storage import build_media_url, key_belongs_to_user, owned_media_key, r2_client


_ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}


@dataclass(frozen=True)
class ImageAsset:
    data: bytes
    mime_type: str
    width: int
    height: int
    dpi: tuple[float, float] | None
    icc_profile: bytes | None


class ProfessionalImagePipeline:
    @property
    def background_removal_configured(self) -> bool:
        return bool(settings.ai_segmentation_url and settings.ai_segmentation_token)

    async def remove_background(
        self,
        *,
        user_id: str,
        payload: BackgroundRemovalRequest,
        public_base_url: str,
    ) -> BackgroundRemovalResponse:
        if not self.background_removal_configured:
            raise HTTPException(
                status_code=503,
                detail="Professional background removal is not configured.",
            )

        source = await self._download_owned_image(payload.image_url, user_id)
        started = time.perf_counter()
        headers = {
            "Authorization": f"Bearer {settings.ai_segmentation_token}",
            "Content-Type": source.mime_type,
            "Accept": "image/png",
            "X-SnapPrint-Quality": payload.quality,
            "X-SnapPrint-Refine-Foreground": str(payload.refine_foreground).lower(),
            "X-SnapPrint-Preserve-Alpha": str(payload.preserve_existing_alpha).lower(),
        }
        timeout = httpx.Timeout(settings.ai_segmentation_timeout_seconds)
        try:
            async with httpx.AsyncClient(timeout=timeout, follow_redirects=False) as client:
                response = await client.post(
                    settings.ai_segmentation_url,
                    content=source.data,
                    headers=headers,
                )
        except httpx.TimeoutException as exc:
            raise HTTPException(504, "Background removal timed out. Please try again.") from exc
        except httpx.HTTPError as exc:
            raise HTTPException(502, "Background removal service is unavailable.") from exc

        if response.status_code >= 400:
            raise HTTPException(502, "Background removal service could not process this image.")
        if response.headers.get("content-type", "").split(";", 1)[0] != "image/png":
            raise HTTPException(502, "Background removal service returned an invalid format.")

        result = await asyncio.to_thread(self._inspect_bytes, response.content, "image/png")
        if (result.width, result.height) != (source.width, source.height):
            raise HTTPException(502, "Background removal changed the source resolution.")

        bounds = _bounds_from_headers(response.headers)
        if bounds is None:
            bounds = await asyncio.to_thread(_alpha_bounds, result.data)
        warnings = _segmentation_warnings(bounds)
        public_url = await asyncio.to_thread(
            self._store_result,
            user_id,
            result.data,
            "image/png",
            "cutout",
            source.dpi,
            source.icc_profile,
            public_base_url,
        )
        elapsed_ms = int((time.perf_counter() - started) * 1000)
        return BackgroundRemovalResponse(
            foreground_url=public_url,
            width=result.width,
            height=result.height,
            subject_bounds=bounds,
            model=response.headers.get("x-model", settings.ai_segmentation_model),
            processing_ms=_int_header(response.headers, "x-processing-ms") or elapsed_ms,
            warnings=warnings,
        )

    async def export(
        self,
        *,
        user_id: str,
        payload: AiExportRequest,
        public_base_url: str,
    ) -> AiExportResponse:
        started = time.perf_counter()
        source = await self._download_owned_image(payload.image_url, user_id)
        background_asset = None
        if payload.background.kind == "image":
            if not payload.background.image_url:
                raise HTTPException(400, "A custom background image is required.")
            background_asset = await self._download_owned_image(
                payload.background.image_url,
                user_id,
            )

        rendered, mime_type, output_dpi = await asyncio.to_thread(
            _render_export,
            source,
            payload,
            background_asset,
        )
        inspected = await asyncio.to_thread(self._inspect_bytes, rendered, mime_type)
        public_url = await asyncio.to_thread(
            self._store_result,
            user_id,
            rendered,
            mime_type,
            "export",
            output_dpi,
            source.icc_profile,
            public_base_url,
        )
        dpi_estimate = _estimate_numeric_dpi(
            inspected.width,
            inspected.height,
            payload.selected_size,
        )
        warnings = _print_warnings(inspected.width, inspected.height, dpi_estimate)
        return AiExportResponse(
            image_url=public_url,
            width=inspected.width,
            height=inspected.height,
            mime_type=mime_type,
            file_size_bytes=len(rendered),
            dpi_estimate=dpi_estimate,
            processing_ms=int((time.perf_counter() - started) * 1000),
            warnings=warnings,
        )

    async def _download_owned_image(self, image_url: str, user_id: str) -> ImageAsset:
        key = owned_media_key(image_url, str(user_id))
        if key is None:
            raise HTTPException(403, "You do not have access to this image.")
        try:
            result = await asyncio.to_thread(
                r2_client().get_object,
                Bucket=settings.r2_bucket_name,
                Key=key,
            )
            data = await asyncio.to_thread(result["Body"].read, settings.ai_max_source_bytes + 1)
            result["Body"].close()
        except Exception as exc:
            raise HTTPException(400, "Could not fetch the selected image.") from exc
        if len(data) > settings.ai_max_source_bytes:
            raise HTTPException(413, "Image exceeds the editor file-size limit.")
        mime_type = str(result.get("ContentType", "")).split(";", 1)[0]
        if mime_type not in _ALLOWED_MIME_TYPES:
            raise HTTPException(400, "Only JPEG, PNG and WebP images are supported.")
        return await asyncio.to_thread(self._inspect_bytes, data, mime_type)

    def _inspect_bytes(self, data: bytes, mime_type: str) -> ImageAsset:
        try:
            with Image.open(io.BytesIO(data)) as image:
                image.verify()
            with Image.open(io.BytesIO(data)) as image:
                oriented = ImageOps.exif_transpose(image)
                width, height = oriented.size
                dpi_value = image.info.get("dpi")
                dpi = _valid_dpi(dpi_value)
                icc_profile = image.info.get("icc_profile")
        except (OSError, ValueError) as exc:
            raise HTTPException(400, "The image file is corrupt or unsupported.") from exc
        if width <= 0 or height <= 0 or width * height > settings.ai_max_source_pixels:
            raise HTTPException(413, "Image dimensions exceed the editor limit.")
        return ImageAsset(data, mime_type, width, height, dpi, icc_profile)

    def _store_result(
        self,
        user_id: str,
        image_bytes: bytes,
        mime_type: str,
        category: str,
        dpi: tuple[float, float] | None,
        icc_profile: bytes | None,
        public_base_url: str,
    ) -> str:
        extension = "png" if mime_type == "image/png" else "jpg"
        key = f"ai-edits/{user_id}/{category}-{uuid.uuid4()}.{extension}"
        metadata: dict[str, str] = {}
        if dpi:
            metadata["dpi-x"] = f"{dpi[0]:.2f}"
            metadata["dpi-y"] = f"{dpi[1]:.2f}"
        if icc_profile:
            metadata["icc-profile-preserved"] = "true"
        r2_client().put_object(
            Bucket=settings.r2_bucket_name,
            Key=key,
            Body=image_bytes,
            ContentType=mime_type,
            CacheControl="private, max-age=31536000, immutable",
            Metadata=metadata,
        )
        return build_media_url(public_base_url, key)


def path_belongs_to_user(path: str, user_id: str) -> bool:
    return key_belongs_to_user(path.lstrip("/"), user_id)


def _render_export(
    source: ImageAsset,
    payload: AiExportRequest,
    background_asset: ImageAsset | None,
) -> tuple[bytes, str, tuple[float, float] | None]:
    with Image.open(io.BytesIO(source.data)) as opened:
        image = ImageOps.exif_transpose(opened).convert("RGBA")
    image = _apply_adjustments(image, payload.adjustments)

    if payload.transform.offset_x or payload.transform.offset_y:
        image = image.transform(
            image.size,
            Image.Transform.AFFINE,
            (
                1,
                0,
                -payload.transform.offset_x * image.width,
                0,
                1,
                -payload.transform.offset_y * image.height,
            ),
            resample=Image.Resampling.BICUBIC,
            fillcolor=(0, 0, 0, 0),
        )

    crop = payload.transform.crop
    if crop:
        left = round(crop.left * image.width)
        top = round(crop.top * image.height)
        right = round(min(1.0, crop.left + crop.width) * image.width)
        bottom = round(min(1.0, crop.top + crop.height) * image.height)
        image = image.crop((left, top, max(left + 1, right), max(top + 1, bottom)))

    if payload.transform.flip_horizontal:
        image = ImageOps.mirror(image)
    if payload.transform.flip_vertical:
        image = ImageOps.flip(image)
    if payload.transform.rotation_quarter_turns:
        image = image.rotate(
            -90 * payload.transform.rotation_quarter_turns,
            resample=Image.Resampling.BICUBIC,
            expand=True,
        )
    if payload.transform.straighten_degrees:
        image = image.rotate(
            -payload.transform.straighten_degrees,
            resample=Image.Resampling.BICUBIC,
            expand=True,
            fillcolor=(0, 0, 0, 0),
        )

    background = payload.background
    if background.kind == "solid":
        canvas = Image.new("RGBA", image.size, _hex_color(background.color))
        canvas.alpha_composite(image)
        image = canvas
    elif background.kind == "gradient":
        canvas = _gradient_canvas(
            image.size,
            _hex_color(background.gradient_start),
            _hex_color(background.gradient_end),
        ).convert("RGBA")
        canvas.alpha_composite(image)
        image = canvas
    elif background.kind == "image" and background_asset:
        with Image.open(io.BytesIO(background_asset.data)) as opened:
            custom = ImageOps.exif_transpose(opened).convert("RGB")
        canvas = ImageOps.fit(custom, image.size, method=Image.Resampling.LANCZOS).convert("RGBA")
        canvas.alpha_composite(image)
        image = canvas

    has_transparency = image.getchannel("A").getextrema()[0] < 255
    requested = payload.output_format
    mime_type = (
        "image/png"
        if requested == "png" or (requested == "auto" and has_transparency)
        else "image/jpeg"
    )
    output = io.BytesIO()
    save_kwargs: dict = {}
    if source.icc_profile:
        save_kwargs["icc_profile"] = source.icc_profile
    output_dpi = source.dpi
    if output_dpi:
        save_kwargs["dpi"] = output_dpi
    if mime_type == "image/png":
        image.save(output, format="PNG", compress_level=6, **save_kwargs)
    else:
        flattened = Image.new("RGB", image.size, (255, 255, 255))
        flattened.paste(image, mask=image.getchannel("A"))
        flattened.save(
            output,
            format="JPEG",
            quality=97,
            subsampling=0,
            optimize=True,
            **save_kwargs,
        )
    return output.getvalue(), mime_type, output_dpi


def _apply_adjustments(image: Image.Image, values) -> Image.Image:
    alpha = image.getchannel("A")
    rgb = image.convert("RGB")
    if values.brightness:
        rgb = ImageEnhance.Brightness(rgb).enhance(max(0.05, 1 + values.brightness))
    if values.contrast:
        rgb = ImageEnhance.Contrast(rgb).enhance(max(0.05, 1 + values.contrast))
    if values.saturation:
        rgb = ImageEnhance.Color(rgb).enhance(max(0, 1 + values.saturation))

    uses_pixel_adjustments = any(
        (
            values.exposure,
            values.temperature,
            values.tint,
            values.vibrance,
            values.highlights,
            values.shadows,
        )
    )
    if uses_pixel_adjustments:
        adjusted_rgb = Image.new("RGB", rgb.size)
        strip_height = max(1, min(512, 8_000_000 // max(1, rgb.width)))
        for top in range(0, rgb.height, strip_height):
            bottom = min(rgb.height, top + strip_height)
            pixels = np.asarray(
                rgb.crop((0, top, rgb.width, bottom)), dtype=np.float32
            ) / np.float32(255.0)
            adjusted_rgb.paste(
                Image.fromarray(_adjust_pixel_strip(pixels, values), "RGB"),
                (0, top),
            )
        rgb = adjusted_rgb

    adjusted = rgb.convert("RGBA")
    adjusted.putalpha(alpha)
    if values.sharpness:
        adjusted = adjusted.filter(
            ImageFilter.UnsharpMask(
                radius=1.2,
                percent=round(60 + values.sharpness * 180),
                threshold=3,
            )
        )
        adjusted.putalpha(alpha)
    return adjusted


def _adjust_pixel_strip(pixels: np.ndarray, values) -> np.ndarray:
    if values.exposure:
        pixels *= 2.0 ** values.exposure
    if values.temperature:
        amount = values.temperature * 0.16
        pixels[..., 0] *= 1 + amount
        pixels[..., 2] *= 1 - amount
    if values.tint:
        amount = values.tint * 0.12
        pixels[..., 1] *= 1 - amount
        pixels[..., 0] *= 1 + amount * 0.45
        pixels[..., 2] *= 1 + amount * 0.45
    luma = (
        pixels[..., 0] * 0.2126
        + pixels[..., 1] * 0.7152
        + pixels[..., 2] * 0.0722
    )[..., None]
    if values.shadows:
        pixels += values.shadows * 0.38 * np.square(1 - np.clip(luma, 0, 1))
    if values.highlights:
        pixels += values.highlights * 0.30 * np.square(np.clip(luma, 0, 1))
    if values.vibrance:
        max_channel = pixels.max(axis=2, keepdims=True)
        min_channel = pixels.min(axis=2, keepdims=True)
        saturation = max_channel - min_channel
        factor = 1 + values.vibrance * (1 - np.clip(saturation, 0, 1))
        pixels = luma + (pixels - luma) * factor
    return np.clip(pixels * 255.0, 0, 255).astype(np.uint8)


def _gradient_canvas(
    size: tuple[int, int],
    start: tuple[int, int, int, int],
    end: tuple[int, int, int, int],
) -> Image.Image:
    height = max(1, size[1])
    ramp = np.linspace(start[:3], end[:3], height, dtype=np.uint8)
    return Image.fromarray(ramp[:, None, :], "RGB").resize(
        size,
        Image.Resampling.BILINEAR,
    )


def _hex_color(value: str) -> tuple[int, int, int, int]:
    raw = value.strip().lstrip("#")
    if len(raw) != 6:
        raise HTTPException(400, "Colors must use six-digit hex values.")
    try:
        return tuple(int(raw[index : index + 2], 16) for index in (0, 2, 4)) + (255,)
    except ValueError as exc:
        raise HTTPException(400, "Colors must use six-digit hex values.") from exc


def _alpha_bounds(data: bytes) -> NormalizedRect:
    with Image.open(io.BytesIO(data)) as image:
        alpha = image.convert("RGBA").getchannel("A")
        mask = alpha.point(lambda value: 255 if value > 8 else 0)
        bounds = mask.getbbox()
        if not bounds:
            return NormalizedRect(left=0, top=0, width=1, height=1)
        left, top, right, bottom = bounds
        return NormalizedRect(
            left=left / image.width,
            top=top / image.height,
            width=(right - left) / image.width,
            height=(bottom - top) / image.height,
        )


def _bounds_from_headers(headers: httpx.Headers) -> NormalizedRect | None:
    raw = headers.get("x-subject-bounds")
    if not raw:
        return None
    try:
        left, top, width, height = (float(part) for part in raw.split(","))
        return NormalizedRect(left=left, top=top, width=width, height=height)
    except (ValueError, TypeError):
        return None


def _segmentation_warnings(bounds: NormalizedRect) -> list[str]:
    warnings = []
    if bounds.width >= 0.99 or bounds.height >= 0.99:
        warnings.append("The subject touches an image edge; inspect the cutout before printing.")
    if bounds.width * bounds.height < 0.01:
        warnings.append("The detected subject is very small; manual correction may be needed.")
    return warnings


def _print_warnings(width: int, height: int, dpi: int | None) -> list[str]:
    warnings = []
    if dpi is not None and dpi < 150:
        warnings.append("Resolution is too low for a sharp print at the selected size.")
    elif dpi is not None and dpi < 300:
        warnings.append("Resolution is below the recommended 300 DPI for this print size.")
    if min(width, height) < 600:
        warnings.append("The exported image has a short edge below 600 pixels.")
    return warnings


def _estimate_numeric_dpi(width: int, height: int, selected_size: str) -> int | None:
    match = re.search(
        r"(?P<width>\d+(?:\.\d+)?)\s*[x×]\s*(?P<height>\d+(?:\.\d+)?)",
        selected_size.lower(),
    )
    if match is None:
        return None
    try:
        width_in = float(match.group("width"))
        height_in = float(match.group("height"))
    except ValueError:
        return None
    if width_in <= 0 or height_in <= 0:
        return None
    return int(min(width / width_in, height / height_in))


def _valid_dpi(value) -> tuple[float, float] | None:
    if not isinstance(value, tuple) or len(value) != 2:
        return None
    try:
        x, y = float(value[0]), float(value[1])
    except (TypeError, ValueError):
        return None
    return (x, y) if 1 <= x <= 2400 and 1 <= y <= 2400 else None


def _int_header(headers: httpx.Headers, name: str) -> int | None:
    try:
        return int(headers[name])
    except (KeyError, ValueError):
        return None
