"""Server-side proxy for Gemini image editing.

The Gemini API key lives here and never reaches the client — a key shipped in
an APK is recoverable from the bundle and can be abused outside the app.
Every call is authenticated and rate limited per caller.
"""
import base64
import binascii

import httpx
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from slowapi import Limiter
from slowapi.util import get_remote_address

from ..config import settings
from ..dependencies import get_current_user

router = APIRouter(prefix="/ai", tags=["ai"])
limiter = Limiter(key_func=get_remote_address)

MODEL = "gemini-2.5-flash-image"
BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"

ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_IMAGE_BYTES = 10 * 1024 * 1024  # 10 MB, same cap as the R2 upload path
GEMINI_TIMEOUT = httpx.Timeout(90.0, connect=15.0)


class EditImageRequest(BaseModel):
    image_base64: str
    mime_type: str = "image/jpeg"
    prompt: str = Field(min_length=1, max_length=1000)
    # Optional PNG mask drawn over the base image to constrain the edit region.
    doodle_base64: str | None = None


class EditImageResponse(BaseModel):
    image_base64: str
    mime_type: str


class AiStatusResponse(BaseModel):
    configured: bool


def _decode(field: str, value: str, max_bytes: int = MAX_IMAGE_BYTES) -> bytes:
    try:
        raw = base64.b64decode(value, validate=True)
    except (binascii.Error, ValueError):
        raise HTTPException(400, f"{field} is not valid base64.")
    if not raw:
        raise HTTPException(400, f"{field} is empty.")
    if len(raw) > max_bytes:
        raise HTTPException(413, f"{field} exceeds the {max_bytes // (1024 * 1024)} MB limit.")
    return raw


@router.get("/status", response_model=AiStatusResponse)
async def ai_status():
    """Feature flag so the app can hide AI editing when no key is configured.
    Public on purpose — it leaks nothing beyond whether the feature is on."""
    return AiStatusResponse(configured=bool(settings.gemini_api_key))


@router.post("/edit-image", response_model=EditImageResponse)
@limiter.limit("10/minute")
async def edit_image(
    request: Request,  # required by slowapi's limiter
    payload: EditImageRequest,
    current_user=Depends(get_current_user),
):
    if not settings.gemini_api_key:
        raise HTTPException(503, "AI editing is not configured on the server.")

    if payload.mime_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(400, "Only JPEG, PNG and WebP images can be edited.")

    image_bytes = _decode("image_base64", payload.image_base64)

    parts: list[dict] = [
        {"inline_data": {"mime_type": payload.mime_type, "data": payload.image_base64}}
    ]

    if payload.doodle_base64:
        _decode("doodle_base64", payload.doodle_base64)
        parts.append(
            {"inline_data": {"mime_type": "image/png", "data": payload.doodle_base64}}
        )
        parts.append(
            {
                "text": "The second image is a doodle mask drawn on top of the first. "
                f"Apply the following edit only within the marked/drawn region: {payload.prompt}"
            }
        )
    else:
        parts.append({"text": payload.prompt})

    del image_bytes  # only decoded to validate size/format

    try:
        async with httpx.AsyncClient(timeout=GEMINI_TIMEOUT) as client:
            response = await client.post(
                f"{BASE_URL}/{MODEL}:generateContent",
                headers={
                    "Content-Type": "application/json",
                    "x-goog-api-key": settings.gemini_api_key,
                },
                json={"contents": [{"parts": parts}]},
            )
    except httpx.TimeoutException:
        raise HTTPException(504, "Gemini took too long to respond — please try again.")
    except httpx.HTTPError:
        raise HTTPException(502, "Could not reach Gemini — please try again.")

    if response.status_code != 200:
        # Never forward the upstream body verbatim: it can echo request details.
        detail = "Gemini rejected that request — try a different prompt."
        if response.status_code in (401, 403):
            detail = "AI editing is misconfigured on the server."
        elif response.status_code == 429:
            detail = "AI editing is busy right now — please try again in a moment."
        raise HTTPException(502 if response.status_code >= 500 else 400, detail)

    data = response.json()
    candidates = data.get("candidates") or []
    response_parts = (candidates[0].get("content") or {}).get("parts") or [] if candidates else []

    for part in response_parts:
        inline = part.get("inline_data") or part.get("inlineData")
        if inline and inline.get("data"):
            return EditImageResponse(
                image_base64=inline["data"],
                mime_type=inline.get("mime_type") or inline.get("mimeType") or "image/png",
            )

    raise HTTPException(422, "Gemini did not return an edited image — try a different prompt.")
