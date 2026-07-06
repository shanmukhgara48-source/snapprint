from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..dependencies import require_customer
from ..models import Coupon, User

router = APIRouter(prefix="/coupons", tags=["coupons"])


class ActiveCouponOut(BaseModel):
    code: str
    discount_type: str
    value: float
    min_order: float
    expires_at: datetime | None = None

    model_config = {"from_attributes": True}


@router.get("/active", response_model=list[ActiveCouponOut])
async def list_active_coupons(
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[Coupon]:
    """Public list of currently redeemable coupons, shown as 'Offers' in the app."""
    now = datetime.now(timezone.utc)
    result = await db.execute(
        select(Coupon).where(
            Coupon.is_active.is_(True),
            or_(Coupon.expires_at.is_(None), Coupon.expires_at >= now),
        ).order_by(Coupon.created_at.desc())
    )
    coupons = [
        c for c in result.scalars().all()
        if c.max_uses is None or c.used_count < c.max_uses
    ]
    return coupons


class CouponValidateRequest(BaseModel):
    code: str
    subtotal: float


class CouponValidateResponse(BaseModel):
    valid: bool
    discount_amount: float = 0
    discount_type: str = ""
    message: str


@router.post("/validate", response_model=CouponValidateResponse)
async def validate_coupon(
    payload: CouponValidateRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_customer)],
) -> CouponValidateResponse:
    """
    Quickly validates a coupon code against the current cart subtotal.
    Returns discount amount if valid. Called when user taps Apply in cart.
    """
    result = await db.execute(
        select(Coupon).where(
            Coupon.code == payload.code.strip().upper(),
            Coupon.is_active.is_(True),
        )
    )
    coupon = result.scalar_one_or_none()

    if coupon is None:
        return CouponValidateResponse(valid=False, message="Invalid coupon code")

    now = datetime.now(timezone.utc)
    if coupon.expires_at and coupon.expires_at < now:
        return CouponValidateResponse(valid=False, message="Coupon has expired")

    if coupon.max_uses and coupon.used_count >= coupon.max_uses:
        return CouponValidateResponse(valid=False, message="Coupon usage limit reached")

    if payload.subtotal < coupon.min_order:
        return CouponValidateResponse(
            valid=False,
            message=f"Minimum order ₹{coupon.min_order:.0f} required for this coupon",
        )

    if coupon.discount_type == "percent":
        discount = round(payload.subtotal * coupon.value / 100, 2)
    else:
        discount = min(coupon.value, payload.subtotal)

    return CouponValidateResponse(
        valid=True,
        discount_amount=discount,
        discount_type=coupon.discount_type,
        message=f"Coupon applied! You save ₹{discount:.0f}",
    )
