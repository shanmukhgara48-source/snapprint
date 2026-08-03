import io

import pytest
from PIL import Image
from pydantic import ValidationError

from app.schemas.ai_editor import (
    AiExportRequest,
    EditorAdjustments,
    EditorBackground,
    EditorTransform,
    NormalizedRect,
)
from app.services.professional_image_pipeline import (
    ImageAsset,
    _alpha_bounds,
    _estimate_numeric_dpi,
    _render_export,
    path_belongs_to_user,
)


def _source_png() -> ImageAsset:
    image = Image.new("RGBA", (100, 80), (0, 0, 0, 0))
    image.paste((220, 30, 40, 255), (20, 10, 80, 70))
    buffer = io.BytesIO()
    image.save(buffer, format="PNG", dpi=(300, 300))
    return ImageAsset(
        data=buffer.getvalue(),
        mime_type="image/png",
        width=100,
        height=80,
        dpi=(300, 300),
        icc_profile=None,
    )


def test_owned_paths_are_scoped_to_the_authenticated_user():
    assert path_belongs_to_user("/customizations/user-1/photo.jpg", "user-1")
    assert path_belongs_to_user("/ai-edits/user-1/cutout.png", "user-1")
    assert not path_belongs_to_user("/cdn/ai-edits/user-1/cutout.png", "user-1")
    assert not path_belongs_to_user("/customizations/user-2/photo.jpg", "user-1")
    assert not path_belongs_to_user(
        "/customizations/user-1/../user-2/photo.jpg", "user-1"
    )


def test_alpha_bounds_capture_the_soft_cutout_extent():
    bounds = _alpha_bounds(_source_png().data)
    assert bounds.left == pytest.approx(0.2)
    assert bounds.top == pytest.approx(0.125)
    assert bounds.width == pytest.approx(0.6)
    assert bounds.height == pytest.approx(0.75)


def test_transparent_export_preserves_alpha_resolution_and_dpi():
    rendered, mime_type, dpi = _render_export(
        _source_png(),
        AiExportRequest(image_url="https://cdn.test/ai-edits/user-1/cutout.png"),
        None,
    )
    with Image.open(io.BytesIO(rendered)) as result:
        assert result.size == (100, 80)
        assert result.mode == "RGBA"
        assert result.getchannel("A").getextrema() == (0, 255)
        assert result.info["dpi"][0] == pytest.approx(300, abs=1)
    assert mime_type == "image/png"
    assert dpi == (300, 300)


def test_solid_background_and_crop_export_one_high_quality_jpeg():
    request = AiExportRequest(
        image_url="https://cdn.test/ai-edits/user-1/cutout.png",
        background=EditorBackground(kind="solid", color="#FFFFFF"),
        transform=EditorTransform(
            crop=NormalizedRect(left=0.1, top=0.125, width=0.8, height=0.75)
        ),
    )
    rendered, mime_type, _ = _render_export(_source_png(), request, None)
    with Image.open(io.BytesIO(rendered)) as result:
        assert result.size == (80, 60)
        assert result.mode == "RGB"
        assert result.getpixel((0, 0)) == pytest.approx((255, 255, 255), abs=5)
    assert mime_type == "image/jpeg"


def test_smart_center_translation_preserves_canvas_and_alpha():
    request = AiExportRequest(
        image_url="https://cdn.test/ai-edits/user-1/cutout.png",
        transform=EditorTransform(offset_x=0.1, offset_y=-0.05),
    )
    rendered, mime_type, _ = _render_export(_source_png(), request, None)
    bounds = _alpha_bounds(rendered)
    assert mime_type == "image/png"
    assert bounds.left == pytest.approx(0.3)
    assert bounds.top == pytest.approx(0.075)
    with Image.open(io.BytesIO(rendered)) as result:
        assert result.size == (100, 80)


def test_all_adjustments_render_in_strips_without_losing_alpha():
    request = AiExportRequest(
        image_url="https://cdn.test/ai-edits/user-1/cutout.png",
        adjustments=EditorAdjustments(
            brightness=0.1,
            contrast=0.1,
            saturation=0.1,
            temperature=0.1,
            tint=-0.1,
            vibrance=0.1,
            exposure=0.2,
            highlights=-0.1,
            shadows=0.1,
            sharpness=0.2,
        ),
    )
    rendered, mime_type, _ = _render_export(_source_png(), request, None)
    with Image.open(io.BytesIO(rendered)) as result:
        assert result.size == (100, 80)
        assert result.getchannel("A").getextrema() == (0, 255)
    assert mime_type == "image/png"


def test_invalid_crop_cannot_escape_the_source_image():
    with pytest.raises(ValidationError):
        NormalizedRect(left=0.8, top=0, width=0.4, height=1)


@pytest.mark.parametrize(
    ("width", "height", "size", "expected"),
    [
        (1200, 1800, "4x6", 300),
        (1200, 1800, '4 x 6"', 300),
        (2400, 3000, "8x10 in", 300),
        (1, 1, "", None),
    ],
)
def test_print_dpi_estimate(width, height, size, expected):
    assert _estimate_numeric_dpi(width, height, size) == expected
