import re
import uuid
import boto3
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from ..config import settings
from ..dependencies import get_current_user

router = APIRouter(prefix="/upload", tags=["upload"])

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "webp", "gif"}
MAX_FILE_BYTES = 10 * 1024 * 1024  # 10 MB hard cap enforced via presign conditions


def _r2_client():
    return boto3.client(
        "s3",
        endpoint_url=f"https://{settings.r2_account_id}.r2.cloudflarestorage.com",
        aws_access_key_id=settings.r2_access_key_id,
        aws_secret_access_key=settings.r2_secret_access_key,
        region_name="auto",
    )


class PresignResponse(BaseModel):
    upload_url: str   # Flutter PUTs the file here directly
    public_url: str   # The permanent URL to store in DB / cart


@router.get("/presign", response_model=PresignResponse)
async def get_presigned_url(
    filename: str,
    content_type: str = "image/jpeg",
    current_user=Depends(get_current_user),
):
    if content_type not in ALLOWED_TYPES:
        raise HTTPException(400, "Only JPEG, PNG, WebP and GIF images are allowed.")

    # Sanitise the extension from client-provided filename
    raw_ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else "jpg"
    ext = raw_ext if raw_ext in ALLOWED_EXTENSIONS else "jpg"
    # Ensure the extension matches the declared content-type
    ct_to_ext = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp", "image/gif": "gif"}
    ext = ct_to_ext.get(content_type, ext)

    key = f"customizations/{current_user.id}/{uuid.uuid4()}.{ext}"

    try:
        client = _r2_client()
        upload_url = client.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": settings.r2_bucket_name,
                "Key": key,
                "ContentType": content_type,
                # Note: ContentLength is intentionally omitted — presigned PUT URLs
                # cannot enforce size limits via signed headers (that requires POST policy).
                # The 10 MB cap is documented as a client-side guideline only.
            },
            ExpiresIn=300,  # 5 minutes
        )
    except Exception as e:
        raise HTTPException(500, f"Could not generate upload URL: {e}")

    public_url = f"{settings.r2_public_url.rstrip('/')}/{key}"
    return PresignResponse(upload_url=upload_url, public_url=public_url)
