import asyncio
import csv
import io
import uuid
from datetime import datetime, timedelta, timezone
from typing import Annotated, Literal

import firebase_admin.storage
from fastapi import APIRouter, Depends, HTTPException, Request, Response, UploadFile, File
from PIL import Image
from pydantic import BaseModel, Field
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..database import get_db
from ..dependencies import require_admin_jwt as require_admin, require_admin_role
from ..config import settings
from ..models import (
    AdminAuditLog,
    AdminLoginHistory,
    AdminUser,
    AppSetting,
    Banner,
    Category,
    Coupon,
    DeliveryTracking,
    Order,
    OrderItem,
    PaymentAttempt,
    Product,
    User,
)
from ..models.delivery_setting import DeliverySetting
from ..services.firebase_service import get_firebase_app, send_broadcast_notification, notify_order_confirmed, set_user_role_claim
from ..services.admin_audit import log_admin_action
from ..services.event_bus import emit_event
from ..services.password import hash_password
from ..services.order_status import validate_order_status_transition
from ..services.payment_service import amount_to_paise, refund_razorpay_payment
from ..schemas.admin import CouponCreate, CouponOut, CouponUpdate
from ..schemas.banner import BannerCreate, BannerOut, BannerUpdate
from ..schemas.category import CategoryCreate, CategoryOut, CategoryUpdate
from ..schemas.product import ProductCreate, ProductOut, ProductUpdate

router = APIRouter(prefix="/admin", tags=["admin"])


def _client_ip(request: Request) -> str | None:
    return request.client.host if request.client else None


async def _resolve_product_category_id(
    db: AsyncSession,
    category: str,
    category_id: str | None,
) -> str:
    query = (
        select(Category).where(Category.id == category_id)
        if category_id
        else select(Category).where(Category.name == category)
    )
    result = await db.execute(query)
    category_row = result.scalar_one_or_none()
    if category_row is None or category_row.name != category:
        raise HTTPException(422, "Product category does not match an existing category.")
    return category_row.id


# ── Image Upload ──────────────────────────────────────────────────────────────

_ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
_MAX_FILE_BYTES = 5 * 1024 * 1024  # 5 MB
_MAX_IMAGE_PIXELS = 25_000_000
_EXTENSION_BY_CONTENT_TYPE = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
    "image/gif": "gif",
}
_FORMAT_BY_CONTENT_TYPE = {
    "image/jpeg": "JPEG",
    "image/png": "PNG",
    "image/webp": "WEBP",
    "image/gif": "GIF",
}


