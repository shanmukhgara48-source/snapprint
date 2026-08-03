from datetime import datetime

from urllib.parse import urlparse

from pydantic import BaseModel, Field, field_validator, model_validator


def _validate_http_url(value: str) -> str:
    value = value.strip()
    parsed = urlparse(value)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise ValueError("image_url must be an HTTP(S) URL")
    return value


class BannerCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    image_url: str = Field(min_length=1, max_length=2048)
    link_action: str | None = Field(default=None, max_length=2048)
    sort_order: int = Field(default=0, ge=-100_000, le=100_000)
    starts_at: datetime | None = None
    ends_at: datetime | None = None

    _valid_url = field_validator("image_url")(_validate_http_url)

    @model_validator(mode="after")
    def valid_schedule(self):
        if self.starts_at and self.ends_at and self.ends_at <= self.starts_at:
            raise ValueError("ends_at must be after starts_at")
        return self


class BannerUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=200)
    image_url: str | None = Field(default=None, min_length=1, max_length=2048)
    link_action: str | None = Field(default=None, max_length=2048)
    sort_order: int | None = Field(default=None, ge=-100_000, le=100_000)
    is_active: bool | None = None
    starts_at: datetime | None = None
    ends_at: datetime | None = None

    @field_validator("image_url")
    @classmethod
    def valid_url(cls, value: str | None) -> str | None:
        return _validate_http_url(value) if value is not None else None


class BannerOut(BaseModel):
    id: str
    title: str
    image_url: str
    link_action: str | None = None
    sort_order: int
    is_active: bool
    starts_at: datetime | None = None
    ends_at: datetime | None = None

    model_config = {"from_attributes": True}
