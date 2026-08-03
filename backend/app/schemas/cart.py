from pydantic import BaseModel, Field


class CartItemInput(BaseModel):
    product_id: str
    qty: int = Field(ge=1, le=99)
    size: str = ""
    image_url: str | None = None


class CartCalculateRequest(BaseModel):
    items: list[CartItemInput] = Field(max_length=100)
    delivery_type: str = Field(default="free", min_length=1, max_length=50)
    coupon_code: str | None = None


class CartItemResult(BaseModel):
    product_id: str
    name: str
    size: str
    qty: int
    unit_price: float
    line_total: float
    image_url: str | None = None


class DeliveryOption(BaseModel):
    type: str
    label: str
    price: float
    days: str


class CartCalculateResponse(BaseModel):
    items: list[CartItemResult]
    subtotal: float
    delivery_charge: float
    discount: float
    total: float
    coupon_applied: bool
    delivery_options: list[DeliveryOption]
