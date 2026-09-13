from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

ReturnReason = Literal[
    "damaged", "wrong_item", "quality_issue", "late_delivery", "changed_mind", "other"
]

RETURNABLE_STATUSES = {"confirmed", "picked_up", "out_for_delivery", "delivered"}
OPEN_RETURN_STATUSES = {"requested", "approved"}


class ReturnCreate(BaseModel):
    order_id: str = Field(min_length=1, max_length=128)
    reason: ReturnReason
    details: str | None = Field(default=None, max_length=2000)


class ReturnOut(BaseModel):
    id: str
    order_id: str
    reason: str
    details: str | None = None
    status: str
    admin_note: str | None = None
    order_status: str | None = None
    order_total: float | None = None
    created_at: datetime
    decided_at: datetime | None = None

    model_config = {"from_attributes": True}


class AdminReturnOut(ReturnOut):
    customer_phone: str | None = None
    item_count: int = 0


class AdminReturnDecision(BaseModel):
    action: Literal["approve", "reject", "refund"]
    admin_note: str | None = Field(default=None, max_length=2000)
