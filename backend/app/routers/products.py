from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..models import Product
from ..schemas.product import ProductListResponse, ProductOut

router = APIRouter(prefix="/products", tags=["products"])


@router.get("", response_model=ProductListResponse)
async def list_products(
    db: Annotated[AsyncSession, Depends(get_db)],
    category: str | None = Query(None),
    category_id: str | None = Query(None),
    featured: bool | None = Query(None),
    trending: bool | None = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
) -> ProductListResponse:
    q = select(Product).where(
        Product.is_active.is_(True),
        Product.base_price >= 0,
    )
    if category:
        # Case/whitespace-insensitive: admin product entry is free text and can
        # drift from the Category.name casing used to build this query param.
        q = q.where(func.lower(Product.category) == category.strip().lower())
    if category_id:
        q = q.where(Product.category_id == category_id)
    if featured is not None:
        q = q.where(Product.is_featured.is_(featured))
    if trending is not None:
        q = q.where(Product.is_trending.is_(trending))

    total_result = await db.execute(select(func.count()).select_from(q.subquery()))
    total = total_result.scalar_one()

    q = q.order_by(Product.sort_order, Product.created_at).offset((page - 1) * limit).limit(limit)
    result = await db.execute(q)
    products = result.scalars().all()

    return ProductListResponse(
        items=[ProductOut.model_validate(p) for p in products],
        total=total,
        page=page,
        limit=limit,
    )


@router.get("/{product_id}", response_model=ProductOut)
async def get_product(
    product_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> Product:
    result = await db.execute(
        select(Product).where(
            Product.id == product_id,
            Product.is_active.is_(True),
            Product.base_price >= 0,
        )
    )
    product = result.scalar_one_or_none()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return product
