from datetime import datetime

from pydantic import BaseModel


class OrderItemCreate(BaseModel):
    product_id: str
    qty: int
    size: str = ""
    image_url: str | None = None
    price: float


class OrderCreate(BaseModel):
    items: list[OrderItemCreate]
    address_id: str
    delivery_type: str = "free"
    coupon_code: str | None = None
    razorpay_payment_id: str | None = None
    razorpay_order_id: str | None = None
    razorpay_signature: str | None = None


class TrackingEventOut(BaseModel):
    status: str
    timestamp: datetime

    model_config = {"from_attributes": True}


class OrderOut(BaseModel):
    id: str
    total_price: float
    status: str
    created_at: datetime
    item_count: int = 0
    delivery_address: str | None = None
    estimated_delivery: datetime | None = None
    tracking_events: list[TrackingEventOut] = []

    model_config = {"from_attributes": True}


class OrderStatusUpdate(BaseModel):
    status: str
