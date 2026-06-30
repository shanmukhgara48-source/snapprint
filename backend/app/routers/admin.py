import uuid
from typing import Annotated

import firebase_admin.storage
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..database import get_db
from ..dependencies import require_admin_jwt as require_admin
from ..config import settings
from ..models import Coupon, Order, Product, User
from ..models.delivery_setting import DeliverySetting
from ..services.firebase_service import get_firebase_app
from ..schemas.admin import CouponCreate, CouponOut
from ..schemas.product import ProductCreate, ProductOut, ProductUpdate

router = APIRouter(prefix="/admin", tags=["admin"])


# ── Image Upload ──────────────────────────────────────────────────────────────

_ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
_MAX_FILE_BYTES = 5 * 1024 * 1024  # 5 MB


@router.post("/upload", response_model=dict)
async def upload_image(
    file: Annotated[UploadFile, File(...)],
    _: Annotated[User, Depends(require_admin)],
) -> dict:
    """
    Upload a product image to Firebase Storage.
    Returns {"url": "<public_url>"}.
    Accepts JPEG / PNG / WebP / GIF, max 5 MB.
    """
    if file.content_type not in _ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=415,
            detail=f"Unsupported file type '{file.content_type}'. "
                   "Allowed: jpeg, png, webp, gif.",
        )

    content = await file.read()
    if len(content) > _MAX_FILE_BYTES:
        raise HTTPException(status_code=413, detail="File exceeds 5 MB limit")

    ext = file.filename.rsplit(".", 1)[-1] if file.filename else "jpg"
    blob_name = f"products/{uuid.uuid4()}.{ext}"

    get_firebase_app()  # ensure initialised
    bucket = firebase_admin.storage.bucket(settings.firebase_storage_bucket)
    blob = bucket.blob(blob_name)
    blob.upload_from_string(content, content_type=file.content_type)
    blob.make_public()

    return {"url": blob.public_url}


# ── Categories ────────────────────────────────────────────────────────────────

@router.get("/categories", response_model=list[str])
async def admin_list_categories(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
) -> list[str]:
    """Returns the distinct category values that already exist in the products table."""
    result = await db.execute(
        select(Product.category).distinct().order_by(Product.category)
    )
    return [row[0] for row in result.all() if row[0]]


# ── Products ─────────────────────────────────────────────────────────────────

@router.get("/products", response_model=list[ProductOut])
async def admin_list_products(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
) -> list[Product]:
    result = await db.execute(select(Product))
    return list(result.scalars().all())


@router.post("/products", response_model=ProductOut, status_code=201)
async def admin_create_product(
    payload: ProductCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
) -> Product:
    product = Product(**payload.model_dump())
    db.add(product)
    await db.commit()
    await db.refresh(product)
    return product


@router.put("/products/{product_id}", response_model=ProductOut)
async def admin_update_product(
    product_id: str,
    payload: ProductUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
) -> Product:
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(product, field, value)
    await db.commit()
    await db.refresh(product)
    return product


@router.delete("/products/{product_id}", status_code=204)
async def admin_delete_product(
    product_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
) -> None:
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    await db.delete(product)
    await db.commit()


# ── Orders ────────────────────────────────────────────────────────────────────

@router.get("/orders")
async def admin_list_orders(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
    status: str | None = None,
) -> list[dict]:
    q = select(Order).options(
        selectinload(Order.items),
        selectinload(Order.address),
        selectinload(Order.customer),
    )
    if status:
        q = q.where(Order.status == status)
    q = q.order_by(Order.created_at.desc())
    result = await db.execute(q)
    orders = result.scalars().all()
    return [
        {
            "id": o.id,
            "status": o.status,
            "total_price": o.total_price,
            "customer_phone": o.customer.phone if o.customer else None,
            "item_count": len(o.items),
            "created_at": o.created_at.isoformat(),
            "delivery_partner_id": o.delivery_partner_id,
        }
        for o in orders
    ]


