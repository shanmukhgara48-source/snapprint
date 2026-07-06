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


class CouponUpdate(BaseModel):
    discount_type: str | None = None
    value: float | None = None
    min_order: float | None = None
    max_uses: int | None = None
    is_active: bool | None = None
    expires_at: datetime | None = None

    @field_validator("discount_type")
    @classmethod
    def valid_type(cls, v: str | None) -> str | None:
        if v is not None and v not in ("percent", "flat"):
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
