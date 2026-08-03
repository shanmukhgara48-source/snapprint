import logging
import asyncio
from decimal import Decimal
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..dependencies import require_customer
from ..models import PaymentAttempt, PaymentIntent, User
from ..services.event_bus import emit_event
from ..services.payment_service import (
    amount_to_paise,
    create_razorpay_order,
    fetch_razorpay_payment,
    verify_razorpay_signature,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/payments", tags=["payments"])
limiter = Limiter(key_func=get_remote_address)


class RazorpayOrderRequest(BaseModel):
    amount: Decimal = Field(gt=0, le=1_000_000, multiple_of=Decimal("0.01"))


class RazorpayVerifyRequest(BaseModel):
    razorpay_payment_id: str = Field(min_length=1, max_length=256)
    razorpay_order_id: str = Field(min_length=1, max_length=256)
    razorpay_signature: str = Field(min_length=1, max_length=512)


@router.post("/razorpay/order")
@limiter.limit("10/minute")
async def create_order(
    request: Request,
    payload: RazorpayOrderRequest,
    user: Annotated[User, Depends(require_customer)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Create a Razorpay order to be consumed by the Flutter SDK."""
    try:
        result = await asyncio.to_thread(create_razorpay_order, payload.amount)
    except Exception as exc:
        logger.exception("Could not create Razorpay order")
        raise HTTPException(502, "Payment provider is unavailable.") from exc
    db.add(
        PaymentIntent(
            razorpay_order_id=result["razorpay_order_id"],
            user_id=user.id,
            amount_paise=amount_to_paise(payload.amount),
            status="created",
        )
    )
    await db.commit()
    return result


@router.post("/razorpay/verify")
@limiter.limit("20/minute")
async def verify_payment(
    request: Request,
    payload: RazorpayVerifyRequest,
    user: Annotated[User, Depends(require_customer)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Verify Razorpay HMAC signature. Returns ok=True on success.
    Logs every attempt (success or failure) so admins can see failed payments —
    an Order row is only ever created after a successful verify."""
    intent_result = await db.execute(
        select(PaymentIntent)
        .where(
            PaymentIntent.razorpay_order_id == payload.razorpay_order_id,
            PaymentIntent.user_id == user.id,
        )
        .with_for_update()
    )
    intent = intent_result.scalar_one_or_none()
    if intent is None:
        raise HTTPException(400, "Unknown payment order.")
    if intent.status == "consumed":
        if intent.razorpay_payment_id == payload.razorpay_payment_id:
            return {
                "ok": True,
                "payment_id": payload.razorpay_payment_id,
                "order_id": intent.consumed_order_id,
            }
        raise HTTPException(409, "Payment has already been used.")
    if (
        intent.status == "verified"
        and intent.razorpay_payment_id == payload.razorpay_payment_id
    ):
        return {"ok": True, "payment_id": payload.razorpay_payment_id}

    ok = verify_razorpay_signature(
        payload.razorpay_order_id,
        payload.razorpay_payment_id,
        payload.razorpay_signature,
    )
    reason = None if ok else "signature_mismatch"
    if ok:
        try:
            payment = await asyncio.to_thread(
                fetch_razorpay_payment,
                payload.razorpay_payment_id,
            )
        except Exception as exc:
            logger.exception("Could not verify payment with Razorpay")
            raise HTTPException(502, "Payment provider is unavailable.") from exc
        ok = (
            payment["id"] == payload.razorpay_payment_id
            and payment["order_id"] == intent.razorpay_order_id
            and payment["amount"] == intent.amount_paise
            and payment["status"] == "captured"
        )
        if not ok:
            reason = "payment_not_captured_or_amount_mismatch"

    db.add(
        PaymentAttempt(
            razorpay_order_id=payload.razorpay_order_id,
            razorpay_payment_id=payload.razorpay_payment_id,
            status="success" if ok else "failed",
            reason=reason,
            user_id=user.id,
        )
    )
    if ok:
        intent.status = "verified"
        intent.razorpay_payment_id = payload.razorpay_payment_id
    await db.commit()

    # Admin panel only — payment attempts are not customer-facing events
    await emit_event(
        "payment", "succeeded" if ok else "failed",
        payload.razorpay_payment_id,
        {"razorpay_order_id": payload.razorpay_order_id, "user_id": user.id},
        admin_only=True,
    )

    if not ok:
        logger.warning(
            "Payment verification failed: order=%s payment=%s reason=%s",
            payload.razorpay_order_id,
            payload.razorpay_payment_id,
            reason,
        )
        raise HTTPException(status_code=400, detail="Payment verification failed")
    return {"ok": True, "payment_id": payload.razorpay_payment_id}
