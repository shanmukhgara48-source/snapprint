from typing import Literal

from pydantic import BaseModel, Field, field_validator, model_validator


class NormalizedRect(BaseModel):
    left: float = Field(ge=0, le=1)
    top: float = Field(ge=0, le=1)
    width: float = Field(gt=0, le=1)
    height: float = Field(gt=0, le=1)

    @model_validator(mode="after")
    def stays_inside_image(self):
        if self.left + self.width > 1.000001 or self.top + self.height > 1.000001:
            raise ValueError("Normalized rectangles must stay inside the image.")
        return self


class AiEditorCapabilities(BaseModel):
    enabled: bool
    background_removal: bool
    generative_editing: bool
    model: str
    max_source_bytes: int
    max_source_pixels: int
    supported_input_formats: list[str]
    supported_output_formats: list[str]


class BackgroundRemovalRequest(BaseModel):
    image_url: str = Field(min_length=1, max_length=2048)
    quality: Literal["standard", "high"] = "high"
    refine_foreground: bool = True
    preserve_existing_alpha: bool = True


class BackgroundRemovalResponse(BaseModel):
    foreground_url: str
    width: int
    height: int
    subject_bounds: NormalizedRect
    model: str
    processing_ms: int
    warnings: list[str] = Field(default_factory=list)


class EditorAdjustments(BaseModel):
    brightness: float = Field(default=0, ge=-1, le=1)
    contrast: float = Field(default=0, ge=-1, le=1)
    saturation: float = Field(default=0, ge=-1, le=1)
    temperature: float = Field(default=0, ge=-1, le=1)
    tint: float = Field(default=0, ge=-1, le=1)
    vibrance: float = Field(default=0, ge=-1, le=1)
    exposure: float = Field(default=0, ge=-2, le=2)
    highlights: float = Field(default=0, ge=-1, le=1)
    shadows: float = Field(default=0, ge=-1, le=1)
    sharpness: float = Field(default=0, ge=0, le=1)


class EditorTransform(BaseModel):
    crop: NormalizedRect | None = None
    rotation_quarter_turns: int = Field(default=0, ge=0, le=3)
    straighten_degrees: float = Field(default=0, ge=-15, le=15)
    offset_x: float = Field(default=0, ge=-1, le=1)
    offset_y: float = Field(default=0, ge=-1, le=1)
    flip_horizontal: bool = False
    flip_vertical: bool = False


class EditorBackground(BaseModel):
    kind: Literal["transparent", "solid", "gradient", "image"] = "transparent"
    color: str = Field(default="#FFFFFF", pattern=r"^#[0-9A-Fa-f]{6}$")
    gradient_start: str = Field(default="#FFFFFF", pattern=r"^#[0-9A-Fa-f]{6}$")
    gradient_end: str = Field(default="#DDE7F2", pattern=r"^#[0-9A-Fa-f]{6}$")
    image_url: str | None = Field(default=None, max_length=2048)


class AiExportRequest(BaseModel):
    image_url: str = Field(min_length=1, max_length=2048)
    background: EditorBackground = Field(default_factory=EditorBackground)
    adjustments: EditorAdjustments = Field(default_factory=EditorAdjustments)
    transform: EditorTransform = Field(default_factory=EditorTransform)
    selected_size: str = Field(default="", max_length=100)
    output_format: Literal["auto", "png", "jpeg"] = "auto"


class AiExportResponse(BaseModel):
    image_url: str
    width: int
    height: int
    mime_type: str
    file_size_bytes: int
    dpi_estimate: int | None = None
    processing_ms: int
    warnings: list[str] = Field(default_factory=list)


class AiEditRequest(BaseModel):
    image_url: str = Field(min_length=1, max_length=2048)
    operation: str = Field(
        ...,
        description="auto, enhance, portrait, background, object_removal, magic_eraser, upscale, colorize, restore, filter, prompt",
    )
    prompt: str = Field(default="", max_length=4000)
    product_name: str = Field(default="", max_length=200)
    selected_size: str = Field(default="", max_length=100)
    mask_image_base64: str | None = Field(default=None, max_length=20_000_000)
    previous_interaction_id: str | None = Field(default=None, max_length=256)
    rights_confirmed: bool = False

    @field_validator("operation")
    @classmethod
    def normalize_operation(cls, value: str) -> str:
        return value.strip().lower().replace("-", "_")


class AiEditResponse(BaseModel):
    edited_image_url: str
    interaction_id: str | None = None
    operation: str
    summary: str = ""


class AiAnalyzeRequest(BaseModel):
    image_url: str = Field(min_length=1, max_length=2048)
    product_name: str = Field(default="", max_length=200)
    selected_size: str = Field(default="", max_length=100)


class AiAnalyzeResponse(BaseModel):
    score: int
    resolution: str
    dpi_estimate: str
    blur: str
    noise: str
    exposure: str
    faces: str
    crop_recommendation: str
    suggestions: list[str]
