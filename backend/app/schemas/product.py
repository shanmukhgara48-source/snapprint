from pydantic import BaseModel


class ProductSizeSchema(BaseModel):
    label: str
    price: float


class ProductCreate(BaseModel):
    name: str
    category: str
    category_id: str | None = None
    base_price: float
    sizes: list[ProductSizeSchema] = []
    images: list[str] = []
    description: str | None = None
    sort_order: int = 0
    stock_quantity: int = 0
    is_featured: bool = False
    is_trending: bool = False


class ProductUpdate(BaseModel):
    name: str | None = None
    category: str | None = None
    category_id: str | None = None
    base_price: float | None = None
    sizes: list[ProductSizeSchema] | None = None
    images: list[str] | None = None
    description: str | None = None
    sort_order: int | None = None
    stock_quantity: int | None = None
    is_featured: bool | None = None
    is_trending: bool | None = None
    is_active: bool | None = None


class ProductOut(BaseModel):
    id: str
    name: str
    category: str
    category_id: str | None = None
    base_price: float
    sizes: list[dict]
    images: list[str]
    description: str | None = None
    sort_order: int
    stock_quantity: int
    is_featured: bool
    is_trending: bool
    is_active: bool

    model_config = {"from_attributes": True}


class ProductListResponse(BaseModel):
    items: list[ProductOut]
    total: int
    page: int
    limit: int
