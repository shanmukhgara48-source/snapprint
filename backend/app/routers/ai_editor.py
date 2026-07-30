from fastapi import APIRouter, Depends, Request
from slowapi import Limiter
from slowapi.util import get_remote_address

from ..config import settings
from ..dependencies import require_customer
from ..models import User
from ..schemas.ai_editor import (
    AiAnalyzeRequest,
    AiAnalyzeResponse,
    AiEditRequest,
    AiEditResponse,
)
from ..services.ai_photo_editor import AiPhotoEditorService

router = APIRouter(prefix="/ai/photo", tags=["ai-photo-editor"])
limiter = Limiter(key_func=get_remote_address)


@router.get("/status")
async def ai_editor_status() -> dict:
    configured = bool(settings.gemini_api_key or settings.google_api_key)
    return {
        "enabled": configured,
        "image_model": settings.gemini_image_model,
        "text_model": settings.gemini_text_model,
    }


@router.post("/edit", response_model=AiEditResponse)
@limiter.limit("10/minute")
async def edit_photo(
    request: Request,
    payload: AiEditRequest,
    current_user: User = Depends(require_customer),
) -> AiEditResponse:
    return await AiPhotoEditorService().edit(
        user_id=current_user.id,
        image_url=payload.image_url,
        operation=payload.operation,
        prompt=payload.prompt,
        product_name=payload.product_name,
        selected_size=payload.selected_size,
        mask_image_base64=payload.mask_image_base64,
        previous_interaction_id=payload.previous_interaction_id,
        rights_confirmed=payload.rights_confirmed,
    )


@router.post("/analyze", response_model=AiAnalyzeResponse)
@limiter.limit("20/minute")
async def analyze_photo(
    request: Request,
    payload: AiAnalyzeRequest,
    current_user: User = Depends(require_customer),
) -> AiAnalyzeResponse:
    del current_user
    return await AiPhotoEditorService().analyze(
        image_url=payload.image_url,
        product_name=payload.product_name,
        selected_size=payload.selected_size,
    )
