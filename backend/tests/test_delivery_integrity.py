import asyncio
import io
import uuid

from fastapi.testclient import TestClient
from PIL import Image
from sqlalchemy import delete

from app.database import AsyncSessionLocal, engine
from app.models import Address, DeliveryTracking, Order, User
from app.routers import delivery
from app.routers.auth import _create_app_access_token
from app.services.order_status import validate_order_status_transition
from main import app


class _FakeR2:
    def __init__(self):
        self.objects: dict[str, dict] = {}

    def upload_fileobj(self, fileobj, bucket, key, ExtraArgs=None):
        self.objects[key] = {
            "Body": fileobj.read(),
            "ContentType": ExtraArgs["ContentType"],
        }

    def head_object(self, *, Bucket, Key):
        stored = self.objects[Key]
        return {
            "ContentType": stored["ContentType"],
            "ContentLength": len(stored["Body"]),
        }


def _png_bytes() -> bytes:
    output = io.BytesIO()
    Image.new("RGB", (160, 120), (80, 120, 40)).save(output, format="PNG")
    return output.getvalue()


async def _create_delivery_order(prefix: str) -> tuple[User, User, Order]:
    async with AsyncSessionLocal() as db:
        customer = User(
            firebase_uid=f"{prefix}_customer",
            phone=f"+917{uuid.uuid4().int % 10**9:09d}",
            role="customer",
        )
        partner = User(
            firebase_uid=f"{prefix}_partner",
            phone=f"+916{uuid.uuid4().int % 10**9:09d}",
            role="delivery",
        )
        db.add_all([customer, partner])
        await db.flush()
        address = Address(
            user_id=customer.id,
            full_address="7 Delivery Integrity Road",
            city="Bengaluru",
            pincode="560001",
            is_default=True,
        )
        db.add(address)
        await db.flush()
        order = Order(
            user_id=customer.id,
            address_id=address.id,
            delivery_partner_id=partner.id,
            status="confirmed",
            total_price=100,
            delivery_type="free",
            delivery_charge=0,
            discount=0,
        )
        db.add(order)
        await db.flush()
        db.add(DeliveryTracking(order_id=order.id, status="confirmed"))
        await db.commit()
        for item in (customer, partner, order):
            await db.refresh(item)
        result = customer, partner, order
    await engine.dispose()
    return result


async def _cleanup_delivery_order(customer_id: str, partner_id: str, order_id: str):
    async with AsyncSessionLocal() as db:
        await db.execute(
            delete(DeliveryTracking).where(DeliveryTracking.order_id == order_id)
        )
        await db.execute(delete(Order).where(Order.id == order_id))
        await db.execute(delete(Address).where(Address.user_id == customer_id))
        await db.execute(delete(User).where(User.id.in_([customer_id, partner_id])))
        await db.commit()
    await engine.dispose()


def test_delivery_requires_ordered_transitions_and_real_photo_proof(monkeypatch):
    prefix = f"delivery_{uuid.uuid4().hex}"
    customer, partner, order = asyncio.run(_create_delivery_order(prefix))
    fake_r2 = _FakeR2()
    monkeypatch.setattr(delivery, "r2_client", lambda: fake_r2)
    customer_headers = {
        "Authorization": f"Bearer {_create_app_access_token(customer)}"
    }
    delivery_headers = {
        "Authorization": f"Bearer {_create_app_access_token(partner)}"
    }

    try:
        with TestClient(app) as client:
            assert client.get(
                "/delivery/assigned", headers=customer_headers
            ).status_code == 403
            assigned = client.get("/delivery/assigned", headers=delivery_headers)
            assert assigned.status_code == 200
            assert [item["id"] for item in assigned.json()] == [order.id]

            skipped = client.patch(
                f"/delivery/{order.id}/status",
                headers=delivery_headers,
                json={"status": "delivered", "proof_url": "otp:123456"},
            )
            assert skipped.status_code == 409

            picked_up = client.patch(
                f"/delivery/{order.id}/status",
                headers=delivery_headers,
                json={"status": "picked_up"},
            )
            assert picked_up.status_code == 200
            assert picked_up.json()["status"] == "picked_up"

            assert client.patch(
                f"/delivery/{order.id}/status",
                headers=delivery_headers,
                json={"status": "delivered", "proof_url": "otp:123456"},
            ).status_code == 409

            out_for_delivery = client.patch(
                f"/delivery/{order.id}/status",
                headers=delivery_headers,
                json={"status": "out_for_delivery"},
            )
            assert out_for_delivery.status_code == 200

            missing_proof = client.patch(
                f"/delivery/{order.id}/status",
                headers=delivery_headers,
                json={"status": "delivered"},
            )
            assert missing_proof.status_code == 400

            corrupt = client.post(
                f"/delivery/{order.id}/proof",
                headers=delivery_headers,
                files={"file": ("proof.png", b"corrupt", "image/png")},
            )
            assert corrupt.status_code == 400

            uploaded = client.post(
                f"/delivery/{order.id}/proof",
                headers=delivery_headers,
                files={"file": ("proof.png", _png_bytes(), "image/png")},
            )
            assert uploaded.status_code == 201
            proof_url = uploaded.json()["proof_url"]
            assert f"/media/delivery-proofs/{order.id}/" in proof_url
            assert "?sig=" in proof_url

            delivered = client.patch(
                f"/delivery/{order.id}/status",
                headers=delivery_headers,
                json={"status": "delivered", "proof_url": proof_url},
            )
            assert delivered.status_code == 200
            assert delivered.json()["status"] == "delivered"
            assert delivered.json()["proof_url"] == proof_url

            assert client.patch(
                f"/delivery/{order.id}/status",
                headers=delivery_headers,
                json={"status": "picked_up"},
            ).status_code == 409
    finally:
        asyncio.run(_cleanup_delivery_order(customer.id, partner.id, order.id))


def test_terminal_statuses_cannot_be_reopened():
    for current in ("delivered", "cancelled"):
        for target in ("confirmed", "picked_up", "out_for_delivery"):
            try:
                validate_order_status_transition(current, target)
            except Exception as exc:
                assert getattr(exc, "status_code", None) == 409
            else:
                raise AssertionError(f"Allowed invalid transition {current} -> {target}")
