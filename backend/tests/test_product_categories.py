import asyncio
import uuid

from fastapi.testclient import TestClient
from sqlalchemy import delete

from app.database import AsyncSessionLocal, engine
from app.models import Product
from main import app


async def _create_alias_products(prefix: str) -> None:
    async with AsyncSessionLocal() as db:
        db.add_all(
            [
                Product(
                    name=f"{prefix}_display_name",
                    category="Photo Prints",
                    base_price=25,
                    images=[],
                ),
                Product(
                    name=f"{prefix}_legacy_slug",
                    category="photo_prints",
                    base_price=25,
                    images=[],
                ),
                Product(
                    name=f"{prefix}_legacy_album",
                    category="albums",
                    base_price=25,
                    images=[],
                ),
            ]
        )
        await db.commit()
    await engine.dispose()


async def _cleanup_alias_products(prefix: str) -> None:
    async with AsyncSessionLocal() as db:
        await db.execute(delete(Product).where(Product.name.like(f"{prefix}%")))
        await db.commit()
    await engine.dispose()


def test_product_category_filter_accepts_display_names_and_legacy_slugs():
    prefix = f"category_alias_{uuid.uuid4().hex[:8]}"
    asyncio.run(_create_alias_products(prefix))

    try:
        with TestClient(app) as client:
            display_response = client.get(
                "/products",
                params={"category": "Photo Prints", "limit": 100},
            )
            assert display_response.status_code == 200
            display_names = {
                item["name"] for item in display_response.json()["items"]
            }
            assert f"{prefix}_display_name" in display_names
            assert f"{prefix}_legacy_slug" in display_names

            slug_response = client.get(
                "/products",
                params={"category": "photo_prints", "limit": 100},
            )
            assert slug_response.status_code == 200
            slug_names = {item["name"] for item in slug_response.json()["items"]}
            assert f"{prefix}_display_name" in slug_names
            assert f"{prefix}_legacy_slug" in slug_names

            books_response = client.get(
                "/products",
                params={"category": "Photo Books", "limit": 100},
            )
            assert books_response.status_code == 200
            book_names = {item["name"] for item in books_response.json()["items"]}
            assert f"{prefix}_legacy_album" in book_names
    finally:
        asyncio.run(_cleanup_alias_products(prefix))
