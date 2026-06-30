import hashlib
import hmac

import razorpay

from ..config import settings


def get_razorpay_client() -> razorpay.Client:
    return razorpay.Client(
        auth=(settings.razorpay_key_id, settings.razorpay_key_secret)
    )


def create_razorpay_order(amount_inr: float, currency: str = "INR") -> dict:
    """Create a Razorpay order. Amount in INR — converted to paise internally."""
    client = get_razorpay_client()
    order = client.order.create(
        {
            "amount": int(amount_inr * 100),  # paise
            "currency": currency,
            "payment_capture": 1,
        }
    )
    return {
        "razorpay_order_id": order["id"],
        "amount": amount_inr,
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
