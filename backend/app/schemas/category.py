from urllib.parse import urlparse

from pydantic import BaseModel, Field, field_validator


def _validate_optional_http_url(value: str | None) -> str | None:
    if value is None:
        return None
    value = value.strip()
    parsed = urlparse(value)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise ValueError("image_url must be an HTTP(S) URL")
    return value


class CategoryCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    icon: str = Field(default="", max_length=100)
    image_url: str | None = Field(default=None, max_length=2048)
    sort_order: int = Field(default=0, ge=-100_000, le=100_000)

    _valid_url = field_validator("image_url")(_validate_optional_http_url)


class CategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    icon: str | None = Field(default=None, max_length=100)
    image_url: str | None = Field(default=None, max_length=2048)
    sort_order: int | None = Field(default=None, ge=-100_000, le=100_000)
    is_active: bool | None = None

    _valid_url = field_validator("image_url")(_validate_optional_http_url)


class CategoryOut(BaseModel):
    id: str
    name: str
    icon: str
    image_url: str | None = None
    sort_order: int
    is_active: bool

    model_config = {"from_attributes": True}
