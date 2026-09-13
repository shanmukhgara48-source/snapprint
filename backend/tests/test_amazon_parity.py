"""Amazon-parity regression tests: reviews, wishlist, returns, discovery."""

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
    Category,
    Coupon,
    DeliveryTracking,
    Order,
    OrderItem,
    Product,
    ReturnRequest,
    Review,
    ReviewVote,
    User,
    WishlistItem,
)
from app.routers.auth import _create_app_access_token
from app.services.password import hash_password
from main import app

PREFIX = f"test_amz_{uuid.uuid4().hex[:8]}"


async def _setup():
    async with AsyncSessionLocal() as db:
        cat = Category(id=f"{PREFIX}_cat", name=f"{PREFIX} Cat", icon="photo")
        db.add(cat)
        await db.flush()
        p1 = Product(
            id=f"{PREFIX}_p1", name=f"{PREFIX} Alpha", category=cat.name,
            category_id=cat.id, base_price=100.0,
            sizes=[{"label": "4x6", "price": 100.0}], images=[],
            stock_quantity=10, tracks_inventory=True,
            is_orderable=True, is_active=True,
            sku=f"{PREFIX}-A", compare_at_price=150.0, is_bestseller=True,
        )
        p2 = Product(
            id=f"{PREFIX}_p2", name=f"{PREFIX} Beta", category=cat.name,
            category_id=cat.id, base_price=200.0,
            sizes=[{"label": "4x6", "price": 200.0}], images=[],
            stock_quantity=10, tracks_inventory=True,
            is_orderable=True, is_active=True,
        )
        coup = Coupon(code=f"{PREFIX.upper()}100", discount_type="percent", value=100,
                      min_order=0, max_uses=100, is_active=True)
        user = User(firebase_uid=f"dev_{PREFIX}",
                    phone=f"+914{uuid.uuid4().int % 10**9:09d}", role="customer")
        admin = AdminUser(username=f"{PREFIX}_adm",
                          password_hash=hash_password("Pass-12345!x"),
                          role="super_admin")
        db.add_all([p1, p2, coup, user, admin])
        await db.commit()
        for o in (p1, p2, coup, user, admin, cat):
            await db.refresh(o)
        out = (p1, p2, coup, user, admin, cat)
    await engine.dispose()
    return out


async def _wipe(ids):
    p1, p2, coup, user, admin, cat = ids
    async with AsyncSessionLocal() as db:
        oids = [o.id for o in (await db.execute(
            select(Order).where(Order.user_id == user.id))).scalars().all()]
        if oids:
            await db.execute(
                delete(DeliveryTracking).where(DeliveryTracking.order_id.in_(oids)))
            await db.execute(
                delete(OrderItem).where(OrderItem.order_id.in_(oids)))
            await db.execute(
                delete(ReturnRequest).where(ReturnRequest.order_id.in_(oids)))
            await db.execute(delete(Order).where(Order.id.in_(oids)))
        await db.execute(delete(Address).where(Address.user_id == user.id))
        await db.execute(delete(ReviewVote).where(ReviewVote.user_id == user.id))
        await db.execute(delete(Review).where(Review.user_id == user.id))
        await db.execute(delete(WishlistItem).where(WishlistItem.user_id == user.id))
        await db.execute(delete(User).where(User.id == user.id))
        await db.execute(delete(Coupon).where(Coupon.code == coup.code))
        await db.execute(delete(Product).where(Product.id.in_([p1.id, p2.id])))
        await db.execute(delete(Category).where(Category.id == cat.id))
        await db.execute(
            delete(AdminAuditLog).where(AdminAuditLog.admin_user_id == admin.id))
        await db.execute(
            delete(AdminLoginHistory).where(AdminLoginHistory.admin_user_id == admin.id))
        row = await db.get(AdminUser, admin.id)
        if row:
            await db.delete(row)
        await db.commit()
    await engine.dispose()


def _user_headers(user):
    return {"Authorization": f"Bearer {_create_app_access_token(user)}"}


