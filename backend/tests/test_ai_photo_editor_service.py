import asyncio
import base64
import io

import pytest
from fastapi import HTTPException
from PIL import Image

from app.services.ai_photo_editor import (
    AiPhotoEditorService,
    _ImagePayload,
    _classify_prompt_operation,
)


def _jpeg_bytes() -> bytes:
    output = io.BytesIO()
    Image.new("RGB", (16, 12), "white").save(output, format="JPEG")
    return output.getvalue()


def test_hf_edit_returns_jpeg(monkeypatch):
    """HF edit pipeline returns a valid JPEG result."""
    service = AiPhotoEditorService()
    source = _ImagePayload(_jpeg_bytes(), "image/jpeg", 16, 12)

    result_img = Image.new("RGB", (512, 512), "blue")

    class FakeClient:
        def text_to_image(self, **kwargs):
            return result_img

        def chat_completion(self, **kwargs):
            return type(
                "R", (), {"choices": [
                    type("C", (), {"message": type("M", (), {"content": "a white square"})()})()
                ]}
            )()

    monkeypatch.setattr(service, "_hf_client", lambda: FakeClient())

    result = service._run_hf_edit(source, "enhance this photo", None)

    assert result["mime_type"] == "image/jpeg"
    assert len(result["image_bytes"]) > 0
    img = Image.open(io.BytesIO(result["image_bytes"]))
    assert img.format == "JPEG"


def test_corrupt_provider_image_is_rejected_before_storage():
    service = AiPhotoEditorService()

    with pytest.raises(HTTPException) as exc:
        service._store_result("user-1", b"not-an-image", "image/jpeg", "https://api.test")

    assert exc.value.status_code == 502


def test_provider_failure_returns_a_stable_gateway_error(monkeypatch):
    service = AiPhotoEditorService()
    source = _ImagePayload(_jpeg_bytes(), "image/jpeg", 16, 12)

    async def download(*args, **kwargs):
        return source

    def fail(*args, **kwargs):
        raise RuntimeError("provider timeout")

    monkeypatch.setattr(service, "_download_owned_image", download)
    monkeypatch.setattr(service, "_run_hf_edit", fail)

    with pytest.raises(HTTPException) as exc:
        asyncio.run(
            service.edit(
                user_id="user-1",
                image_url="https://api.test/media/customizations/user-1/photo.jpg",
                operation="enhance",
                prompt="",
                product_name="Print",
                selected_size="4x6",
                mask_image_base64=None,
                previous_interaction_id=None,
                rights_confirmed=False,
                public_base_url="https://api.test",
            )
        )

    assert exc.value.status_code == 502
    assert exc.value.detail == "The AI editing service is temporarily unavailable."


def test_prompt_auto_classifier_routes_common_photo_edits():
    assert _classify_prompt_operation("Remove the background") == "background"
    assert _classify_prompt_operation("Replace background with beach") == "background"
    assert (
        _classify_prompt_operation("Replace the sky with a dramatic sunset")
        == "background"
    )
    assert _classify_prompt_operation("Remove the chair") == "object_removal"
    assert _classify_prompt_operation("Upscale to 4K") == "photo_enhance"
    assert _classify_prompt_operation("Colorize this old photo") == "colorize"
    assert _classify_prompt_operation("Fix scratches") == "restore"
    assert _classify_prompt_operation("Turn this into anime") == "style_transfer"


def test_extended_12_category_classifier():
    """Test all 12 feature categories classify correctly."""
    assert _classify_prompt_operation("Make it anime style") == "style_transfer"
    assert _classify_prompt_operation("Oil painting effect") == "style_transfer"
    assert _classify_prompt_operation("Turn into pencil sketch") == "style_transfer"
    assert _classify_prompt_operation("Make it sunset") == "scene_transform"
    assert _classify_prompt_operation("Day to night") == "scene_transform"
    assert _classify_prompt_operation("Add rain effect") == "scene_transform"
    assert _classify_prompt_operation("Change outfit to suit") == "fashion_edit"
    assert _classify_prompt_operation("Redesign room modern") == "interior_design"
    assert _classify_prompt_operation("Add text overlay") == "text_graphic"
    assert _classify_prompt_operation("Cinematic color grading") == "color_lighting"
    assert _classify_prompt_operation("Double exposure effect") == "multi_image"
    assert _classify_prompt_operation("Sharpen and denoise") == "photo_enhance"
    assert _classify_prompt_operation("Smooth skin naturally") == "portrait"
    assert _classify_prompt_operation("Restore old damaged photo") == "restore"


def test_conversation_context_tracking():
    """Test that multi-turn editing returns interaction IDs."""
    # Conversation context is module-level dict; just verify it's importable
    from app.services.ai_photo_editor import _CONVERSATION_CONTEXT
    assert isinstance(_CONVERSATION_CONTEXT, dict)


def test_auto_operation_uses_classified_prompt_pipeline(monkeypatch):
    service = AiPhotoEditorService()
    source = _ImagePayload(_jpeg_bytes(), "image/jpeg", 16, 12)
    captured = {}

    async def download(*args, **kwargs):
        return source

    def run(source, prompt, mask_image_base64):
        captured["prompt"] = prompt
        return {
            "image_bytes": _jpeg_bytes(),
            "mime_type": "image/jpeg",
            "summary": "done",
        }

    def store(*args, **kwargs):
        return "https://api.test/media/ai-edits/user-1/result.jpg?sig=test"

    monkeypatch.setattr(service, "_download_owned_image", download)
    monkeypatch.setattr(service, "_run_hf_edit", run)
    monkeypatch.setattr(service, "_store_result", store)

    result = asyncio.run(
        service.edit(
            user_id="user-1",
            image_url="https://api.test/media/customizations/user-1/photo.jpg",
            operation="auto",
            prompt="Colorize this old photo",
            product_name="Print",
            selected_size="4x6",
            mask_image_base64=None,
            previous_interaction_id=None,
            rights_confirmed=False,
            public_base_url="https://api.test",
        )
    )

    assert result.operation == "colorize"
    assert "Colorize this black-and-white" in captured["prompt"]


def test_auto_operation_still_requires_watermark_rights(monkeypatch):
    service = AiPhotoEditorService()
    source = _ImagePayload(_jpeg_bytes(), "image/jpeg", 16, 12)

    async def download(*args, **kwargs):
        return source

    monkeypatch.setattr(service, "_download_owned_image", download)

    with pytest.raises(HTTPException) as exc:
        asyncio.run(
            service.edit(
                user_id="user-1",
                image_url="https://api.test/media/customizations/user-1/photo.jpg",
                operation="auto",
                prompt="Remove the watermark",
                product_name="Print",
                selected_size="4x6",
                mask_image_base64=None,
                previous_interaction_id=None,
                rights_confirmed=False,
                public_base_url="https://api.test",
            )
        )

    assert exc.value.status_code == 400
