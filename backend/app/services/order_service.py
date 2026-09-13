from datetime import datetime, timezone

from fastapi import HTTPException
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import Coupon, Product
from ..models.app_setting import AppSetting
from ..models.delivery_setting import DeliverySetting
from ..schemas.cart import (
    CartCalculateRequest,
    CartCalculateResponse,
    CartItemResult,
    DeliveryOption,
)


#: Fallback gift-wrap offer when no admin-configured AppSetting exists.
#: Admins control the live values via PUT /admin/settings/gift_wrap with
#: {"price": 49, "enabled": true}. Never trust a client-supplied fee.
GIFT_WRAP_DEFAULT = {"price": 49.0, "enabled": True}


async def get_gift_wrap_config(db: AsyncSession) -> dict:
    """Admin-controlled gift-wrap offer: {"price": float, "enabled": bool}."""
    result = await db.execute(
        select(AppSetting).where(AppSetting.key == "gift_wrap")
    )
    setting = result.scalar_one_or_none()
    if setting is None or not isinstance(setting.value, dict):
        return dict(GIFT_WRAP_DEFAULT)
    try:
        price = float(setting.value.get("price", GIFT_WRAP_DEFAULT["price"]))
    except (TypeError, ValueError):
        price = float(GIFT_WRAP_DEFAULT["price"])
    return {
        "price": max(0.0, price),
        "enabled": bool(setting.value.get("enabled", True)),
    }


async def resolve_gift_wrap_charge(
    db: AsyncSession, gift_wrap: bool
) -> float:
    """Server-authoritative gift-wrap fee. Raises 400 if unavailable."""
    if not gift_wrap:
        return 0.0
    config = await get_gift_wrap_config(db)
    if not config["enabled"]:
        raise HTTPException(status_code=400, detail="Gift wrap is currently unavailable")
    return config["price"]


async def _get_delivery_options(db: AsyncSession) -> list[DeliveryOption]:
    result = await db.execute(
        select(DeliverySetting)
        .where(DeliverySetting.is_active.is_(True))
        .order_by(DeliverySetting.price)
    )
    settings = result.scalars().all()
    return [
        DeliveryOption(
            type=s.type,
            label=s.label,
            price=s.price,
            days=s.days_label,
        )
        for s in settings
    ]


async def calculate_cart(
    db: AsyncSession,
    payload: CartCalculateRequest,
    *,
    user_id: str,
) -> CartCalculateResponse:
    """
    Server-side cart price calculation.
    - Fetches current product prices from DB (prevents client-side tampering).
    - Fetches delivery options from DB (admin-controlled prices).
    - Validates coupon if provided.
    - Returns itemised totals, delivery options, and final total.
    """
    delivery_options = await _get_delivery_options(db)
    delivery_charges: dict[str, float] = {opt.type: opt.price for opt in delivery_options}
    if payload.delivery_type not in delivery_charges:
        raise HTTPException(status_code=400, detail="Invalid delivery type")

    if not payload.items:
        return CartCalculateResponse(
            items=[],
            subtotal=0,
            delivery_charge=0,
            gift_wrap_charge=0,
            discount=0,
            total=0,
            coupon_applied=False,
            delivery_options=delivery_options,
        )

    # Fetch products from DB
    product_ids = [i.product_id for i in payload.items]
    result = await db.execute(
        select(Product).where(Product.id.in_(product_ids), Product.is_active.is_(True))
    )
    products_by_id: dict[str, Product] = {p.id: p for p in result.scalars().all()}

    item_results: list[CartItemResult] = []
    subtotal = 0.0

    for item in payload.items:
        product = products_by_id.get(item.product_id)
        if product is None:
            continue  # skip unavailable products
        if not product.is_orderable:
            raise HTTPException(
                status_code=400,
                detail=f"{product.name} is not available to order yet",
            )

        # Check if a size-specific price exists
        unit_price = product.base_price
        if product.sizes:
            unit_price = None
            for size_opt in product.sizes:
                if size_opt.get("label") == item.size:
                    unit_price = float(size_opt["price"])
                    break
            if unit_price is None:
                raise HTTPException(
                    status_code=400,
                    detail=f"Invalid size for {product.name}",
                )
        if unit_price <= 0:
            raise HTTPException(
                status_code=400,
                detail=f"Price is unavailable for {product.name}",
            )

        line_total = unit_price * item.qty
        subtotal += line_total
        item_results.append(
            CartItemResult(
                product_id=item.product_id,
                name=product.name,
                size=item.size,
                qty=item.qty,
                unit_price=unit_price,
                line_total=line_total,
                image_url=item.image_url,
            )
        )

    delivery_charge = delivery_charges.get(payload.delivery_type, 0)

    # Order-level gift wrap: flat server-side fee, never client-supplied.
    gift_wrap_charge = await resolve_gift_wrap_charge(db, payload.gift_wrap)

    # Coupon validation
    discount = 0.0
    coupon_applied = False

    if payload.coupon_code:
        coupon_result = await db.execute(
            select(Coupon).where(
                Coupon.code == payload.coupon_code.upper(),
                Coupon.is_active.is_(True),
                or_(Coupon.owner_user_id.is_(None), Coupon.owner_user_id == user_id),
            )
        )
        coupon = coupon_result.scalar_one_or_none()

        if coupon:
            now = datetime.now(timezone.utc)
            expired = coupon.expires_at and coupon.expires_at < now
            exhausted = coupon.max_uses and coupon.used_count >= coupon.max_uses
            min_met = subtotal >= coupon.min_order

            if not expired and not exhausted and min_met:
                if coupon.discount_type == "percent":
                    discount = round(subtotal * coupon.value / 100, 2)
                else:
                    discount = min(coupon.value, subtotal)
                coupon_applied = True

    total = max(0.0, subtotal + delivery_charge + gift_wrap_charge - discount)

    return CartCalculateResponse(
        items=item_results,
        subtotal=round(subtotal, 2),
        delivery_charge=delivery_charge,
        gift_wrap_charge=round(gift_wrap_charge, 2),
        discount=round(discount, 2),
        total=round(total, 2),
        coupon_applied=coupon_applied,
        delivery_options=delivery_options,
    )
