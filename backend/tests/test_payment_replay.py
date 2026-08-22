import hashlib
import hmac
import uuid
import asyncio

from fastapi.testclient import TestClient

from app.config import settings
from app.database import AsyncSessionLocal, engine
from app.models import Order, User
from app.routers import auth, payments
from main import app


def _signature(order_id: str, payment_id: str) -> str:
    return hmac.new(
        settings.razorpay_key_secret.encode(),
        f"{order_id}|{payment_id}".encode(),
        hashlib.sha256,
    ).hexdigest()


async def _mark_delivered(order_id: str) -> None:
    async with AsyncSessionLocal() as db:
        order = await db.get(Order, order_id)
        order.status = "delivered"
        await db.commit()
    await engine.dispose()


async def _verify_anonymized_and_cleanup(user_id: str, order_id: str) -> None:
    async with AsyncSessionLocal() as db:
        user = await db.get(User, user_id)
        order = await db.get(Order, order_id)
        assert user is not None
        assert user.role == "deleted"
        assert user.is_active is False
        assert user.phone.startswith("deleted_")
        assert order is not None
        assert order.delivery_address_snapshot is None
        await db.delete(user)
        await db.commit()
    await engine.dispose()


def test_payment_is_bound_to_user_amount_and_consumed_exactly_once(monkeypatch):
    if not settings.dev_bypass_secret:
        return

    razorpay_order_id = f"order_test_{uuid.uuid4().hex}"
    razorpay_payment_id = f"pay_test_{uuid.uuid4().hex}"

    def fake_create(amount):
        return {
            "razorpay_order_id": razorpay_order_id,
            "order_id": razorpay_order_id,
            "amount": float(amount),
            "currency": "INR",
        }

    captured_amount = 0

    def fake_fetch(payment_id):
        return {
            "id": payment_id,
            "order_id": razorpay_order_id,
            "amount": captured_amount,
            "status": "captured",
        }

    monkeypatch.setattr(payments, "create_razorpay_order", fake_create)
    monkeypatch.setattr(payments, "fetch_razorpay_payment", fake_fetch)
    deleted_prefixes = []
    monkeypatch.setattr(auth, "delete_prefixes", deleted_prefixes.extend)

    with TestClient(app) as client:
        phone = f"+918{uuid.uuid4().int % 10**9:09d}"
        login = client.post(
            "/auth/dev-login",
            json={"phone": phone, "secret": settings.dev_bypass_secret},
        )
        assert login.status_code == 200
        headers = {"Authorization": f"Bearer {login.json()['dev_token']}"}
        user_id = login.json()["user"]["id"]

        product = next(
            item
            for item in client.get("/products?limit=100").json()["items"]
            if item["sizes"]
        )
        size = product["sizes"][0]
        amount = float(size["price"])
        captured_amount = round(amount * 100)

        address = client.post(
            "/addresses",
            headers=headers,
            json={
                "full_address": "42 Payment Integrity Road",
                "city": "Bengaluru",
                "pincode": "560001",
                "is_default": True,
            },
        )
        assert address.status_code == 201

        tampered_create = client.post(
            "/payments/razorpay/order",
            headers=headers,
            json={"amount": amount},
        )
        assert tampered_create.status_code == 422

        created = client.post(
            "/payments/razorpay/order",
            headers=headers,
            json={
                "items": [
                    {
                        "product_id": product["id"],
                        "qty": 1,
                        "size": size["label"],
                    }
                ],
                "address_id": address.json()["id"],
                "delivery_type": "free",
            },
        )
        assert created.status_code == 200

        invalid_signature = client.post(
            "/payments/razorpay/verify",
            headers=headers,
            json={
                "razorpay_order_id": razorpay_order_id,
                "razorpay_payment_id": razorpay_payment_id,
                "razorpay_signature": "invalid",
            },
        )
        assert invalid_signature.status_code == 400

        signature = _signature(razorpay_order_id, razorpay_payment_id)
        verified = client.post(
            "/payments/razorpay/verify",
            headers=headers,
            json={
                "razorpay_order_id": razorpay_order_id,
                "razorpay_payment_id": razorpay_payment_id,
                "razorpay_signature": signature,
            },
        )
        assert verified.status_code == 200

        payload = {
            "items": [
                {
                    "product_id": product["id"],
                    "qty": 1,
                    "size": size["label"],
                    "price": 0,
                }
            ],
            "address_id": address.json()["id"],
            "delivery_type": "free",
            "razorpay_order_id": razorpay_order_id,
            "razorpay_payment_id": razorpay_payment_id,
            "razorpay_signature": signature,
        }
        first_order = client.post("/orders", headers=headers, json=payload)
        assert first_order.status_code == 201

        replay = client.post("/orders", headers=headers, json=payload)
        assert replay.status_code == 201
        assert replay.json()["id"] == first_order.json()["id"]

        repeated_verification = client.post(
            "/payments/razorpay/verify",
            headers=headers,
            json={
                "razorpay_order_id": razorpay_order_id,
                "razorpay_payment_id": razorpay_payment_id,
                "razorpay_signature": signature,
            },
        )
        assert repeated_verification.status_code == 200
        assert repeated_verification.json()["order_id"] == first_order.json()["id"]
        assert len(client.get("/orders/me", headers=headers).json()) == 1

        assert client.delete("/auth/me", headers=headers).status_code == 409

    order_id = first_order.json()["id"]
    asyncio.run(_mark_delivered(order_id))
    with TestClient(app) as client:
        assert client.delete("/auth/me", headers=headers).status_code == 204
    assert f"customizations/{user_id}/" in deleted_prefixes
    assert f"ai-edits/{user_id}/" in deleted_prefixes
    assert f"delivery-proofs/{order_id}/" in deleted_prefixes
    asyncio.run(_verify_anonymized_and_cleanup(user_id, order_id))
