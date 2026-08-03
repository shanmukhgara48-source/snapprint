import asyncio
import io
import logging
import uuid
from pathlib import PurePosixPath

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile
from PIL import Image, ImageOps
from pillow_heif import register_heif_opener
from pydantic import BaseModel
from slowapi import Limiter
from slowapi.util import get_remote_address
from ..config import settings
from ..dependencies import get_current_user
from ..services.r2_storage import build_media_url, media_base_url, r2_client

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/upload", tags=["upload"])
limiter = Limiter(key_func=get_remote_address)

register_heif_opener()

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"}
MAX_FILE_BYTES = 50 * 1024 * 1024
MAX_IMAGE_PIXELS = 50_000_000
_EXPECTED_FORMAT = {
    "image/jpeg": "JPEG",
    "image/png": "PNG",
    "image/webp": "WEBP",
    "image/heic": "HEIF",
    "image/heif": "HEIF",
}
_EXTENSION_BY_TYPE = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"}


class PresignResponse(BaseModel):
    upload_url: str   # Flutter PUTs the file here directly
    public_url: str   # The permanent URL to store in DB / cart


class UploadResponse(BaseModel):
    public_url: str
    width: int
    height: int
    file_size_bytes: int


@router.post("/image", response_model=UploadResponse, status_code=201)
@limiter.limit("15/minute")
async def upload_customer_image(
    request: Request,
    file: UploadFile = File(...),
    current_user=Depends(get_current_user),
) -> UploadResponse:
    content_type = (file.content_type or "").lower()
    if content_type not in ALLOWED_TYPES:
        raise HTTPException(415, "Only JPEG, PNG, WebP and HEIC images are allowed.")

    total = 0
    while chunk := await file.read(1024 * 1024):
        total += len(chunk)
        if total > MAX_FILE_BYTES:
            raise HTTPException(413, "Image exceeds the 50 MB upload limit.")
    if total == 0:
        raise HTTPException(400, "Image file is empty.")

    await file.seek(0)
    try:
        with Image.open(file.file) as image:
            detected_format = image.format
            width, height = image.size
            image.verify()
        await file.seek(0)
        with Image.open(file.file) as image:
            if image.getexif().get(274) in {5, 6, 7, 8}:
                width, height = height, width
    except (OSError, RuntimeError, ValueError) as exc:
        raise HTTPException(400, "Image file is corrupt or unsupported.") from exc
    if detected_format != _EXPECTED_FORMAT[content_type]:
        raise HTTPException(400, "Declared image type does not match the file content.")
    if width <= 0 or height <= 0 or width * height > MAX_IMAGE_PIXELS:
        raise HTTPException(413, "Image dimensions exceed the 50 megapixel limit.")

    stored_content_type = content_type
    stored_file = file.file
    extension = _EXTENSION_BY_TYPE.get(content_type, "jpg")
    if content_type in {"image/heic", "image/heif"}:
        await file.seek(0)
        try:
            with Image.open(file.file) as image:
                converted = ImageOps.exif_transpose(image).convert("RGB")
                output = io.BytesIO()
                save_options = {
                    "format": "JPEG",
                    "quality": 95,
                    "subsampling": 0,
                    "optimize": True,
                }
                if image.info.get("icc_profile"):
                    save_options["icc_profile"] = image.info["icc_profile"]
                if image.info.get("dpi"):
                    save_options["dpi"] = image.info["dpi"]
                converted.save(output, **save_options)
                output.seek(0)
        except (OSError, RuntimeError, ValueError) as exc:
            raise HTTPException(400, "Could not convert the HEIC image.") from exc
        stored_content_type = "image/jpeg"
        stored_file = output
    key = PurePosixPath("customizations", str(current_user.id), f"{uuid.uuid4()}.{extension}")
    if stored_file is file.file:
        await file.seek(0)
    try:
        await asyncio.to_thread(
            r2_client().upload_fileobj,
            stored_file,
            settings.r2_bucket_name,
            str(key),
            ExtraArgs={
                "ContentType": stored_content_type,
                "CacheControl": "private, max-age=31536000, immutable",
            },
        )
    except Exception as exc:
        logger.exception("Failed to upload customer image")
        raise HTTPException(502, "Could not store image. Please try again.") from exc

    return UploadResponse(
        public_url=build_media_url(media_base_url(str(request.base_url)), str(key)),
        width=width,
        height=height,
        file_size_bytes=total,
    )


@router.get("/presign", response_model=PresignResponse)
@limiter.limit("30/minute")
async def get_presigned_url(
    request: Request,
    filename: str,
    content_type: str = "image/jpeg",
    current_user=Depends(get_current_user),
):
    del filename, content_type, current_user
    raise HTTPException(
        410,
        "Direct uploads are retired. Use POST /upload/image so image limits can be enforced.",
    )
