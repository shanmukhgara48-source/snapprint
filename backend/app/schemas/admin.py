from datetime import datetime

from pydantic import BaseModel, Field, field_validator, model_validator


class CouponCreate(BaseModel):
    code: str
    discount_type: str  # "percent" | "flat"
    value: float = Field(ge=0)
    min_order: float = Field(default=0, ge=0)
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

    @model_validator(mode="after")
    def percent_within_range(self) -> "CouponCreate":
        if self.discount_type == "percent" and self.value > 100:
            raise ValueError("value cannot exceed 100 for a percent coupon")
        return self


class CouponUpdate(BaseModel):
    discount_type: str | None = None
    value: float | None = Field(default=None, ge=0)
    min_order: float | None = Field(default=None, ge=0)
    max_uses: int | None = None
    is_active: bool | None = None
    expires_at: datetime | None = None

    @field_validator("discount_type")
    @classmethod
    def valid_type(cls, v: str | None) -> str | None:
        if v is not None and v not in ("percent", "flat"):
            raise ValueError("discount_type must be 'percent' or 'flat'")
        return v

    @model_validator(mode="after")
    def percent_within_range(self) -> "CouponUpdate":
        # Only catches the case where both fields are supplied together in
        # the same PATCH; the case where value alone is later raised above
        # an existing percent coupon's 100 cap is enforced in the router,
        # which has the current DB row to check against.
        if self.discount_type == "percent" and self.value is not None and self.value > 100:
            raise ValueError("value cannot exceed 100 for a percent coupon")
        return self


class CouponOut(BaseModel):
    id: str
    code: str
    discount_type: str
    value: float
    min_order: float
    expires_at: datetime | None = None
    created_at: datetime

    model_config = {"from_attributes": True}
