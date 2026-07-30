from pydantic import BaseModel, Field, field_validator


class AiEditRequest(BaseModel):
    image_url: str
    operation: str = Field(
        ...,
        description="enhance, portrait, background, object_removal, magic_eraser, upscale, colorize, restore, filter, prompt",
    )
    prompt: str = ""
    product_name: str = ""
    selected_size: str = ""
    mask_image_base64: str | None = None
    previous_interaction_id: str | None = None
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
    image_url: str
    product_name: str = ""
    selected_size: str = ""


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
