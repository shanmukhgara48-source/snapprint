from datetime import datetime

from pydantic import BaseModel, field_validator


class CouponCreate(BaseModel):
    code: str
    discount_type: str  # "percent" | "flat"
    value: float
    min_order: float = 0
    expires_at: datetime | None = None

    @field_validator("code")
    @classmethod
    def uppercase_code(cls, v: str) -> str:
        return v.strip().upper()

    @field_validator("discount_type")
    @classmethod
    def valid_type(cls, v: str) -> str:
        if v not in ("percent", "flat"):
            raise ValueError("discount_type must be 'percent' or 'flat'")
        return v


class CouponOut(BaseModel):
    id: str
    code: str
    discount_type: str
    value: float
    min_order: float
    expires_at: datetime | None = None
    created_at: datetime

    model_config = {"from_attributes": True}
