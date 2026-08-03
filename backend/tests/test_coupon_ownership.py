import asyncio
import uuid

from fastapi.testclient import TestClient

from app.database import AsyncSessionLocal, engine
from app.models import Coupon, User
from app.routers.auth import _create_app_access_token
from main import app


async def _create_users_and_reward() -> tuple[User, User, Coupon]:
    suffix = uuid.uuid4().hex
    async with AsyncSessionLocal() as db:
        owner = User(
            firebase_uid=f"dev_coupon_owner_{suffix}",
            phone=f"+915{uuid.uuid4().int % 10**9:09d}",
            role="customer",
        )
        stranger = User(
            firebase_uid=f"dev_coupon_stranger_{suffix}",
            phone=f"+914{uuid.uuid4().int % 10**9:09d}",
            role="customer",
        )
        db.add_all([owner, stranger])
        await db.flush()
        reward = Coupon(
            code=f"WELCOME{suffix[:10].upper()}",
            owner_user_id=owner.id,
            discount_type="flat",
            value=1_000_000,
            min_order=0,
            max_uses=1,
            is_active=True,
        )
        db.add(reward)
        await db.commit()
        for item in (owner, stranger, reward):
            await db.refresh(item)
        result = owner, stranger, reward
    await engine.dispose()
    return result


async def _cleanup_users(user_ids: list[str]) -> None:
    async with AsyncSessionLocal() as db:
        for user_id in user_ids:
            user = await db.get(User, user_id)
            if user is not None:
                await db.delete(user)
        await db.commit()
    await engine.dispose()


def test_private_reward_is_hidden_owner_bound_and_supports_free_checkout():
    owner, stranger, reward = asyncio.run(_create_users_and_reward())
    owner_headers = {"Authorization": f"Bearer {_create_app_access_token(owner)}"}
    stranger_headers = {
        "Authorization": f"Bearer {_create_app_access_token(stranger)}"
    }

    with TestClient(app) as client:
        offers = client.get("/coupons/active")
        assert offers.status_code == 200
        assert reward.code not in {item["code"] for item in offers.json()}

        stranger_validation = client.post(
            "/coupons/validate",
            headers=stranger_headers,
            json={"code": reward.code, "subtotal": 100},
        )
        assert stranger_validation.status_code == 200
        assert stranger_validation.json()["valid"] is False

        owner_validation = client.post(
            "/coupons/validate",
            headers=owner_headers,
            json={"code": reward.code, "subtotal": 100},
        )
        assert owner_validation.status_code == 200
        assert owner_validation.json()["valid"] is True

        product = next(
            item
            for item in client.get("/products?limit=100").json()["items"]
            if item["sizes"]
        )
        size = product["sizes"][0]
        stranger_cart = client.post(
            "/cart/calculate",
            headers=stranger_headers,
            json={
                "items": [
                    {
                        "product_id": product["id"],
                        "qty": 1,
                        "size": size["label"],
                    }
                ],
                "delivery_type": "free",
                "coupon_code": reward.code,
            },
        )
        assert stranger_cart.status_code == 200
        assert stranger_cart.json()["coupon_applied"] is False

        address = client.post(
            "/addresses",
            headers=owner_headers,
            json={
                "full_address": "1 Private Reward Road",
                "city": "Bengaluru",
                "pincode": "560001",
                "is_default": True,
            },
        )
        assert address.status_code == 201
        invalid_address = client.post(
            "/addresses",
            headers=owner_headers,
            json={
                "full_address": "Too short",
                "city": "X",
                "pincode": "00000A",
            },
        )
        assert invalid_address.status_code == 422
        free_order = client.post(
            "/orders",
            headers=owner_headers,
            json={
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
                "coupon_code": reward.code,
            },
        )
        assert free_order.status_code == 201
        assert free_order.json()["total_price"] == 0

        changed = client.put(
            f"/addresses/{address.json()['id']}",
            headers=owner_headers,
            json={
                "full_address": "99 Newly Edited Address",
                "city": "Mumbai",
                "pincode": "400001",
                "is_default": True,
            },
        )
        assert changed.status_code == 200
        order_after_edit = client.get(
            f"/orders/{free_order.json()['id']}",
            headers=owner_headers,
        )
        assert "1 Private Reward Road" in order_after_edit.json()["delivery_address"]
        assert "99 Newly Edited Address" not in order_after_edit.json()["delivery_address"]

        deleted_address = client.delete(
            f"/addresses/{address.json()['id']}",
            headers=owner_headers,
        )
        assert deleted_address.status_code == 204
        order_after_delete = client.get(
            f"/orders/{free_order.json()['id']}",
            headers=owner_headers,
        )
        assert "1 Private Reward Road" in order_after_delete.json()["delivery_address"]

        assert client.delete("/auth/me", headers=owner_headers).status_code == 409
        assert client.delete("/auth/me", headers=stranger_headers).status_code == 204

    asyncio.run(_cleanup_users([owner.id, stranger.id]))
