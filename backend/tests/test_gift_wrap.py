"""Gift-wrap regression tests: server-side fee, payment binding, storage."""

import asyncio
import hashlib
import hmac
import uuid

from fastapi.testclient import TestClient
from sqlalchemy import delete, select

from app.config import settings
from app.database import AsyncSessionLocal, engine
from app.models import (
    Address,
    Category,
    Coupon,
    DeliveryTracking,
    Order,
    OrderItem,
    Product,
    User,
)
from app.models.app_setting import AppSetting
from app.routers import payments
from app.routers.auth import _create_app_access_token
from main import app

PREFIX = f"test_gift_{uuid.uuid4().hex[:8]}"


def _signature(order_id: str, payment_id: str) -> str:
    return hmac.new(
        settings.razorpay_key_secret.encode(),
        f"{order_id}|{payment_id}".encode(),
        hashlib.sha256,
    ).hexdigest()


async def _setup():
    async with AsyncSessionLocal() as db:
        cat = Category(id=f"{PREFIX}_cat", name=f"{PREFIX} Cat", icon="photo")
        db.add(cat)
        await db.flush()
        product = Product(
            id=f"{PREFIX}_p", name=f"{PREFIX} Prod", category=cat.name,
            category_id=cat.id, base_price=100.0,
            sizes=[{"label": "4x6", "price": 100.0}], images=[],
            stock_quantity=10, tracks_inventory=True,
            is_orderable=True, is_active=True,
        )
        user = User(firebase_uid=f"dev_{PREFIX}",
                    phone=f"+915{uuid.uuid4().int % 10**9:09d}", role="customer")
        db.add_all([product, user])
        await db.commit()
        for o in (product, user, cat):
            await db.refresh(o)
        out = (product, user, cat)
    await engine.dispose()
    return out


async def _wipe(ids):
    product, user, cat = ids
    async with AsyncSessionLocal() as db:
        oids = [o.id for o in (await db.execute(
            select(Order).where(Order.user_id == user.id))).scalars().all()]
        if oids:
            await db.execute(
                delete(DeliveryTracking).where(DeliveryTracking.order_id.in_(oids)))
            await db.execute(
                delete(OrderItem).where(OrderItem.order_id.in_(oids)))
            await db.execute(delete(Order).where(Order.id.in_(oids)))
        await db.execute(delete(Address).where(Address.user_id == user.id))
        await db.execute(delete(User).where(User.id == user.id))
        await db.execute(delete(Product).where(Product.id == product.id))
        await db.execute(delete(Category).where(Category.id == cat.id))
        await db.commit()
    await engine.dispose()


def test_gift_wrap_fee_is_server_side_and_paid():
    product, user, cat = asyncio.run(_setup())
    uh = {"Authorization": f"Bearer {_create_app_access_token(user)}"}

    razorpay_order_id = f"order_test_{uuid.uuid4().hex}"
    razorpay_payment_id = f"pay_test_{uuid.uuid4().hex}"
    captured = {"amount": 0}

    def fake_create(amount):
        return {
            "razorpay_order_id": razorpay_order_id,
            "order_id": razorpay_order_id,
            "amount": float(amount),
            "currency": "INR",
        }

    def fake_fetch(payment_id):
        return {
            "id": payment_id,
            "order_id": razorpay_order_id,
            "amount": captured["amount"],
            "status": "captured",
        }

    payments_create = payments.create_razorpay_order
    payments_fetch = payments.fetch_razorpay_payment
    payments.create_razorpay_order = fake_create
    payments.fetch_razorpay_payment = fake_fetch
    try:
        with TestClient(app) as client:
            address = client.post("/addresses", headers=uh, json={
                "full_address": "1 Gift Road", "city": "Bengaluru",
                "pincode": "560001", "is_default": True})
            assert address.status_code == 201
            address_id = address.json()["id"]
            item = {"product_id": product.id, "qty": 1, "size": "4x6"}

            # Quote without gift has no charge.
            plain = client.post("/cart/calculate", headers=uh, json={
                "items": [item], "delivery_type": "free"})
            assert plain.status_code == 200
            assert plain.json()["gift_wrap_charge"] == 0

            # Quote with gift adds the server-side fee (default 49).
            quoted = client.post("/cart/calculate", headers=uh, json={
                "items": [item], "delivery_type": "free", "gift_wrap": True})
            assert quoted.status_code == 200
            assert quoted.json()["gift_wrap_charge"] == 49.0
            assert quoted.json()["total"] == 149.0
            captured["amount"] = 14900

            # Razorpay order carries the gift total.
            created = client.post("/payments/razorpay/order", headers=uh, json={
                "items": [item], "address_id": address_id,
                "delivery_type": "free", "gift_wrap": True})
            assert created.status_code == 200

            signature = _signature(razorpay_order_id, razorpay_payment_id)
            verified = client.post("/payments/razorpay/verify", headers=uh, json={
                "razorpay_order_id": razorpay_order_id,
                "razorpay_payment_id": razorpay_payment_id,
                "razorpay_signature": signature,
            })
            assert verified.status_code == 200

            # A client-supplied fee is ignored; the server fee wins.
            placed = client.post("/orders", headers=uh, json={
                "items": [{**item, "price": 0}],
                "address_id": address_id,
                "delivery_type": "free",
                "razorpay_order_id": razorpay_order_id,
                "razorpay_payment_id": razorpay_payment_id,
                "razorpay_signature": signature,
                "gift_wrap": True,
                "gift_message": "Happy birthday!",
            })
            assert placed.status_code == 201
            body = placed.json()
            assert body["gift_wrap"] is True
            assert body["gift_wrap_charge"] == 49.0
            assert body["gift_message"] == "Happy birthday!"
            assert body["total_price"] == 149.0

            fetched = client.get(f"/orders/{body['id']}", headers=uh).json()
            assert fetched["gift_wrap"] is True
            assert fetched["gift_message"] == "Happy birthday!"

        # Gift wrap can be disabled server-side (400, not silent ignore).
        asyncio.run(_disable_gift_wrap())
        try:
            with TestClient(app) as client:
                blocked = client.post("/cart/calculate", headers=uh, json={
                    "items": [item], "delivery_type": "free", "gift_wrap": True})
                assert blocked.status_code == 400
        finally:
            asyncio.run(_enable_gift_wrap())
    finally:
        payments.create_razorpay_order = payments_create
        payments.fetch_razorpay_payment = payments_fetch
        asyncio.run(_wipe((product, user, cat)))


async def _disable_gift_wrap():
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(AppSetting).where(AppSetting.key == "gift_wrap"))
        setting = result.scalar_one_or_none()
        if setting is None:
            db.add(AppSetting(key="gift_wrap", value={"price": 49.0, "enabled": False}))
        else:
            setting.value = {"price": 49.0, "enabled": False}
        await db.commit()
    await engine.dispose()


async def _enable_gift_wrap():
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(AppSetting).where(AppSetting.key == "gift_wrap"))
        setting = result.scalar_one_or_none()
        if setting is None:
            db.add(AppSetting(key="gift_wrap", value={"price": 49.0, "enabled": True}))
        else:
            setting.value = {"price": 49.0, "enabled": True}
        await db.commit()
    await engine.dispose()
