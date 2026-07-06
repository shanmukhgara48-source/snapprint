from pydantic import BaseModel


class CategoryCreate(BaseModel):
    name: str
    icon: str = ""
    image_url: str | None = None
    sort_order: int = 0


class CategoryUpdate(BaseModel):
    name: str | None = None
    icon: str | None = None
    image_url: str | None = None
    sort_order: int | None = None
    is_active: bool | None = None


class CategoryOut(BaseModel):
    id: str
    name: str
    icon: str
    image_url: str | None = None
    sort_order: int
    is_active: bool

    model_config = {"from_attributes": True}
