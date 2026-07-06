from datetime import datetime

from pydantic import BaseModel


class BannerCreate(BaseModel):
    title: str
    image_url: str
    link_action: str | None = None
    sort_order: int = 0
    starts_at: datetime | None = None
    ends_at: datetime | None = None


class BannerUpdate(BaseModel):
    title: str | None = None
    image_url: str | None = None
    link_action: str | None = None
    sort_order: int | None = None
    is_active: bool | None = None
    starts_at: datetime | None = None
    ends_at: datetime | None = None


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
