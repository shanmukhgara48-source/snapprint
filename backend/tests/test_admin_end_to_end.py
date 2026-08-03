import asyncio
import uuid

from fastapi.testclient import TestClient
from sqlalchemy import delete

from app.database import AsyncSessionLocal, engine
from app.models import (
    AdminAuditLog,
    AdminLoginHistory,
    AdminUser,
    AppSetting,
    Banner,
    Category,
    Coupon,
    Product,
)
from app.services.password import hash_password
from main import app


async def _create_test_admins(prefix: str, password: str) -> list[AdminUser]:
    admins = [
        AdminUser(
            username=f"{prefix}_super",
            password_hash=hash_password(password),
            role="super_admin",
        ),
        AdminUser(
            username=f"{prefix}_support",
            password_hash=hash_password(password),
            role="support_staff",
        ),
    ]
    async with AsyncSessionLocal() as db:
        db.add_all(admins)
        await db.commit()
        for admin in admins:
            await db.refresh(admin)
    await engine.dispose()
    return admins


async def _cleanup_test_data(prefix: str, admin_ids: list[str]) -> None:
    async with AsyncSessionLocal() as db:
        await db.execute(
            delete(AdminAuditLog).where(AdminAuditLog.admin_user_id.in_(admin_ids))
        )
        await db.execute(
            delete(AdminLoginHistory).where(
                AdminLoginHistory.username_attempted.like(f"{prefix}%")
            )
        )
        await db.execute(delete(Product).where(Product.name.like(f"{prefix}%")))
        await db.execute(delete(Category).where(Category.name.like(f"{prefix}%")))
        await db.execute(delete(Banner).where(Banner.title.like(f"{prefix}%")))
        await db.execute(delete(Coupon).where(Coupon.code.like(f"{prefix.upper()}%")))
        await db.execute(delete(AppSetting).where(AppSetting.key == f"{prefix}_setting"))
        await db.execute(delete(AdminUser).where(AdminUser.id.in_(admin_ids)))
        await db.commit()
    await engine.dispose()


