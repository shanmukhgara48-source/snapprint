import asyncio
import uuid

from fastapi.testclient import TestClient
from sqlalchemy import delete, select

from app.database import AsyncSessionLocal, engine
from app.models import (
    Address,
    AdminAuditLog,
    AdminLoginHistory,
    AdminUser,
    Coupon,
    DeliveryTracking,
    Order,
    OrderItem,
    Product,
    User,
)
from app.routers import admin
from app.services.password import hash_password
from main import app


async def _create_fixture(prefix: str, password: str) -> dict[str, str]:
    async with AsyncSessionLocal() as db:
        customer = User(
            firebase_uid=f"dev_{prefix}",
            phone=f"+917{uuid.uuid4().int % 10**9:09d}",
            role="customer",
        )
        manager = AdminUser(
            username=f"{prefix}_manager",
            password_hash=hash_password(password),
            role="manager",
        )
        support = AdminUser(
            username=f"{prefix}_support",
            password_hash=hash_password(password),
            role="support_staff",
        )
        product = Product(
            name=f"{prefix}_product",
            category="photo_prints",
            base_price=50,
            sizes=[],
            images=[],
            stock_quantity=1,
            tracks_inventory=True,
        )
        coupon = Coupon(
            code=f"{prefix.upper()}_10",
            discount_type="flat",
            value=10,
            min_order=0,
            max_uses=10,
            used_count=1,
        )
        db.add_all([customer, manager, support, product, coupon])
        await db.flush()
        address = Address(
            user_id=customer.id,
            full_address="1 Refund Road",
            city="Mumbai",
            pincode="400001",
        )
        db.add(address)
        await db.flush()
        order = Order(
            user_id=customer.id,
            address_id=address.id,
            delivery_address_snapshot=address.full_address,
            delivery_city_snapshot=address.city,
            delivery_pincode_snapshot=address.pincode,
            status="confirmed",
            total_price=90,
            delivery_type="free",
            delivery_charge=0,
            discount=10,
            coupon_code=coupon.code,
            razorpay_order_id=f"order_{prefix}",
            razorpay_payment_id=f"pay_{prefix}",
        )
        db.add(order)
        await db.flush()
        db.add_all([
            OrderItem(
                order_id=order.id,
                product_id=product.id,
                quantity=2,
                selected_size="default",
                unit_price=50,
            ),
            DeliveryTracking(order_id=order.id, status="confirmed"),
        ])
        await db.commit()
        ids = {
            "order_id": order.id,
            "product_id": product.id,
            "coupon_id": coupon.id,
            "customer_id": customer.id,
            "manager_id": manager.id,
            "manager_username": manager.username,
            "support_id": support.id,
            "support_username": support.username,
            "address_id": address.id,
        }
    await engine.dispose()
    return ids


async def _cleanup_fixture(ids: dict[str, str]) -> None:
    async with AsyncSessionLocal() as db:
        await db.execute(delete(AdminAuditLog).where(AdminAuditLog.admin_user_id.in_([ids["manager_id"], ids["support_id"]])))
        await db.execute(delete(AdminLoginHistory).where(AdminLoginHistory.username_attempted.in_([ids["manager_username"], ids["support_username"]])))
        await db.execute(delete(DeliveryTracking).where(DeliveryTracking.order_id == ids["order_id"]))
        await db.execute(delete(OrderItem).where(OrderItem.order_id == ids["order_id"]))
        await db.execute(delete(Order).where(Order.id == ids["order_id"]))
        await db.execute(delete(Address).where(Address.id == ids["address_id"]))
        await db.execute(delete(Coupon).where(Coupon.id == ids["coupon_id"]))
        await db.execute(delete(Product).where(Product.id == ids["product_id"]))
        await db.execute(delete(User).where(User.id == ids["customer_id"]))
        await db.execute(delete(AdminUser).where(AdminUser.id.in_([ids["manager_id"], ids["support_id"]])))
        await db.commit()
    await engine.dispose()


def _login(client: TestClient, username: str, password: str) -> dict[str, str]:
    response = client.post(
        "/auth/admin/login",
        json={"username": username, "password": password},
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def test_paid_cancellation_refunds_and_restores_inventory_once(monkeypatch):
    prefix = f"cancel_{uuid.uuid4().hex[:8]}"
    password = f"Release-{uuid.uuid4().hex}!"
    ids = asyncio.run(_create_fixture(prefix, password))
    refund_calls = []

    def fake_refund(payment_id, amount_paise, *, receipt):
        refund_calls.append((payment_id, amount_paise, receipt))
        return {"id": f"rfnd_{prefix}", "status": "processed", "amount": amount_paise}

    monkeypatch.setattr(admin, "refund_razorpay_payment", fake_refund)
    try:
        with TestClient(app) as client:
            manager_headers = _login(client, ids["manager_username"], password)
            support_headers = _login(client, ids["support_username"], password)
            assert client.patch(
                f"/admin/orders/{ids['order_id']}",
                headers=support_headers,
                json={"status": "cancelled"},
            ).status_code == 403
            assert client.patch(
                f"/admin/orders/{ids['order_id']}",
                headers=support_headers,
                json={"notes": "Customer called support"},
            ).status_code == 200

            cancelled = client.patch(
                f"/admin/orders/{ids['order_id']}",
                headers=manager_headers,
                json={"status": "cancelled"},
            )
            assert cancelled.status_code == 200
            repeated = client.patch(
                f"/admin/orders/{ids['order_id']}",
                headers=manager_headers,
                json={"status": "cancelled"},
            )
            assert repeated.status_code == 200
            assert len(refund_calls) == 1
            terminal_assignment = client.post(
                f"/admin/orders/{ids['order_id']}/assign",
                headers=manager_headers,
                json={"delivery_partner_id": "unused"},
            )
            assert terminal_assignment.status_code == 409

        async def verify():
            async with AsyncSessionLocal() as db:
                order = await db.get(Order, ids["order_id"])
                product = await db.get(Product, ids["product_id"])
                coupon = await db.get(Coupon, ids["coupon_id"])
                assert order.status == "cancelled"
                assert order.refund_status == "processed"
                assert order.razorpay_refund_id == f"rfnd_{prefix}"
                assert product.stock_quantity == 3
                assert coupon.used_count == 0
            await engine.dispose()

        asyncio.run(verify())
    finally:
        asyncio.run(_cleanup_fixture(ids))


def test_failed_refund_leaves_order_inventory_and_coupon_unchanged(monkeypatch):
    prefix = f"cancel_fail_{uuid.uuid4().hex[:8]}"
    password = f"Release-{uuid.uuid4().hex}!"
    ids = asyncio.run(_create_fixture(prefix, password))

    def fail_refund(*args, **kwargs):
        raise RuntimeError("provider unavailable")

    monkeypatch.setattr(admin, "refund_razorpay_payment", fail_refund)
    try:
        with TestClient(app) as client:
            manager_headers = _login(client, ids["manager_username"], password)
            response = client.patch(
                f"/admin/orders/{ids['order_id']}",
                headers=manager_headers,
                json={"status": "cancelled"},
            )
            assert response.status_code == 502

        async def verify():
            async with AsyncSessionLocal() as db:
                order = await db.get(Order, ids["order_id"])
                product = await db.get(Product, ids["product_id"])
                coupon = await db.get(Coupon, ids["coupon_id"])
                assert order.status == "confirmed"
                assert order.refund_status is None
                assert product.stock_quantity == 1
                assert coupon.used_count == 1
            await engine.dispose()

        asyncio.run(verify())
    finally:
        asyncio.run(_cleanup_fixture(ids))
