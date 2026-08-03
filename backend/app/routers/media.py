import asyncio
import hmac
import re
from typing import Iterator

from botocore.exceptions import ClientError
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from starlette.background import BackgroundTask

from ..config import settings
from ..services.r2_storage import MEDIA_NAMESPACES, r2_client, sign_media_key


router = APIRouter(prefix="/media", tags=["media"])
_USER_ID = re.compile(r"^[A-Za-z0-9_-]{1,128}$")
_FILENAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,254}$")
_ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}


def _iter_body(body, chunk_size: int = 1024 * 1024) -> Iterator[bytes]:
    while chunk := body.read(chunk_size):
        yield chunk


@router.get("/{namespace}/{user_id}/{filename}")
async def get_media(
    namespace: str,
    user_id: str,
    filename: str,
    sig: str | None = None,
) -> StreamingResponse:
    if (
        namespace not in MEDIA_NAMESPACES
        or not _USER_ID.fullmatch(user_id)
        or not _FILENAME.fullmatch(filename)
    ):
        raise HTTPException(404, "Image not found.")

    key = f"{namespace}/{user_id}/{filename}"
    if (
        sig is None or not hmac.compare_digest(sig, sign_media_key(key))
    ):
        raise HTTPException(404, "Image not found.")
    try:
        result = await asyncio.to_thread(
            r2_client().get_object,
            Bucket=settings.r2_bucket_name,
            Key=key,
        )
    except ClientError as exc:
        code = str(exc.response.get("Error", {}).get("Code", ""))
        if code in {"NoSuchKey", "404", "NotFound"}:
            raise HTTPException(404, "Image not found.") from exc
        raise HTTPException(502, "Image storage is unavailable.") from exc
    except Exception as exc:
        raise HTTPException(502, "Image storage is unavailable.") from exc

    content_type = str(result.get("ContentType", ""))
    if content_type not in _ALLOWED_CONTENT_TYPES:
        result["Body"].close()
        raise HTTPException(404, "Image not found.")

    headers = {
        "Cache-Control": "private, max-age=31536000, immutable",
        "X-Content-Type-Options": "nosniff",
    }
    if result.get("ContentLength") is not None:
        headers["Content-Length"] = str(result["ContentLength"])
    if result.get("ETag"):
        headers["ETag"] = str(result["ETag"])
    body = result["Body"]
    return StreamingResponse(
        _iter_body(body),
        media_type=content_type,
        headers=headers,
        background=BackgroundTask(body.close),
    )
