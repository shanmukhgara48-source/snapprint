from datetime import datetime

from pydantic import BaseModel, Field


class OrderItemCreate(BaseModel):
    product_id: str = Field(min_length=1, max_length=128)
    qty: int = Field(ge=1, le=99)
    size: str = Field(default="", max_length=100)
    image_url: str | None = Field(default=None, max_length=2048)
    price: float = Field(ge=0, le=10_000_000)


class OrderCreate(BaseModel):
    items: list[OrderItemCreate] = Field(min_length=1, max_length=100)
    address_id: str = Field(min_length=1, max_length=128)
    delivery_type: str = Field(default="free", min_length=1, max_length=50)
    coupon_code: str | None = Field(default=None, max_length=64)
    razorpay_payment_id: str | None = Field(default=None, max_length=256)
    razorpay_order_id: str | None = Field(default=None, max_length=256)
    razorpay_signature: str | None = Field(default=None, max_length=512)
    # Purchase channel: "mobile_app" | "website" | "admin".
    # Optional for backward compat — backend falls back to the
    # X-Client-Source header / User-Agent heuristic, then "unknown".
    source: str | None = Field(default=None, max_length=32)
    # Gift wrap for the whole order + optional message (max 500 chars).
    gift_wrap: bool = False
    gift_message: str | None = Field(default=None, max_length=500)


class TrackingEventOut(BaseModel):
    status: str
    timestamp: datetime

    model_config = {"from_attributes": True}


class OrderOut(BaseModel):
    id: str
    total_price: float
    status: str
    source: str = "unknown"
    gift_wrap: bool = False
    gift_wrap_charge: float = 0
    gift_message: str | None = None
    created_at: datetime
    item_count: int = 0
    delivery_address: str | None = None
    estimated_delivery: datetime | None = None
    tracking_events: list[TrackingEventOut] = Field(default_factory=list)

    model_config = {"from_attributes": True}


class OrderStatusUpdate(BaseModel):
    status: str