def _login(client: TestClient, username: str, password: str) -> dict[str, str]:
    response = client.post(
        "/auth/admin/login",
        json={"username": username, "password": password},
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def test_admin_auth_rbac_crud_and_public_catalog_synchronization():
    prefix = f"qa_{uuid.uuid4().hex[:8]}"
    password = f"Release-{uuid.uuid4().hex}!"
    admins = asyncio.run(_create_test_admins(prefix, password))
    admin_ids = [admin.id for admin in admins]

    try:
        with TestClient(app) as client:
            wrong = client.post(
                "/auth/admin/login",
                json={"username": admins[0].username, "password": "wrong"},
            )
            assert wrong.status_code == 401

            super_headers = _login(client, admins[0].username, password)
            support_headers = _login(client, admins[1].username, password)

            assert client.get("/admin/products").status_code == 401
            assert client.get("/admin/products", headers=support_headers).status_code == 200
            forbidden = client.post(
                "/admin/categories",
                headers=support_headers,
                json={"name": f"{prefix}_forbidden"},
            )
            assert forbidden.status_code == 403
            assert client.put(
                "/admin/delivery-settings/free",
                headers=support_headers,
                json={"price": 0},
            ).status_code == 403

            corrupt_upload = client.post(
                "/admin/upload",
                headers=super_headers,
                files={"file": ("fake.png", b"not-an-image", "image/png")},
            )
            assert corrupt_upload.status_code == 400

            read_paths = [
                "/admin/categories",
                "/admin/banners",
                "/admin/products",
                "/admin/orders",
                "/admin/orders/export",
                "/admin/users",
                "/admin/delivery-partners",
                "/admin/coupons",
                "/admin/delivery-settings",
                "/admin/payments",
                "/admin/settings",
                "/admin/notifications/history",
                "/admin/audit-logs",
                "/admin/login-history",
                "/admin/admins",
                "/admin/analytics/dashboard",
                "/admin/analytics/charts",
            ]
            for path in read_paths:
                response = client.get(path, headers=super_headers)
                assert response.status_code == 200, (path, response.text)

            category_response = client.post(
                "/admin/categories",
                headers=super_headers,
                json={"name": f"{prefix}_category", "icon": "photo", "sort_order": 999},
            )
            assert category_response.status_code == 201
            category = category_response.json()
            assert any(
                item["id"] == category["id"] for item in client.get("/categories").json()
            )

            product_response = client.post(
                "/admin/products",
                headers=super_headers,
                json={
                    "name": f"{prefix}_product",
                    "category": category["name"],
                    "category_id": category["id"],
                    "base_price": 25,
                    "sizes": [{"label": "4x6", "price": 25}],
                    "images": ["https://images.unsplash.com/photo-1542038784456-1ea8e935640e"],
                    "stock_quantity": 3,
                    "tracks_inventory": True,
                },
            )
            assert product_response.status_code == 201
            product = product_response.json()
            public_product = client.get(f"/products/{product['id']}")
            assert public_product.status_code == 200
            assert public_product.json()["base_price"] == 25
            assert public_product.json()["tracks_inventory"] is True

            mismatched_category = client.put(
                f"/admin/products/{product['id']}",
                headers=super_headers,
                json={"category": category["name"], "category_id": "missing"},
            )
            assert mismatched_category.status_code == 422

            unsellable_bulk = client.post(
                "/admin/products/bulk-update",
                headers=super_headers,
                json={
                    "ids": [product["id"]],
                    "update": {"base_price": 0, "sizes": []},
                },
            )
            assert unsellable_bulk.status_code == 422

            updated_product = client.put(
                f"/admin/products/{product['id']}",
                headers=super_headers,
                json={"base_price": 29, "is_featured": True},
            )
            assert updated_product.status_code == 200
            assert client.get(f"/products/{product['id']}").json()["base_price"] == 29

            banner_response = client.post(
                "/admin/banners",
                headers=super_headers,
                json={
                    "title": f"{prefix}_banner",
                    "image_url": "https://images.unsplash.com/photo-1542038784456-1ea8e935640e",
                    "sort_order": 999,
                    "starts_at": "2020-01-01T00:00:00Z",
                    "ends_at": "2100-01-02T00:00:00Z",
                },
            )
            assert banner_response.status_code == 201
            banner = banner_response.json()
            assert any(item["id"] == banner["id"] for item in client.get("/banners").json())
            invalid_banner_schedule = client.put(
                f"/admin/banners/{banner['id']}",
                headers=super_headers,
                json={"starts_at": "2200-01-03T00:00:00Z"},
            )
            assert invalid_banner_schedule.status_code == 422

            coupon_response = client.post(
                "/admin/coupons",
                headers=super_headers,
                json={
                    "code": f"{prefix}_coupon",
                    "discount_type": "percent",
                    "value": 10,
                    "min_order": 0,
                    "max_uses": 5,
                },
            )
            assert coupon_response.status_code == 201
            coupon = coupon_response.json()
            assert any(
                item["code"] == coupon["code"]
                for item in client.get("/coupons/active").json()
            )

            setting_key = f"{prefix}_setting"
            setting_response = client.put(
                f"/admin/settings/{setting_key}",
                headers=super_headers,
                json={"value": {"enabled": True}},
            )
            assert setting_response.status_code == 200
            assert setting_response.json()["value"] == {"enabled": True}

            assert client.delete(
                f"/admin/coupons/{coupon['id']}", headers=super_headers
            ).status_code == 204
            assert client.delete(
                f"/admin/banners/{banner['id']}", headers=super_headers
            ).status_code == 204
            assert client.delete(
                f"/admin/products/{product['id']}", headers=super_headers
            ).status_code == 204
            assert client.delete(
                f"/admin/categories/{category['id']}", headers=super_headers
            ).status_code == 204

            assert client.get(f"/products/{product['id']}").status_code == 404
            assert not any(
                item["id"] == category["id"] for item in client.get("/categories").json()
            )
    finally:
        asyncio.run(_cleanup_test_data(prefix, admin_ids))
