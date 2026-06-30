from pydantic import BaseModel


class CartItemInput(BaseModel):
    product_id: str
    qty: int
    size: str = ""
    image_url: str | None = None


class CartCalculateRequest(BaseModel):
    items: list[CartItemInput]
    delivery_type: str = "free"  # free | standard | express
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
