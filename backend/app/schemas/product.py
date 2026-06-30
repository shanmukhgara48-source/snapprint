from pydantic import BaseModel


class ProductSizeSchema(BaseModel):
    label: str
    price: float


class ProductCreate(BaseModel):
    name: str
    category: str
    base_price: float
    sizes: list[ProductSizeSchema] = []
    image_url: str = ""
    description: str | None = None


class ProductUpdate(BaseModel):
    name: str | None = None
    category: str | None = None
    base_price: float | None = None
    sizes: list[ProductSizeSchema] | None = None
    image_url: str | None = None
    description: str | None = None
    is_active: bool | None = None


class ProductOut(BaseModel):
    id: str
    name: str
    category: str
    base_price: float
    sizes: list[dict]
    image_url: str
    description: str | None = None
    is_active: bool

    model_config = {"from_attributes": True}


class ProductListResponse(BaseModel):
    items: list[ProductOut]
    total: int
    page: int
    limit: int
