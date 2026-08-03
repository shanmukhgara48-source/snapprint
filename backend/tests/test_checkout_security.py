import uuid

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from app.config import settings
from app.schemas.cart import CartCalculateRequest
from app.schemas.order import OrderCreate
from main import app


def test_checkout_schemas_reject_empty_orders_and_nonpositive_quantities():
    with pytest.raises(ValidationError):
        CartCalculateRequest(
            items=[{"product_id": "product", "qty": 0}],
        )
    with pytest.raises(ValidationError):
        OrderCreate(items=[], address_id="address")
    with pytest.raises(ValidationError):
        OrderCreate(
            items=[{"product_id": "product", "qty": -2, "price": 1}],
            address_id="address",
        )


def test_live_checkout_rejects_price_bypass_inputs_and_rolls_back_stock():
    if not settings.dev_bypass_secret:
        pytest.skip("DEV_BYPASS_SECRET is required for the authenticated API test")

    with TestClient(app) as client:
        phone = f"+919{uuid.uuid4().int % 10**9:09d}"
        login = client.post(
            "/auth/dev-login",
            json={"phone": phone, "secret": settings.dev_bypass_secret},
        )
        assert login.status_code == 200
        headers = {"Authorization": f"Bearer {login.json()['dev_token']}"}

        catalog = client.get("/products?limit=100")
        assert catalog.status_code == 200
        products = catalog.json()["items"]
        product = next(item for item in products if item["sizes"])
        size = product["sizes"][0]["label"]

        address_response = client.post(
            "/addresses",
            headers=headers,
            json={
                "full_address": "1 Release Test Road",
                "city": "Bengaluru",
                "pincode": "560001",
                "is_default": True,
            },
        )
        assert address_response.status_code == 201
        address_id = address_response.json()["id"]

        invalid_delivery = client.post(
            "/cart/calculate",
            headers=headers,
            json={
                "items": [{"product_id": product["id"], "qty": 1, "size": size}],
                "delivery_type": "attacker-free",
            },
        )
        assert invalid_delivery.status_code == 400

        invalid_size = client.post(
            "/cart/calculate",
            headers=headers,
            json={
                "items": [
                    {"product_id": product["id"], "qty": 1, "size": "invalid"}
                ],
                "delivery_type": "free",
            },
        )
        assert invalid_size.status_code == 400

        order_payload = {
            "items": [
                {
                    "product_id": product["id"],
                    "qty": 1,
                    "size": size,
                    "price": 0,
                }
            ],
            "address_id": address_id,
            "delivery_type": "free",
        }
        stock_before = product["stock_quantity"]
        foreign_artwork = client.post(
            "/orders",
            headers=headers,
            json={
                **order_payload,
                "items": [
                    {
                        **order_payload["items"][0],
                        "image_url": "https://attacker.example/customer-photo.png",
                    }
                ],
            },
        )
        assert foreign_artwork.status_code == 403

        unpaid = client.post("/orders", headers=headers, json=order_payload)
        assert unpaid.status_code == 402

        refreshed = client.get(f"/products/{product['id']}")
        assert refreshed.status_code == 200
        assert refreshed.json()["stock_quantity"] == stock_before

        invalid_order_delivery = client.post(
            "/orders",
            headers=headers,
            json={**order_payload, "delivery_type": "attacker-free"},
        )
        assert invalid_order_delivery.status_code == 400

        invalid_order_size = client.post(
            "/orders",
            headers=headers,
            json={
                **order_payload,
                "items": [
                    {
                        "product_id": product["id"],
                        "qty": 1,
                        "size": "invalid",
                        "price": 0,
                    }
                ],
            },
        )
        assert invalid_order_size.status_code == 400

        cleanup = client.delete("/auth/me", headers=headers)
        assert cleanup.status_code == 204