class AssignDeliveryRequest(BaseModel):
    delivery_partner_id: str


@router.post("/orders/{order_id}/assign")
async def admin_assign_delivery(
    order_id: str,
    payload: AssignDeliveryRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
) -> dict:
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")

    partner_result = await db.execute(
        select(User).where(
            User.id == payload.delivery_partner_id,
            User.role == "delivery",
            User.is_active.is_(True),
        )
    )
    partner = partner_result.scalar_one_or_none()
    if partner is None:
        raise HTTPException(status_code=404, detail="Delivery partner not found")

    order.delivery_partner_id = payload.delivery_partner_id
    await db.commit()
    return {"ok": True, "order_id": order_id, "delivery_partner_id": payload.delivery_partner_id}


# ── Users ─────────────────────────────────────────────────────────────────────

@router.get("/users")
async def admin_list_users(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
    role: str | None = None,
) -> list[dict]:
    q = select(User)
    if role:
        q = q.where(User.role == role)
    result = await db.execute(q)
    users = result.scalars().all()
    return [
        {
            "id": u.id,
            "phone": u.phone,
            "role": u.role,
            "is_active": u.is_active,
            "created_at": u.created_at.isoformat(),
        }
        for u in users
    ]


@router.get("/delivery-partners")
async def admin_delivery_partners(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
) -> list[dict]:
    result = await db.execute(
        select(User).where(User.role == "delivery", User.is_active.is_(True))
    )
    partners = result.scalars().all()
    return [{"id": p.id, "phone": p.phone} for p in partners]


# ── Coupons ────────────────────────────────────────────────────────────────────

@router.get("/coupons", response_model=list[CouponOut])
async def admin_list_coupons(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
) -> list[Coupon]:
    result = await db.execute(select(Coupon).order_by(Coupon.created_at.desc()))
    return list(result.scalars().all())


@router.post("/coupons", response_model=CouponOut, status_code=201)
async def admin_create_coupon(
    payload: CouponCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
) -> Coupon:
    existing = await db.execute(select(Coupon).where(Coupon.code == payload.code))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Coupon code already exists")
    coupon = Coupon(**payload.model_dump())
    db.add(coupon)
    await db.commit()
    await db.refresh(coupon)
    return coupon


@router.delete("/coupons/{coupon_id}", status_code=204)
async def admin_delete_coupon(
    coupon_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
) -> None:
    result = await db.execute(select(Coupon).where(Coupon.id == coupon_id))
    coupon = result.scalar_one_or_none()
    if coupon is None:
        raise HTTPException(status_code=404, detail="Coupon not found")
    await db.delete(coupon)
    await db.commit()


# ── Delivery Settings ─────────────────────────────────────────────────────────

class DeliverySettingOut(BaseModel):
    type: str
    label: str
    price: float
    days_label: str
    is_active: bool

    model_config = {"from_attributes": True}


class DeliverySettingUpdate(BaseModel):
    label: str | None = None
    price: float | None = None
    days_label: str | None = None
    is_active: bool | None = None


@router.get("/delivery-settings", response_model=list[DeliverySettingOut])
async def admin_list_delivery_settings(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
) -> list[DeliverySetting]:
    result = await db.execute(select(DeliverySetting).order_by(DeliverySetting.price))
    return list(result.scalars().all())


@router.put("/delivery-settings/{delivery_type}", response_model=DeliverySettingOut)
async def admin_update_delivery_setting(
    delivery_type: str,
    payload: DeliverySettingUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
) -> DeliverySetting:
    result = await db.execute(
        select(DeliverySetting).where(DeliverySetting.type == delivery_type)
    )
    setting = result.scalar_one_or_none()
    if setting is None:
        raise HTTPException(status_code=404, detail="Delivery setting not found")
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(setting, field, value)
    await db.commit()
    await db.refresh(setting)
    return setting
