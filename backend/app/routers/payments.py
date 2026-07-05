import logging
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..dependencies import require_customer
from ..models import PaymentAttempt, User
from ..services.payment_service import create_razorpay_order, verify_razorpay_signature

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/payments", tags=["payments"])


class RazorpayOrderRequest(BaseModel):
    amount: float  # INR


class RazorpayVerifyRequest(BaseModel):
    razorpay_payment_id: str
    razorpay_order_id: str
    razorpay_signature: str


@router.post("/razorpay/order")
async def create_order(
    payload: RazorpayOrderRequest,
    user: Annotated[User, Depends(require_customer)],
) -> dict:
    """Create a Razorpay order to be consumed by the Flutter SDK."""
    if payload.amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")
    return create_razorpay_order(payload.amount)


@router.post("/razorpay/verify")
async def verify_payment(
    payload: RazorpayVerifyRequest,
    user: Annotated[User, Depends(require_customer)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Verify Razorpay HMAC signature. Returns ok=True on success.
    Logs every attempt (success or failure) so admins can see failed payments —
    an Order row is only ever created after a successful verify."""
    ok = verify_razorpay_signature(
        payload.razorpay_order_id,
        payload.razorpay_payment_id,
        payload.razorpay_signature,
    )
    db.add(PaymentAttempt(
        razorpay_order_id=payload.razorpay_order_id,
        razorpay_payment_id=payload.razorpay_payment_id,
        status="success" if ok else "failed",
        reason=None if ok else "signature_mismatch",
        user_id=user.id,
    ))
    await db.commit()

    if not ok:
        logger.warning(
            f"Signature mismatch: order={payload.razorpay_order_id} "
            f"payment={payload.razorpay_payment_id}"
        )
        raise HTTPException(status_code=400, detail="Payment signature verification failed")
    return {"ok": True, "payment_id": payload.razorpay_payment_id}
