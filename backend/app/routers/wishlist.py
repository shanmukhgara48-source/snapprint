from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError

from ..database import get_db
from ..dependencies import require_customer
from ..models import Product, User, WishlistItem
from ..schemas.product import ProductOut

router = APIRouter(prefix="/wishlist", tags=["wishlist"])


@router.get("", response_model=list[ProductOut])
async def my_wishlist(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> list[Product]:
    result = await db.execute(
        select(Product)
        .join(WishlistItem, WishlistItem.product_id == Product.id)
        .where(WishlistItem.user_id == user.id, Product.is_active.is_(True))
        .order_by(WishlistItem.created_at.desc())
    )
    return list(result.scalars().all())


@router.get("/ids")
async def my_wishlist_ids(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> dict[str, list[str]]:
    result = await db.execute(
        select(WishlistItem.product_id).where(WishlistItem.user_id == user.id)
    )
    return {"product_ids": list(result.scalars().all())}


@router.post("/{product_id}", status_code=201)
async def add_to_wishlist(
    product_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> dict:
    product = await db.get(Product, product_id)
    if product is None or not product.is_active:
        raise HTTPException(status_code=404, detail="Product not found")
    db.add(WishlistItem(user_id=user.id, product_id=product_id))
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()  # already saved — idempotent add
    return {"product_id": product_id, "saved": True}


@router.delete("/{product_id}", status_code=204)
async def remove_from_wishlist(
    product_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> None:
    result = await db.execute(
        select(WishlistItem).where(
            WishlistItem.user_id == user.id, WishlistItem.product_id == product_id
        )
    )
    item = result.scalar_one_or_none()
    if item is None:
        raise HTTPException(status_code=404, detail="Not in wishlist")
    await db.delete(item)
    await db.commit()
    return None
