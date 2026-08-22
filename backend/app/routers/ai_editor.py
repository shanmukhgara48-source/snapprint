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
    AiEditorCapabilities,
    AiExportRequest,
    AiExportResponse,
    BackgroundRemovalRequest,
    BackgroundRemovalResponse,
)
from ..services.ai_photo_editor import AiPhotoEditorService
from ..services.professional_image_pipeline import ProfessionalImagePipeline
from ..services.r2_storage import media_base_url

router = APIRouter(prefix="/ai/photo", tags=["ai-photo-editor"])
limiter = Limiter(key_func=get_remote_address)


@router.get("/status", response_model=AiEditorCapabilities)
async def ai_editor_status() -> AiEditorCapabilities:
    generative = bool(settings.hf_api_token or settings.gemini_api_key or settings.google_api_key)
    segmentation = ProfessionalImagePipeline().background_removal_configured
    return AiEditorCapabilities(
        enabled=True,
        background_removal=segmentation,
        generative_editing=generative,
        model=settings.hf_edit_model if settings.hf_api_token else settings.gemini_image_model,
        max_source_bytes=settings.ai_max_source_bytes,
        max_source_pixels=settings.ai_max_source_pixels,
        supported_input_formats=["image/jpeg", "image/png", "image/webp"],
        supported_output_formats=["image/png", "image/jpeg"],
    )


@router.post("/remove-background", response_model=BackgroundRemovalResponse)
@limiter.limit("5/minute")
async def remove_background(
    request: Request,
    payload: BackgroundRemovalRequest,
    current_user: User = Depends(require_customer),
) -> BackgroundRemovalResponse:
    return await ProfessionalImagePipeline().remove_background(
        user_id=str(current_user.id),
        payload=payload,
        public_base_url=media_base_url(str(request.base_url)),
    )


@router.post("/export", response_model=AiExportResponse)
@limiter.limit("10/minute")
async def export_photo(
    request: Request,
    payload: AiExportRequest,
    current_user: User = Depends(require_customer),
) -> AiExportResponse:
    return await ProfessionalImagePipeline().export(
        user_id=str(current_user.id),
        payload=payload,
        public_base_url=media_base_url(str(request.base_url)),
    )


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
        public_base_url=media_base_url(str(request.base_url)),
    )


@router.post("/analyze", response_model=AiAnalyzeResponse)
@limiter.limit("20/minute")
async def analyze_photo(
    request: Request,
    payload: AiAnalyzeRequest,
    current_user: User = Depends(require_customer),
) -> AiAnalyzeResponse:
    return await AiPhotoEditorService().analyze(
        user_id=str(current_user.id),
        image_url=payload.image_url,
        product_name=payload.product_name,
        selected_size=payload.selected_size,
    )