def test_reviews_wishlist_returns_and_discovery():
    p1, p2, coup, user, admin, cat = asyncio.run(_setup())
    uh = _user_headers(user)
    try:
        with TestClient(app) as client:
            # Discovery: suggest + empty batch ratings.
            suggest = client.get("/products/suggest", params={"q": PREFIX})
            assert suggest.status_code == 200
            assert {x["id"] for x in suggest.json()} == {p1.id, p2.id}
            assert client.get("/products/suggest", params={"q": "x"}).json() == []
            ratings = client.post(
                "/products/ratings", json={"ids": [p1.id, p2.id]}).json()
            assert ratings[p1.id] == {"avg": 0.0, "count": 0}

            # Free order containing both products (drives verified + bought-together).
            address = client.post("/addresses", headers=uh, json={
                "full_address": "1 Amz Road", "city": "Bengaluru",
                "pincode": "560001", "is_default": True})
            assert address.status_code == 201
            order = client.post("/orders", headers=uh, json={
                "items": [
                    {"product_id": p1.id, "qty": 1, "size": "4x6", "price": 0},
                    {"product_id": p2.id, "qty": 1, "size": "4x6", "price": 0},
                ],
                "address_id": address.json()["id"],
                "delivery_type": "free",
                "coupon_code": coup.code,
                "source": "website",
            })
            assert order.status_code == 201
            order_id = order.json()["id"]

            # Reviews: create (verified), duplicate blocked, summary, list.
            review = client.post(f"/products/{p1.id}/reviews", headers=uh, json={
                "rating": 5, "title": "Superb", "body": "Loved it"})
            assert review.status_code == 201
            assert review.json()["verified_purchase"] is True
            review_id = review.json()["id"]
            dup = client.post(f"/products/{p1.id}/reviews", headers=uh,
                              json={"rating": 4})
            assert dup.status_code == 409
            summary = client.get(f"/products/{p1.id}/reviews/summary").json()
            assert summary["avg_rating"] == 5.0
            assert summary["review_count"] == 1
            listed = client.get(f"/products/{p1.id}/reviews").json()
            assert len(listed) == 1
            assert listed[0]["reviewer"] != user.phone  # masked
            # Cannot vote on your own review.
            assert client.post(f"/reviews/{review_id}/helpful",
                               headers=uh).status_code == 400

            # Wishlist: add (idempotent), list, remove.
            assert client.post(f"/wishlist/{p1.id}", headers=uh).status_code == 201
            assert client.post(f"/wishlist/{p1.id}", headers=uh).status_code == 201
            wishlist = client.get("/wishlist", headers=uh).json()
            assert [w["id"] for w in wishlist] == [p1.id]
            assert wishlist[0]["sku"] == f"{PREFIX}-A"
            assert client.delete(f"/wishlist/{p1.id}", headers=uh).status_code == 204
            assert client.get("/wishlist", headers=uh).json() == []

            # Bought together reflects the shared order.
            together = client.get(f"/products/{p1.id}/bought-together").json()
            assert [p["id"] for p in together] == [p2.id]

            # Returns: request, duplicate blocked, mine.
            ret = client.post("/returns", headers=uh, json={
                "order_id": order_id, "reason": "damaged"})
            assert ret.status_code == 201
            assert client.post("/returns", headers=uh, json={
                "order_id": order_id, "reason": "other"}).status_code == 409
            mine = client.get("/returns/me", headers=uh).json()
            assert len(mine) == 1 and mine[0]["status"] == "requested"

            # Admin: moderate review, refund return (free order → no payment).
            login = client.post("/auth/admin/login", json={
                "username": admin.username, "password": "Pass-12345!x"})
            assert login.status_code == 200
            ah = {"Authorization": f"Bearer {login.json()['access_token']}"}
            listed_admin = client.get("/admin/reviews", headers=ah).json()
            assert any(x["id"] == review_id for x in listed_admin)
            assert client.patch(f"/admin/reviews/{review_id}", headers=ah, json={
                "status": "hidden"}).status_code == 200
            assert client.get(f"/products/{p1.id}/reviews").json() == []
            assert client.patch(f"/admin/reviews/{review_id}", headers=ah, json={
                "status": "published",
                "seller_response": "Thanks!"}).status_code == 200

            returns = client.get("/admin/returns", headers=ah).json()
            assert any(x["id"] == ret.json()["id"] for x in returns)
            decided = client.patch(f"/admin/returns/{ret.json()['id']}",
                                   headers=ah,
                                   json={"action": "refund", "admin_note": "ok"})
            assert decided.status_code == 200
            fetched = client.get(f"/orders/{order_id}", headers=uh).json()
            assert fetched["status"] == "cancelled"
            restored = client.get(f"/products/{p1.id}").json()
            assert restored["stock_quantity"] == 10

            # Dashboard carries the new account-health signals.
            dashboard = client.get("/admin/analytics/dashboard", headers=ah).json()
            assert "health" in dashboard
            assert "open_returns" in dashboard["alerts"]
    finally:
        asyncio.run(_wipe((p1, p2, coup, user, admin, cat)))
