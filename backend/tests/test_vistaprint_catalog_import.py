import pytest
from pydantic import ValidationError

from app.schemas.product import ProductCreate
from app.vistaprint_seed_data import VISTAPRINT_PHOTO_PRODUCTS


def test_import_contains_only_high_relevance_sellable_catalog_rows():
    assert len(VISTAPRINT_PHOTO_PRODUCTS) == 19
    assert len({product["name"] for product in VISTAPRINT_PHOTO_PRODUCTS}) == 19
    assert all(product["is_active"] for product in VISTAPRINT_PHOTO_PRODUCTS)
    assert all(product["source_url"].startswith("https://") for product in VISTAPRINT_PHOTO_PRODUCTS)
    assert all(product["source_checked_on"].isoformat() == "2026-08-03" for product in VISTAPRINT_PHOTO_PRODUCTS)

    orderable = [product for product in VISTAPRINT_PHOTO_PRODUCTS if product["is_orderable"]]
    assert [product["name"] for product in orderable] == [
        "Customised Photo with Frame - Table Stand"
    ]
    assert orderable[0]["base_price"] == 300


def test_catalog_only_products_may_omit_a_price_but_orderable_products_may_not():
    catalog_only = ProductCreate(
        name="Catalog Preview",
        category="Photo Books",
        base_price=0,
        is_orderable=False,
    )
    assert catalog_only.is_orderable is False

    with pytest.raises(ValidationError, match="positive base or size price"):
        ProductCreate(
            name="Invalid Orderable Product",
            category="Photo Books",
            base_price=0,
            is_orderable=True,
        )


def test_layflat_album_preserves_structured_workbook_details():
    layflat = next(
        product
        for product in VISTAPRINT_PHOTO_PRODUCTS
        if product["name"] == "Layflat Photo Albums"
    )

    assert layflat["source_rating"] == 4.5
    assert layflat["source_review_count"] == 16
    assert "12x18" in layflat["dimensions"]
    assert "24-50 pages" in layflat["dimensions"]
    assert "premium photo paper" in layflat["material"]
    assert layflat["is_orderable"] is False
