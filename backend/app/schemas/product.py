from datetime import date
from urllib.parse import urlparse

from pydantic import BaseModel, Field, field_validator, model_validator


def _validate_image_urls(values: list[str] | None) -> list[str] | None:
    if values is None:
        return None
    for value in values:
        parsed = urlparse(value)
        if len(value) > 2048 or parsed.scheme not in {"http", "https"} or not parsed.netloc:
            raise ValueError("Every product image must be an HTTP(S) URL")
    return values


def _validate_optional_url(value: str | None) -> str | None:
    if value is None:
        return None
    parsed = urlparse(value)
    if len(value) > 2048 or parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise ValueError("Source URL must be an HTTP(S) URL")
    return value


class ProductSizeSchema(BaseModel):
    label: str = Field(min_length=1, max_length=100)
    price: float = Field(gt=0, le=10_000_000)


class ProductCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    category: str = Field(min_length=1, max_length=100)
    category_id: str | None = Field(default=None, max_length=128)
    base_price: float = Field(ge=0, le=10_000_000)
    sizes: list[ProductSizeSchema] = Field(default_factory=list, max_length=100)
    images: list[str] = Field(default_factory=list, max_length=20)
    description: str | None = Field(default=None, max_length=5000)
    material: str | None = Field(default=None, max_length=5000)
    dimensions: str | None = Field(default=None, max_length=2000)
    options_summary: str | None = Field(default=None, max_length=5000)
    delivery_info: str | None = Field(default=None, max_length=5000)
    price_note: str | None = Field(default=None, max_length=2000)
    source_url: str | None = None
    source_checked_on: date | None = None
    source_rating: float | None = Field(default=None, ge=0, le=5)
    source_review_count: int | None = Field(default=None, ge=0)
    sort_order: int = Field(default=0, ge=-100_000, le=100_000)
    stock_quantity: int = Field(default=0, ge=0, le=10_000_000)
    tracks_inventory: bool = False
    is_featured: bool = False
    is_trending: bool = False
    is_orderable: bool = True

    _valid_images = field_validator("images")(_validate_image_urls)
    _valid_source_url = field_validator("source_url")(_validate_optional_url)

    @model_validator(mode="after")
    def has_a_sellable_price(self):
        if self.is_orderable and self.base_price <= 0 and not self.sizes:
            raise ValueError("A product must have a positive base or size price")
        return self


class ProductUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=200)
    category: str | None = Field(default=None, min_length=1, max_length=100)
    category_id: str | None = Field(default=None, max_length=128)
    base_price: float | None = Field(default=None, ge=0, le=10_000_000)
    sizes: list[ProductSizeSchema] | None = Field(default=None, max_length=100)
    images: list[str] | None = Field(default=None, max_length=20)
    description: str | None = Field(default=None, max_length=5000)
    material: str | None = Field(default=None, max_length=5000)
    dimensions: str | None = Field(default=None, max_length=2000)
    options_summary: str | None = Field(default=None, max_length=5000)
    delivery_info: str | None = Field(default=None, max_length=5000)
    price_note: str | None = Field(default=None, max_length=2000)
    source_url: str | None = None
    source_checked_on: date | None = None
    source_rating: float | None = Field(default=None, ge=0, le=5)
    source_review_count: int | None = Field(default=None, ge=0)
    sort_order: int | None = Field(default=None, ge=-100_000, le=100_000)
    stock_quantity: int | None = Field(default=None, ge=0, le=10_000_000)
    tracks_inventory: bool | None = None
    is_featured: bool | None = None
    is_trending: bool | None = None
    is_orderable: bool | None = None
    is_active: bool | None = None

    _valid_images = field_validator("images")(_validate_image_urls)
    _valid_source_url = field_validator("source_url")(_validate_optional_url)


class ProductOut(BaseModel):
    id: str
    name: str
    category: str
    category_id: str | None = None
    base_price: float
    sizes: list[dict]
    images: list[str]
    description: str | None = None
    material: str | None = None
    dimensions: str | None = None
    options_summary: str | None = None
    delivery_info: str | None = None
    price_note: str | None = None
    source_url: str | None = None
    source_checked_on: date | None = None
    source_rating: float | None = None
    source_review_count: int | None = None
    sort_order: int
    stock_quantity: int
    tracks_inventory: bool
    is_featured: bool
    is_trending: bool
    is_orderable: bool
    is_active: bool

    model_config = {"from_attributes": True}


class ProductListResponse(BaseModel):
    items: list[ProductOut]
    total: int
    page: int
    limit: int
