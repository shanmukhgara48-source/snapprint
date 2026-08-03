import hashlib
import hmac
from decimal import Decimal, ROUND_HALF_UP

import razorpay

from ..config import settings


def get_razorpay_client() -> razorpay.Client:
    return razorpay.Client(
        auth=(settings.razorpay_key_id, settings.razorpay_key_secret)
    )


def amount_to_paise(amount_inr: Decimal | float | str) -> int:
    return int(
        (Decimal(str(amount_inr)) * 100).quantize(
            Decimal("1"), rounding=ROUND_HALF_UP
        )
    )


def create_razorpay_order(
    amount_inr: Decimal | float | str,
    currency: str = "INR",
) -> dict:
    """Create a Razorpay order. Amount in INR — converted to paise internally."""
    client = get_razorpay_client()
    order = client.order.create(
        {
            "amount": amount_to_paise(amount_inr),
            "currency": currency,
            "payment_capture": 1,
        }
    )
    return {
        "razorpay_order_id": order["id"],
        "amount": float(amount_inr),
        "currency": currency,
        "order_id": order["id"],
    }


def verify_razorpay_signature(
    razorpay_order_id: str,
    razorpay_payment_id: str,
    razorpay_signature: str,
) -> bool:
    """
    Verify HMAC-SHA256 signature from Razorpay.
    Message = razorpay_order_id | razorpay_payment_id
    """
    message = f"{razorpay_order_id}|{razorpay_payment_id}"
    expected = hmac.new(
        settings.razorpay_key_secret.encode(),
        message.encode(),
        hashlib.sha256,
    ).hexdigest()
    return hmac.compare_digest(expected, razorpay_signature)


def get_paid_amount_paise(razorpay_order_id: str) -> int:
    """
    Fetch the amount actually paid for a Razorpay order, straight from
    Razorpay's servers. A valid signature only proves a payment/order pair is
    authentic — it says nothing about the amount, so callers must cross-check
    this against the server-computed order total before trusting the payment.
    """
    client = get_razorpay_client()
    order = client.order.fetch(razorpay_order_id)
    return int(order["amount_paid"])


def fetch_razorpay_payment(razorpay_payment_id: str) -> dict:
    payment = get_razorpay_client().payment.fetch(razorpay_payment_id)
    return {
        "id": str(payment.get("id", "")),
        "order_id": str(payment.get("order_id", "")),
        "amount": int(payment.get("amount", 0)),
        "status": str(payment.get("status", "")),
        "amount_refunded": int(payment.get("amount_refunded", 0)),
        "refund_status": payment.get("refund_status"),
    }


def refund_razorpay_payment(
    razorpay_payment_id: str,
    amount_paise: int,
    *,
    receipt: str,
) -> dict:
    """Issue an idempotent full refund for a captured payment."""
    client = get_razorpay_client()
    payment = client.payment.fetch(razorpay_payment_id)
    if int(payment.get("amount_refunded", 0)) >= amount_paise:
        return {
            "id": "",
            "status": "processed",
            "amount": amount_paise,
        }
    refund = client.payment.refund(
        razorpay_payment_id,
        {
            "amount": amount_paise,
            "speed": "normal",
            "receipt": receipt,
            "notes": {"snapprint_order_id": receipt.removeprefix("snapprint-")},
        },
    )
    return {
        "id": str(refund.get("id", "")),
        "status": str(refund.get("status", "pending")),
        "amount": int(refund.get("amount", 0)),
    }
