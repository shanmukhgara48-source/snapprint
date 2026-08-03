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


def test_gemini_edit_requests_4k_output(monkeypatch):
    captured = {}

    class Interactions:
        def create(self, **kwargs):
            captured.update(kwargs)
            image = type(
                "OutputImage",
                (),
                {
                    "data": base64.b64encode(_jpeg_bytes()).decode(),
                    "mime_type": "image/jpeg",
                },
            )()
            return type(
                "Interaction",
                (),
                {"output_image": image, "id": "interaction-1", "output_text": "done"},
            )()

    client = type("Client", (), {"interactions": Interactions()})()
    service = AiPhotoEditorService()
    monkeypatch.setattr(service, "_client", lambda: client)
    source = _ImagePayload(_jpeg_bytes(), "image/jpeg", 16, 12)

    result = service._run_gemini_edit(source, "enhance", None, None)

    assert captured["response_format"]["image_size"] == "4K"
    assert result["image_bytes"] == _jpeg_bytes()


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
    monkeypatch.setattr(service, "_run_gemini_edit", fail)

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
    assert _classify_prompt_operation("Upscale to 4K") == "upscale"
    assert _classify_prompt_operation("Colorize this old photo") == "colorize"
    assert _classify_prompt_operation("Fix scratches") == "restore"
    assert _classify_prompt_operation("Turn this into anime") == "filter"


def test_auto_operation_uses_classified_prompt_pipeline(monkeypatch):
    service = AiPhotoEditorService()
    source = _ImagePayload(_jpeg_bytes(), "image/jpeg", 16, 12)
    captured = {}

    async def download(*args, **kwargs):
        return source

    def run(source, prompt, mask_image_base64, previous_interaction_id):
        captured["prompt"] = prompt
        return {
            "image_bytes": _jpeg_bytes(),
            "mime_type": "image/jpeg",
            "interaction_id": "interaction-1",
            "summary": "done",
        }

    def store(*args, **kwargs):
        return "https://api.test/media/ai-edits/user-1/result.jpg?sig=test"

    monkeypatch.setattr(service, "_download_owned_image", download)
    monkeypatch.setattr(service, "_run_gemini_edit", run)
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
