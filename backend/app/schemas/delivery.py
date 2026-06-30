from datetime import datetime

from pydantic import BaseModel


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
    status: str
    proof_url: str | None = None
