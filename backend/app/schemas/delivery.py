from datetime import datetime

from typing import Literal

from pydantic import BaseModel, Field


class DeliveryOrderOut(BaseModel):
    id: str
    status: str
    customer_phone: str
    pickup_address: str
    delivery_address: str
    delivery_city: str
    delivery_pincode: str
    total_price: float
    item_count: int
    delivery_lat: float | None = None
    delivery_lng: float | None = None
    proof_url: str | None = None
    assigned_at: datetime | None = None

    model_config = {"from_attributes": True}


class DeliveryStatusUpdate(BaseModel):
    status: Literal["picked_up", "out_for_delivery", "delivered"]
    proof_url: str | None = Field(default=None, max_length=2048)