@router.post("/upload", response_model=dict)
async def upload_image(
    file: Annotated[UploadFile, File(...)],
    _: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
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
    if not content:
        raise HTTPException(status_code=400, detail="Image file is empty")
    if len(content) > _MAX_FILE_BYTES:
        raise HTTPException(status_code=413, detail="File exceeds 5 MB limit")
    try:
        with Image.open(io.BytesIO(content)) as image:
            image_format = image.format
            width, height = image.size
            image.verify()
    except (OSError, RuntimeError, ValueError) as exc:
        raise HTTPException(status_code=400, detail="Image file is corrupt or unsupported") from exc
    if image_format != _FORMAT_BY_CONTENT_TYPE[file.content_type]:
        raise HTTPException(status_code=400, detail="Declared image type does not match file content")
    if width <= 0 or height <= 0 or width * height > _MAX_IMAGE_PIXELS:
        raise HTTPException(status_code=413, detail="Image dimensions exceed the limit")

    # Derive the extension from the validated content-type, never from the
    # client-supplied filename — an unsanitized filename could inject path
    # separators or arbitrary characters into the storage blob name.
    ext = _EXTENSION_BY_CONTENT_TYPE[file.content_type]
    blob_name = f"products/{uuid.uuid4()}.{ext}"

    get_firebase_app()  # ensure initialised
    bucket = firebase_admin.storage.bucket(settings.firebase_storage_bucket)
    blob = bucket.blob(blob_name)
    await asyncio.to_thread(blob.upload_from_string, content, content_type=file.content_type)
    await asyncio.to_thread(blob.make_public)

    return {"url": blob.public_url}


# ── Categories ────────────────────────────────────────────────────────────────

@router.get("/categories", response_model=list[CategoryOut])
async def admin_list_categories(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
) -> list[Category]:
    result = await db.execute(select(Category).order_by(Category.sort_order, Category.name))
    return list(result.scalars().all())


@router.post("/categories", response_model=CategoryOut, status_code=201)
async def admin_create_category(
    request: Request,
    payload: CategoryCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> Category:
    existing = await db.execute(select(Category).where(Category.name == payload.name))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Category name already exists")
    category = Category(**payload.model_dump())
    db.add(category)
    await db.commit()
    await db.refresh(category)
    await log_admin_action(db, admin["admin_user_id"], "category.create", "category", category.id, ip_address=_client_ip(request))
    await emit_event("category", "created", category.id, CategoryOut.model_validate(category).model_dump(mode="json"))
    return category


@router.put("/categories/{category_id}", response_model=CategoryOut)
async def admin_update_category(
    request: Request,
    category_id: str,
    payload: CategoryUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> Category:
    result = await db.execute(select(Category).where(Category.id == category_id))
    category = result.scalar_one_or_none()
    if category is None:
        raise HTTPException(status_code=404, detail="Category not found")
    changes = payload.model_dump(exclude_unset=True)
    for field, value in changes.items():
        setattr(category, field, value)
    await db.commit()
    await db.refresh(category)
    await log_admin_action(db, admin["admin_user_id"], "category.update", "category", category.id, details=changes, ip_address=_client_ip(request))
    await emit_event("category", "updated", category.id, CategoryOut.model_validate(category).model_dump(mode="json"))
    return category


@router.delete("/categories/{category_id}", status_code=204)
async def admin_delete_category(
    request: Request,
    category_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> None:
    result = await db.execute(select(Category).where(Category.id == category_id))
    category = result.scalar_one_or_none()
    if category is None:
        raise HTTPException(status_code=404, detail="Category not found")

    product_ref = await db.execute(
        select(Product.id).where(Product.category_id == category_id).limit(1)
    )
    if product_ref.scalar_one_or_none() is not None:
        category.is_active = False
        await db.commit()
        await db.refresh(category)
        await log_admin_action(
            db,
            admin["admin_user_id"],
            "category.deactivate",
            "category",
            category_id,
            details={"reason": "delete requested but category has products"},
            ip_address=_client_ip(request),
        )
        await emit_event(
            "category",
            "updated",
            category_id,
            CategoryOut.model_validate(category).model_dump(mode="json"),
        )
        return

    await db.delete(category)
    await db.commit()
    await log_admin_action(db, admin["admin_user_id"], "category.delete", "category", category_id, ip_address=_client_ip(request))
    await emit_event("category", "deleted", category_id)


# ── Banners ──────────────────────────────────────────────────────────────────

@router.get("/banners", response_model=list[BannerOut])
async def admin_list_banners(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
) -> list[Banner]:
    result = await db.execute(select(Banner).order_by(Banner.sort_order))
    return list(result.scalars().all())


@router.post("/banners", response_model=BannerOut, status_code=201)
async def admin_create_banner(
    request: Request,
    payload: BannerCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> Banner:
    banner = Banner(**payload.model_dump())
    db.add(banner)
    await db.commit()
    await db.refresh(banner)
    await log_admin_action(db, admin["admin_user_id"], "banner.create", "banner", banner.id, ip_address=_client_ip(request))
    await emit_event("banner", "created", banner.id, BannerOut.model_validate(banner).model_dump(mode="json"))
    return banner


@router.put("/banners/{banner_id}", response_model=BannerOut)
async def admin_update_banner(
    request: Request,
    banner_id: str,
    payload: BannerUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> Banner:
    result = await db.execute(select(Banner).where(Banner.id == banner_id))
    banner = result.scalar_one_or_none()
    if banner is None:
        raise HTTPException(status_code=404, detail="Banner not found")
    changes = payload.model_dump(exclude_unset=True)
    starts_at = changes.get("starts_at", banner.starts_at)
    ends_at = changes.get("ends_at", banner.ends_at)
    if starts_at and ends_at and ends_at <= starts_at:
        raise HTTPException(status_code=422, detail="ends_at must be after starts_at")
    for field, value in changes.items():
        setattr(banner, field, value)
    await db.commit()
    await db.refresh(banner)
    await log_admin_action(db, admin["admin_user_id"], "banner.update", "banner", banner.id, details=changes, ip_address=_client_ip(request))
    await emit_event("banner", "updated", banner.id, BannerOut.model_validate(banner).model_dump(mode="json"))
    return banner


@router.delete("/banners/{banner_id}", status_code=204)
async def admin_delete_banner(
    request: Request,
    banner_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> None:
    result = await db.execute(select(Banner).where(Banner.id == banner_id))
    banner = result.scalar_one_or_none()
    if banner is None:
        raise HTTPException(status_code=404, detail="Banner not found")
    await db.delete(banner)
    await db.commit()
    await log_admin_action(db, admin["admin_user_id"], "banner.delete", "banner", banner_id, ip_address=_client_ip(request))
    await emit_event("banner", "deleted", banner_id)


# ── Products ─────────────────────────────────────────────────────────────────

@router.get("/products", response_model=list[ProductOut])
async def admin_list_products(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[dict, Depends(require_admin)],
    q: str | None = None,
) -> list[Product]:
    query = select(Product)
    if q:
        query = query.where(or_(Product.name.ilike(f"%{q}%"), Product.category.ilike(f"%{q}%")))
    result = await db.execute(query)
    return list(result.scalars().all())


@router.post("/products", response_model=ProductOut, status_code=201)
async def admin_create_product(
    request: Request,
    payload: ProductCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> Product:
    data = payload.model_dump()
    data["category_id"] = await _resolve_product_category_id(
        db,
        payload.category,
        payload.category_id,
    )
    product = Product(**data)
    db.add(product)
    await db.commit()
    await db.refresh(product)
    await log_admin_action(db, admin["admin_user_id"], "product.create", "product", product.id, ip_address=_client_ip(request))
    await emit_event("product", "created", product.id, ProductOut.model_validate(product).model_dump(mode="json"))
    return product


@router.put("/products/{product_id}", response_model=ProductOut)
async def admin_update_product(
    request: Request,
    product_id: str,
    payload: ProductUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> Product:
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    changes = payload.model_dump(exclude_unset=True)
    if "category" in changes or "category_id" in changes:
        changes["category_id"] = await _resolve_product_category_id(
            db,
            changes.get("category", product.category),
            changes.get("category_id")
            if "category" in changes
            else product.category_id,
        )
    for field, value in changes.items():
        setattr(product, field, value)
    if product.is_orderable and product.base_price <= 0 and not product.sizes:
        raise HTTPException(
            status_code=422,
            detail="A product must have a positive base or size price",
        )
    await db.commit()
    await db.refresh(product)
    await log_admin_action(db, admin["admin_user_id"], "product.update", "product", product.id, details=changes, ip_address=_client_ip(request))
    await emit_event("product", "updated", product.id, ProductOut.model_validate(product).model_dump(mode="json"))
    return product


async def _has_order_references(db: AsyncSession, product_id: str) -> bool:
    result = await db.execute(
        select(OrderItem.id).where(OrderItem.product_id == product_id).limit(1)
    )
    return result.first() is not None


@router.delete("/products/{product_id}", status_code=204)
async def admin_delete_product(
    request: Request,
    product_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> None:
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    # Products in order history can't be hard-deleted (FK) — deactivate instead.
    if await _has_order_references(db, product_id):
        product.is_active = False
        await db.commit()
        await db.refresh(product)
        await log_admin_action(db, admin["admin_user_id"], "product.deactivate", "product", product_id, details={"reason": "delete requested but product has orders"}, ip_address=_client_ip(request))
        await emit_event("product", "updated", product_id, ProductOut.model_validate(product).model_dump(mode="json"))
        return
    await db.delete(product)
    await db.commit()
    await log_admin_action(db, admin["admin_user_id"], "product.delete", "product", product_id, ip_address=_client_ip(request))
    await emit_event("product", "deleted", product_id)


class BulkProductUpdate(BaseModel):
    ids: list[str] = Field(min_length=1, max_length=500)
    update: ProductUpdate


class BulkProductIds(BaseModel):
    ids: list[str] = Field(min_length=1, max_length=500)


@router.post("/products/bulk-update", response_model=list[ProductOut])
async def admin_bulk_update_products(
    request: Request,
    payload: BulkProductUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> list[Product]:
    changes = payload.update.model_dump(exclude_unset=True)
    if not payload.ids or not changes:
        raise HTTPException(status_code=422, detail="ids and at least one update field required")
    result = await db.execute(select(Product).where(Product.id.in_(payload.ids)))
    products = list(result.scalars().all())
    if not products:
        raise HTTPException(status_code=404, detail="No matching products")
    if "category" in changes or "category_id" in changes:
        changes["category_id"] = await _resolve_product_category_id(
            db,
            changes.get("category", products[0].category),
            changes.get("category_id")
            if "category" in changes
            else products[0].category_id,
        )
    for product in products:
        for field, value in changes.items():
            setattr(product, field, value)
        if product.is_orderable and product.base_price <= 0 and not product.sizes:
            raise HTTPException(
                status_code=422,
                detail=f"{product.name} must have a positive base or size price",
            )
    await db.commit()
    await log_admin_action(db, admin["admin_user_id"], "product.bulk_update", "product", ",".join(payload.ids), details=changes, ip_address=_client_ip(request))
    for product in products:
        await db.refresh(product)
        await emit_event("product", "updated", product.id, ProductOut.model_validate(product).model_dump(mode="json"))
    return products


@router.post("/products/bulk-delete", status_code=204)
async def admin_bulk_delete_products(
    request: Request,
    payload: BulkProductIds,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> None:
    if not payload.ids:
        raise HTTPException(status_code=422, detail="ids required")
    result = await db.execute(select(Product).where(Product.id.in_(payload.ids)))
    products = list(result.scalars().all())
    if not products:
        raise HTTPException(status_code=404, detail="No matching products")
    # Products in order history can't be hard-deleted (FK) — deactivate instead.
    deleted_ids: list[str] = []
    deactivated: list[Product] = []
    for product in products:
        if await _has_order_references(db, product.id):
            product.is_active = False
            deactivated.append(product)
        else:
            deleted_ids.append(product.id)
            await db.delete(product)
    await db.commit()
    await log_admin_action(
        db, admin["admin_user_id"], "product.bulk_delete", "product", ",".join(payload.ids),
        details={"deleted": deleted_ids, "deactivated": [p.id for p in deactivated]},
        ip_address=_client_ip(request),
    )
    for pid in deleted_ids:
        await emit_event("product", "deleted", pid)
    for product in deactivated:
        await db.refresh(product)
        await emit_event("product", "updated", product.id, ProductOut.model_validate(product).model_dump(mode="json"))


# ── Orders ────────────────────────────────────────────────────────────────────

@router.get("/orders")
async def admin_list_orders(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[dict, Depends(require_admin)],
    status: str | None = None,
    q: str | None = None,
) -> list[dict]:
    query = select(Order).options(
        selectinload(Order.items),
        selectinload(Order.address),
        selectinload(Order.customer),
    )
    if status:
        query = query.where(Order.status == status)
    if q:
        query = query.join(User, Order.user_id == User.id).where(User.phone.ilike(f"%{q}%"))
    query = query.order_by(Order.created_at.desc())
    result = await db.execute(query)
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


@router.get("/orders/export")
async def admin_export_orders(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[dict, Depends(require_admin)],
    status: str | None = None,
) -> Response:
    """Download the (optionally status-filtered) order list as CSV."""
    query = select(Order).options(
        selectinload(Order.items),
        selectinload(Order.address),
        selectinload(Order.customer),
    )
    if status:
        query = query.where(Order.status == status)
    query = query.order_by(Order.created_at.desc())
    result = await db.execute(query)
    orders = result.scalars().all()

    buf = io.StringIO()
    writer = csv.writer(buf)
    writer.writerow([
        "order_id", "created_at", "status", "customer_phone", "items",
        "item_count", "delivery_type", "delivery_charge", "discount",
        "coupon_code", "total_price", "razorpay_payment_id",
        "delivery_partner_id", "city", "pincode",
    ])
    for o in orders:
        items_desc = "; ".join(
            f"{i.product_id} x{i.quantity} ({i.selected_size or 'std'}) @ {i.unit_price}"
            for i in o.items
        )
        writer.writerow([
            o.id,
            o.created_at.isoformat(),
            o.status,
            o.customer.phone if o.customer else "",
            items_desc,
            len(o.items),
            o.delivery_type,
            o.delivery_charge,
            o.discount,
            o.coupon_code or "",
            o.total_price,
            o.razorpay_payment_id or "",
            o.delivery_partner_id or "",
            o.address.city if o.address else "",
            o.address.pincode if o.address else "",
        ])

    filename = f"snapprint-orders-{datetime.now(timezone.utc).strftime('%Y%m%d-%H%M')}.csv"
    return Response(
        content=buf.getvalue(),
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


class AssignDeliveryRequest(BaseModel):
    delivery_partner_id: str = Field(min_length=1, max_length=128)


@router.post("/orders/{order_id}/assign")
async def admin_assign_delivery(
    request: Request,
    order_id: str,
    payload: AssignDeliveryRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[
        dict,
        Depends(require_admin_role("super_admin", "manager", "support_staff")),
    ],
) -> dict:
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.status in {"delivered", "cancelled"}:
        raise HTTPException(status_code=409, detail="Terminal orders cannot be assigned")

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
    await log_admin_action(db, admin["admin_user_id"], "order.assign_delivery", "order", order_id, details={"delivery_partner_id": payload.delivery_partner_id}, ip_address=_client_ip(request))
    # Notify the assigned delivery partner's app so its order list refreshes live
    await emit_event(
        "order", "assigned", order_id,
        {"delivery_partner_id": payload.delivery_partner_id},
        user_id=payload.delivery_partner_id,
    )
    return {"ok": True, "order_id": order_id, "delivery_partner_id": payload.delivery_partner_id}


class OrderUpdateRequest(BaseModel):
    # Must match delivery.py's VALID_STATUS_TRANSITIONS states plus "cancelled".
    status: Literal["confirmed", "picked_up", "out_for_delivery", "delivered", "cancelled"] | None = None
    notes: str | None = Field(default=None, max_length=5000)


@router.get("/orders/{order_id}")
async def admin_get_order(
    order_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[dict, Depends(require_admin)],
) -> dict:
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.product),
            selectinload(Order.address),
            selectinload(Order.customer),
            selectinload(Order.tracking_events),
        )
        .where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    return {
        "id": order.id,
        "status": order.status,
        "notes": order.notes,
        "total_price": order.total_price,
        "delivery_type": order.delivery_type,
        "delivery_charge": order.delivery_charge,
        "discount": order.discount,
        "coupon_code": order.coupon_code,
        "customer_phone": order.customer.phone if order.customer else None,
        "delivery_partner_id": order.delivery_partner_id,
        "address": (
            f"{order.delivery_address_snapshot}, {order.delivery_city_snapshot} - {order.delivery_pincode_snapshot}"
            if order.delivery_address_snapshot
            else f"{order.address.full_address}, {order.address.city} - {order.address.pincode}"
            if order.address else None
        ),
        "razorpay_order_id": order.razorpay_order_id,
        "razorpay_payment_id": order.razorpay_payment_id,
        "razorpay_refund_id": order.razorpay_refund_id,
        "refund_status": order.refund_status,
        "created_at": order.created_at.isoformat(),
        "estimated_delivery": order.estimated_delivery.isoformat() if order.estimated_delivery else None,
        "items": [
            {
                "id": i.id,
                "product_name": i.product.name if i.product else None,
                "quantity": i.quantity,
                "selected_size": i.selected_size,
                "unit_price": i.unit_price,
                "image_url": i.image_url,
            }
            for i in order.items
        ],
        "timeline": [
            {"status": t.status, "timestamp": t.timestamp.isoformat(), "proof_url": t.proof_url}
            for t in sorted(order.tracking_events, key=lambda t: t.timestamp)
        ],
    }


@router.patch("/orders/{order_id}")
async def admin_update_order(
    request: Request,
    order_id: str,
    payload: OrderUpdateRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[
        dict,
        Depends(
            require_admin_role(
                "super_admin", "manager", "support_staff", "printing_staff"
            )
        ),
    ],
) -> dict:
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.customer),
            selectinload(Order.items).selectinload(OrderItem.product),
        )
        .where(Order.id == order_id)
        .with_for_update()
    )
    order = result.scalar_one_or_none()
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")

    changes: dict = {}
    if payload.notes is not None:
        order.notes = payload.notes
        changes["notes"] = payload.notes
    if payload.status is not None:
        admin_role = admin.get("admin_role")
        if admin_role == "support_staff":
            raise HTTPException(403, "Support staff can edit notes but not order status.")
        if payload.status == "cancelled" and admin_role not in {
            "super_admin",
            "manager",
        }:
            raise HTTPException(403, "Only managers can cancel an order.")
        if validate_order_status_transition(order.status, payload.status):
            if payload.status == "cancelled" and order.razorpay_payment_id:
                try:
                    refund = await asyncio.to_thread(
                        refund_razorpay_payment,
                        order.razorpay_payment_id,
                        amount_to_paise(order.total_price),
                        receipt=f"snapprint-{order.id}",
                    )
                except Exception as exc:
                    raise HTTPException(
                        502,
                        "The payment could not be refunded; the order remains active.",
                    ) from exc
                if refund["amount"] != amount_to_paise(order.total_price):
                    raise HTTPException(
                        502,
                        "The payment provider returned an incomplete refund.",
                    )
                order.razorpay_refund_id = refund["id"] or order.razorpay_refund_id
                order.refund_status = refund["status"]

            if payload.status == "cancelled":
                for item in order.items:
                    if item.product and item.product.tracks_inventory:
                        item.product.stock_quantity += item.quantity
                if order.coupon_code:
                    coupon_result = await db.execute(
                        select(Coupon)
                        .where(Coupon.code == order.coupon_code)
                        .with_for_update()
                    )
                    coupon = coupon_result.scalar_one_or_none()
                    if coupon is not None and coupon.used_count > 0:
                        coupon.used_count -= 1
            order.status = payload.status
            changes["status"] = payload.status
            db.add(DeliveryTracking(order_id=order.id, status=payload.status))

    await db.commit()
    await log_admin_action(db, admin["admin_user_id"], "order.update", "order", order_id, details=changes, ip_address=_client_ip(request))
    await emit_event(
        "order",
        "status_changed" if payload.status is not None else "updated",
        order_id,
        {"status": order.status, "notes": order.notes},
        user_id=order.user_id,
    )
    if payload.status == "cancelled":
        for item in order.items:
            if item.product and item.product.tracks_inventory:
                await emit_event(
                    "product",
                    "updated",
                    item.product.id,
                    ProductOut.model_validate(item.product).model_dump(mode="json"),
                )

    # This is the pending -> confirmed transition (the customer's first
    # confirmation that their order was accepted) — send the push notification
    # here since it's the only place this status is ever set.
    if payload.status == "confirmed" and order.customer and order.customer.fcm_token:
        try:
            notify_order_confirmed(order.customer.fcm_token, order.id)
        except Exception:
            pass

    return {"ok": True, "order_id": order_id}


# ── Users ─────────────────────────────────────────────────────────────────────

@router.get("/users")
async def admin_list_users(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[dict, Depends(require_admin)],
    role: str | None = None,
    q: str | None = None,
) -> list[dict]:
    query = select(User)
    if role:
        query = query.where(User.role == role)
    if q:
        query = query.where(User.phone.ilike(f"%{q}%"))
    result = await db.execute(query)
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


@router.get("/users/{user_id}")
async def admin_get_user(
    user_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[dict, Depends(require_admin)],
) -> dict:
    result = await db.execute(
        select(User).options(selectinload(User.addresses), selectinload(User.orders)).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "id": user.id,
        "phone": user.phone,
        "role": user.role,
        "is_active": user.is_active,
        "referral_code": user.referral_code,
        "created_at": user.created_at.isoformat(),
        "addresses": [
            {"id": a.id, "full_address": a.full_address, "city": a.city, "pincode": a.pincode, "is_default": a.is_default}
            for a in user.addresses
        ],
        "orders": [
            {"id": o.id, "status": o.status, "total_price": o.total_price, "created_at": o.created_at.isoformat()}
            for o in sorted(user.orders, key=lambda o: o.created_at, reverse=True)
        ],
    }


class UserUpdateRequest(BaseModel):
    is_active: bool | None = None


@router.patch("/users/{user_id}")
async def admin_update_user(
    request: Request,
    user_id: str,
    payload: UserUpdateRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> dict:
    """Suspend/reactivate a customer or delivery-partner account."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    changes: dict = {}
    if payload.is_active is not None:
        user.is_active = payload.is_active
        changes["is_active"] = payload.is_active
    await db.commit()
    await log_admin_action(db, admin["admin_user_id"], "user.update", "user", user_id, details=changes, ip_address=_client_ip(request))
    await emit_event("user", "updated", user_id, {"is_active": user.is_active}, user_id=user_id)
    return {"id": user.id, "is_active": user.is_active}


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


@router.post("/delivery-partners/{user_id}/promote")
async def admin_promote_to_delivery(
    request: Request,
    user_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> dict:
    """Promote an existing customer account to delivery partner role."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    if user.role == "delivery":
        return {"id": user.id, "phone": user.phone, "role": user.role, "message": "Already a delivery partner"}
    user.role = "delivery"
    await db.commit()
    await db.refresh(user)
    try:
        set_user_role_claim(user.firebase_uid, "delivery")
    except Exception:
        pass
    await log_admin_action(db, admin["admin_user_id"], "user.promote", "user", user_id, details={"new_role": "delivery"}, ip_address=_client_ip(request))
    await emit_event("user", "role_changed", user_id, {"role": "delivery"}, user_id=user_id)
    return {"id": user.id, "phone": user.phone, "role": user.role, "message": "Promoted to delivery partner"}


@router.post("/delivery-partners/{user_id}/demote")
async def admin_demote_to_customer(
    request: Request,
    user_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> dict:
    """Revert a delivery partner back to customer role."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    user.role = "customer"
    await db.commit()
    await db.refresh(user)
    try:
        set_user_role_claim(user.firebase_uid, "customer")
    except Exception:
        pass
    await log_admin_action(db, admin["admin_user_id"], "user.demote", "user", user_id, details={"new_role": "customer"}, ip_address=_client_ip(request))
    await emit_event("user", "role_changed", user_id, {"role": "customer"}, user_id=user_id)
    return {"id": user.id, "phone": user.phone, "role": user.role, "message": "Demoted to customer"}


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
    request: Request,
    payload: CouponCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> Coupon:
    existing = await db.execute(select(Coupon).where(Coupon.code == payload.code))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Coupon code already exists")
    coupon = Coupon(**payload.model_dump())
    db.add(coupon)
    await db.commit()
    await db.refresh(coupon)
    await log_admin_action(db, admin["admin_user_id"], "coupon.create", "coupon", coupon.id, ip_address=_client_ip(request))
    await emit_event("coupon", "created", coupon.id, CouponOut.model_validate(coupon).model_dump(mode="json"))
    return coupon


@router.put("/coupons/{coupon_id}", response_model=CouponOut)
async def admin_update_coupon(
    request: Request,
    coupon_id: str,
    payload: CouponUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> Coupon:
    result = await db.execute(select(Coupon).where(Coupon.id == coupon_id))
    coupon = result.scalar_one_or_none()
    if coupon is None:
        raise HTTPException(status_code=404, detail="Coupon not found")
    changes = payload.model_dump(exclude_unset=True)
    for field, value in changes.items():
        setattr(coupon, field, value)
    if coupon.discount_type == "percent" and coupon.value > 100:
        raise HTTPException(status_code=422, detail="value cannot exceed 100 for a percent coupon")
    await db.commit()
    await db.refresh(coupon)
    await log_admin_action(db, admin["admin_user_id"], "coupon.update", "coupon", coupon.id, details=changes, ip_address=_client_ip(request))
    await emit_event("coupon", "updated", coupon.id, CouponOut.model_validate(coupon).model_dump(mode="json"))
    return coupon


@router.delete("/coupons/{coupon_id}", status_code=204)
async def admin_delete_coupon(
    request: Request,
    coupon_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> None:
    result = await db.execute(select(Coupon).where(Coupon.id == coupon_id))
    coupon = result.scalar_one_or_none()
    if coupon is None:
        raise HTTPException(status_code=404, detail="Coupon not found")
    await db.delete(coupon)
    await db.commit()
    await log_admin_action(db, admin["admin_user_id"], "coupon.delete", "coupon", coupon_id, ip_address=_client_ip(request))
    await emit_event("coupon", "deleted", coupon_id)


# ── Delivery Settings ─────────────────────────────────────────────────────────

class DeliverySettingOut(BaseModel):
    type: str
    label: str
    price: float
    days_label: str
    is_active: bool

    model_config = {"from_attributes": True}


class DeliverySettingUpdate(BaseModel):
    label: str | None = Field(default=None, min_length=1, max_length=100)
    price: float | None = Field(default=None, ge=0, le=1_000_000)
    days_label: str | None = Field(default=None, min_length=1, max_length=100)
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
    request: Request,
    delivery_type: str,
    payload: DeliverySettingUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> DeliverySetting:
    result = await db.execute(
        select(DeliverySetting).where(DeliverySetting.type == delivery_type)
    )
    setting = result.scalar_one_or_none()
    if setting is None:
        raise HTTPException(status_code=404, detail="Delivery setting not found")
    changes = payload.model_dump(exclude_unset=True)
    for field, value in changes.items():
        setattr(setting, field, value)
    await db.commit()
    await db.refresh(setting)
    await log_admin_action(db, admin["admin_user_id"], "delivery_setting.update", "delivery_setting", delivery_type, details=changes, ip_address=_client_ip(request))
    await emit_event("delivery_setting", "updated", delivery_type, DeliverySettingOut.model_validate(setting).model_dump(mode="json"))
    return setting


# ── Payments ──────────────────────────────────────────────────────────────────

@router.get("/payments")
async def admin_list_payments(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[dict, Depends(require_admin)],
    status: str | None = None,
) -> list[dict]:
    q = select(PaymentAttempt).order_by(PaymentAttempt.created_at.desc())
    if status:
        q = q.where(PaymentAttempt.status == status)
    result = await db.execute(q)
    attempts = result.scalars().all()
    return [
        {
            "id": p.id,
            "razorpay_order_id": p.razorpay_order_id,
            "razorpay_payment_id": p.razorpay_payment_id,
            "status": p.status,
            "reason": p.reason,
            "user_id": p.user_id,
            "created_at": p.created_at.isoformat(),
        }
        for p in attempts
    ]


# ── Settings ──────────────────────────────────────────────────────────────────

class SettingUpdate(BaseModel):
    value: dict


@router.get("/settings")
async def admin_list_settings(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[dict, Depends(require_admin)],
) -> list[dict]:
    result = await db.execute(select(AppSetting))
    return [{"key": s.key, "value": s.value, "updated_at": s.updated_at.isoformat()} for s in result.scalars().all()]


@router.put("/settings/{key}")
async def admin_update_setting(
    request: Request,
    key: str,
    payload: SettingUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> dict:
    result = await db.execute(select(AppSetting).where(AppSetting.key == key))
    setting = result.scalar_one_or_none()
    if setting is None:
        setting = AppSetting(key=key, value=payload.value)
        db.add(setting)
    else:
        setting.value = payload.value
    await db.commit()
    await log_admin_action(db, admin["admin_user_id"], "setting.update", "setting", key, details=payload.value, ip_address=_client_ip(request))
    await emit_event("setting", "updated", key, {"key": key, "value": payload.value})
    return {"key": key, "value": payload.value}


# ── Audit logs & login history ──────────────────────────────────────────────

# ── Notifications ─────────────────────────────────────────────────────────────

class BroadcastNotificationRequest(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    body: str = Field(min_length=1, max_length=2000)


@router.post("/notifications/broadcast", status_code=201)
async def admin_broadcast_notification(
    request: Request,
    payload: BroadcastNotificationRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> dict:
    """Push an announcement to every app user via the FCM 'all_users' topic."""
    if not payload.title.strip() or not payload.body.strip():
        raise HTTPException(status_code=422, detail="title and body are required")
    try:
        await asyncio.to_thread(
            send_broadcast_notification,
            payload.title.strip(),
            payload.body.strip(),
            {"type": "announcement"},
        )
    except Exception as e:  # FCM/network failure — surface it to the admin
        raise HTTPException(status_code=502, detail=f"FCM broadcast failed: {e}")
    await log_admin_action(
        db, admin["admin_user_id"], "notification.broadcast", "notification", "broadcast",
        details={"title": payload.title.strip(), "body": payload.body.strip()},
        ip_address=_client_ip(request),
    )
    await emit_event("notification", "broadcast", None, {"title": payload.title.strip()}, admin_only=True)
    return {"success": True}


@router.get("/notifications/history")
async def admin_notification_history(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[dict, Depends(require_admin)],
) -> list[dict]:
    """Past broadcasts, sourced from the audit log (no extra table needed)."""
    result = await db.execute(
        select(AdminAuditLog)
        .where(AdminAuditLog.action == "notification.broadcast")
        .order_by(AdminAuditLog.created_at.desc())
        .limit(100)
    )
    return [
        {
            "id": l.id,
            "admin_user_id": l.admin_user_id,
            "title": (l.details or {}).get("title"),
            "body": (l.details or {}).get("body"),
            "created_at": l.created_at.isoformat(),
        }
        for l in result.scalars().all()
    ]


@router.get("/audit-logs")
async def admin_list_audit_logs(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
    admin_user_id: str | None = None,
    action: str | None = None,
) -> list[dict]:
    q = select(AdminAuditLog).order_by(AdminAuditLog.created_at.desc()).limit(500)
    if admin_user_id:
        q = q.where(AdminAuditLog.admin_user_id == admin_user_id)
    if action:
        q = q.where(AdminAuditLog.action == action)
    result = await db.execute(q)
    logs = result.scalars().all()
    return [
        {
            "id": l.id,
            "admin_user_id": l.admin_user_id,
            "action": l.action,
            "resource_type": l.resource_type,
            "resource_id": l.resource_id,
            "details": l.details,
            "ip_address": l.ip_address,
            "created_at": l.created_at.isoformat(),
        }
        for l in logs
    ]


@router.get("/login-history")
async def admin_list_login_history(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[dict, Depends(require_admin_role("super_admin", "manager"))],
) -> list[dict]:
    result = await db.execute(
        select(AdminLoginHistory).order_by(AdminLoginHistory.created_at.desc()).limit(200)
    )
    return [
        {
            "id": h.id,
            "admin_user_id": h.admin_user_id,
            "username_attempted": h.username_attempted,
            "ip_address": h.ip_address,
            "success": h.success,
            "created_at": h.created_at.isoformat(),
        }
        for h in result.scalars().all()
    ]


# ── Admin user management (super_admin only) ────────────────────────────────

class AdminUserCreate(BaseModel):
    username: str = Field(min_length=3, max_length=128, pattern=r"^[A-Za-z0-9_.-]+$")
    password: str = Field(min_length=12, max_length=512)
    role: str  # super_admin | manager | support_staff | printing_staff | delivery_staff


class AdminUserUpdate(BaseModel):
    role: str | None = None
    is_active: bool | None = None
    password: str | None = Field(default=None, min_length=12, max_length=512)


_VALID_ADMIN_ROLES = {"super_admin", "manager", "support_staff", "printing_staff", "delivery_staff"}


@router.get("/admins")
async def admin_list_admins(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[dict, Depends(require_admin_role("super_admin"))],
) -> list[dict]:
    result = await db.execute(select(AdminUser).order_by(AdminUser.created_at))
    return [
        {
            "id": a.id,
            "username": a.username,
            "role": a.role,
            "is_active": a.is_active,
            "last_login_at": a.last_login_at.isoformat() if a.last_login_at else None,
            "created_at": a.created_at.isoformat(),
        }
        for a in result.scalars().all()
    ]


@router.post("/admins", status_code=201)
async def admin_create_admin(
    request: Request,
    payload: AdminUserCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin"))],
) -> dict:
    if payload.role not in _VALID_ADMIN_ROLES:
        raise HTTPException(status_code=400, detail=f"role must be one of {sorted(_VALID_ADMIN_ROLES)}")
    existing = await db.execute(select(AdminUser).where(AdminUser.username == payload.username))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Username already exists")
    new_admin = AdminUser(
        username=payload.username,
        password_hash=hash_password(payload.password),
        role=payload.role,
    )
    db.add(new_admin)
    await db.commit()
    await db.refresh(new_admin)
    await log_admin_action(db, admin["admin_user_id"], "admin.create", "admin_user", new_admin.id, details={"role": payload.role}, ip_address=_client_ip(request))
    return {"id": new_admin.id, "username": new_admin.username, "role": new_admin.role}


@router.patch("/admins/{admin_id}")
async def admin_update_admin(
    request: Request,
    admin_id: str,
    payload: AdminUserUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[dict, Depends(require_admin_role("super_admin"))],
) -> dict:
    result = await db.execute(select(AdminUser).where(AdminUser.id == admin_id))
    target = result.scalar_one_or_none()
    if target is None:
        raise HTTPException(status_code=404, detail="Admin not found")

    demoting_or_disabling = (payload.role is not None and payload.role != "super_admin") or payload.is_active is False
    if demoting_or_disabling and target.role == "super_admin" and target.is_active:
        other_active = await db.execute(
            select(func.count()).select_from(AdminUser).where(
                AdminUser.role == "super_admin",
                AdminUser.is_active.is_(True),
                AdminUser.id != target.id,
            )
        )
        if other_active.scalar_one() == 0:
            raise HTTPException(status_code=400, detail="Cannot demote or disable the last active super_admin")

    changes: dict = {}
    if payload.role is not None:
        if payload.role not in _VALID_ADMIN_ROLES:
            raise HTTPException(status_code=400, detail=f"role must be one of {sorted(_VALID_ADMIN_ROLES)}")
        target.role = payload.role
        changes["role"] = payload.role
    if payload.is_active is not None:
        target.is_active = payload.is_active
        changes["is_active"] = payload.is_active
    if payload.password:
        target.password_hash = hash_password(payload.password)
        changes["password"] = "changed"
    await db.commit()
    await log_admin_action(db, admin["admin_user_id"], "admin.update", "admin_user", admin_id, details=changes, ip_address=_client_ip(request))
    return {"id": target.id, "username": target.username, "role": target.role, "is_active": target.is_active}


# ── Analytics ─────────────────────────────────────────────────────────────────

@router.get("/analytics/dashboard")
async def admin_analytics_dashboard(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[dict, Depends(require_admin)],
) -> dict:
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = today_start - timedelta(days=today_start.weekday())
    month_start = today_start.replace(day=1)
    year_start = today_start.replace(month=1, day=1)

    async def revenue_since(since: datetime) -> float:
        r = await db.execute(
            select(func.coalesce(func.sum(Order.total_price), 0)).where(Order.created_at >= since)
        )
        return float(r.scalar_one())

    revenue_today = await revenue_since(today_start)
    revenue_week = await revenue_since(week_start)
    revenue_month = await revenue_since(month_start)
    revenue_year = await revenue_since(year_start)

    status_counts_result = await db.execute(
        select(Order.status, func.count(Order.id)).group_by(Order.status)
    )
    status_counts = {status: count for status, count in status_counts_result.all()}

    orders_today_result = await db.execute(
        select(func.count(Order.id)).where(Order.created_at >= today_start)
    )
    orders_today = orders_today_result.scalar_one()

    total_users_result = await db.execute(select(func.count(User.id)).where(User.role == "customer"))
    total_users = total_users_result.scalar_one()

    new_users_result = await db.execute(
        select(func.count(User.id)).where(User.role == "customer", User.created_at >= month_start)
    )
    new_users_this_month = new_users_result.scalar_one()

    failed_payments_result = await db.execute(
        select(func.count(PaymentAttempt.id)).where(PaymentAttempt.status == "failed")
    )
    failed_payments = failed_payments_result.scalar_one()

    photos_uploaded_result = await db.execute(
        select(func.count(OrderItem.id)).where(OrderItem.image_url.is_not(None))
    )
    total_photos_uploaded = photos_uploaded_result.scalar_one()

    top_products_result = await db.execute(
        select(Product.name, func.sum(OrderItem.quantity).label("qty"))
        .join(OrderItem, OrderItem.product_id == Product.id)
        .group_by(Product.name)
        .order_by(func.sum(OrderItem.quantity).desc())
        .limit(5)
    )
    top_products = [{"name": name, "quantity": int(qty)} for name, qty in top_products_result.all()]

    return {
        "revenue": {
            "today": revenue_today,
            "week": revenue_week,
            "month": revenue_month,
            "year": revenue_year,
        },
        "orders": {
            "today": orders_today,
            "by_status": status_counts,
        },
        "users": {
            "total": total_users,
            "new_this_month": new_users_this_month,
        },
        "payments": {
            "failed": failed_payments,
        },
        "photos": {
            "total_uploaded": total_photos_uploaded,
        },
        "top_products": top_products,
    }


@router.get("/analytics/charts")
async def admin_analytics_charts(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[dict, Depends(require_admin)],
    days: int = 30,
) -> dict:
    since = datetime.now(timezone.utc) - timedelta(days=days)

    revenue_result = await db.execute(
        select(func.date(Order.created_at), func.sum(Order.total_price))
        .where(Order.created_at >= since)
        .group_by(func.date(Order.created_at))
        .order_by(func.date(Order.created_at))
    )
    revenue_series = [{"date": str(d), "revenue": float(r)} for d, r in revenue_result.all()]

    orders_result = await db.execute(
        select(func.date(Order.created_at), func.count(Order.id))
        .where(Order.created_at >= since)
        .group_by(func.date(Order.created_at))
        .order_by(func.date(Order.created_at))
    )
    orders_series = [{"date": str(d), "orders": int(c)} for d, c in orders_result.all()]

    users_result = await db.execute(
        select(func.date(User.created_at), func.count(User.id))
        .where(User.created_at >= since, User.role == "customer")
        .group_by(func.date(User.created_at))
        .order_by(func.date(User.created_at))
    )
    users_series = [{"date": str(d), "new_users": int(c)} for d, c in users_result.all()]

    return {"revenue": revenue_series, "orders": orders_series, "users": users_series}
