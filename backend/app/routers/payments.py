import logging
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from ..dependencies import require_customer
from ..models import User
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
) -> dict:
    """Verify Razorpay HMAC signature. Returns ok=True on success."""
    ok = verify_razorpay_signature(
        payload.razorpay_order_id,
        payload.razorpay_payment_id,
        payload.razorpay_signature,
    )
    if not ok:
        logger.warning(
            f"Signature mismatch: order={payload.razorpay_order_id} "
            f"payment={payload.razorpay_payment_id}"
        )
        raise HTTPException(status_code=400, detail="Payment signature verification failed")
    return {"ok": True, "payment_id": payload.razorpay_payment_id}
