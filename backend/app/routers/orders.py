import re
from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..database import get_db
from ..dependencies import require_customer
from ..models import (
    Address,
    Coupon,
    DeliveryTracking,
    Order,
    OrderItem,
    PaymentIntent,
    Product,
    User,
)
from ..models.delivery_setting import DeliverySetting
from ..schemas.order import OrderCreate, OrderOut
from ..schemas.product import ProductOut
from ..services.event_bus import emit_event
from ..services.firebase_service import notify_order_placed
from ..services.payment_service import amount_to_paise
from ..services.r2_storage import owned_media_key

router = APIRouter(prefix="/orders", tags=["orders"])


def _order_to_out(order: Order) -> OrderOut:
    address_str = order.delivery_address_snapshot
    if address_str and order.delivery_city_snapshot and order.delivery_pincode_snapshot:
        address_str = (
            f"{address_str}, {order.delivery_city_snapshot} - "
            f"{order.delivery_pincode_snapshot}"
        )
    elif order.address:
        a = order.address
        address_str = f"{a.full_address}, {a.city} - {a.pincode}"

    return OrderOut(
        id=order.id,
        total_price=order.total_price,
        status=order.status,
        created_at=order.created_at,
        item_count=len(order.items),
        delivery_address=address_str,
        estimated_delivery=order.estimated_delivery,
        tracking_events=[
            {"status": t.status, "timestamp": t.timestamp}
            for t in order.tracking_events
        ],
    )


@router.post("", response_model=OrderOut, status_code=201)
async def place_order(
    payload: OrderCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> OrderOut:
    # Validate address
    addr_result = await db.execute(
        select(Address).where(
            Address.id == payload.address_id, Address.user_id == user.id
        )
    )
    address = addr_result.scalar_one_or_none()
    if address is None:
        raise HTTPException(status_code=404, detail="Address not found")

    # Fetch delivery charge from DB (admin-controlled)
    setting_result = await db.execute(
        select(DeliverySetting).where(
            DeliverySetting.type == payload.delivery_type,
            DeliverySetting.is_active.is_(True),
        )
    )
    setting = setting_result.scalar_one_or_none()
    if setting is None:
        raise HTTPException(status_code=400, detail="Invalid delivery type")
    delivery_charge = setting.price
    # Estimate from the admin-set label (e.g. "1-2 business days" -> 2 days)
    # rather than a flat number, so an express order isn't quoted the same
    # ETA as a free one. Falls back to 5 days if the label has no digits.
    estimated_days = 5
    if setting and setting.days_label:
        day_numbers = [int(n) for n in re.findall(r"\d+", setting.days_label)]
        if day_numbers:
            estimated_days = max(day_numbers)

    # Verify item prices server-side — never trust client-supplied prices.
    # Row-locked so concurrent orders can't oversell tracked stock.
    product_ids = [item.product_id for item in payload.items]
    products_result = await db.execute(
        select(Product)
        .where(Product.id.in_(product_ids), Product.is_active.is_(True))
        .with_for_update()
    )
    products_by_id: dict[str, Product] = {p.id: p for p in products_result.scalars().all()}

    items_total = 0.0
    verified_item_prices: dict[tuple[str, str], float] = {}
    for item in payload.items:
        if item.image_url and owned_media_key(item.image_url, str(user.id)) is None:
            raise HTTPException(
                status_code=403,
                detail="Order artwork must be an image uploaded by this account.",
            )
        product = products_by_id.get(item.product_id)
        if product is None:
            raise HTTPException(status_code=400, detail=f"Product {item.product_id} not found or inactive")
        # Find the authoritative price for the requested size
        server_price: float | None = product.base_price
        if product.sizes:
            server_price = None
            for size_entry in product.sizes:
                if isinstance(size_entry, dict) and size_entry.get("label") == item.size:
                    server_price = float(size_entry["price"])
                    break
        if server_price is None:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid size for {product.name}",
            )
        if server_price <= 0:
            raise HTTPException(
                status_code=400,
                detail=f"Price is unavailable for {product.name}",
            )
        verified_item_prices[(item.product_id, item.size)] = server_price
        items_total += server_price * item.qty

    # Validate stock now, but defer the mutation until payment validation has
    # completed. This keeps idempotent payment retries free of inventory writes.
    qty_by_product: dict[str, int] = {}
    for item in payload.items:
        qty_by_product[item.product_id] = qty_by_product.get(item.product_id, 0) + item.qty
    for pid, qty in qty_by_product.items():
        product = products_by_id[pid]
        if product.tracks_inventory:
            if qty > product.stock_quantity:
                raise HTTPException(
                    status_code=409,
                    detail=f"Only {product.stock_quantity} left in stock for {product.name}",
                )

    # Apply coupon discount if provided
    discount = 0.0
    applied_coupon: Coupon | None = None
    if payload.coupon_code:
        coupon_result = await db.execute(
            select(Coupon)
            .where(
                Coupon.code == payload.coupon_code.upper(),
                Coupon.is_active.is_(True),
                or_(Coupon.owner_user_id.is_(None), Coupon.owner_user_id == user.id),
            )
            .with_for_update()
        )
        coupon = coupon_result.scalar_one_or_none()
        if coupon:
            now = datetime.now(timezone.utc)
            expired = coupon.expires_at and coupon.expires_at < now
            exhausted = coupon.max_uses and coupon.used_count >= coupon.max_uses
            if not expired and not exhausted and items_total >= coupon.min_order:
                if coupon.discount_type == "percent":
                    discount = round(items_total * coupon.value / 100, 2)
                else:
                    discount = min(coupon.value, items_total)
                applied_coupon = coupon

    total = max(0.0, items_total + delivery_charge - discount)

    # Payment is mandatory whenever there's actually something to pay for.
    # razorpay_* fields are optional in the schema only so a 100%-coupon
    # order (total == 0) can skip Razorpay entirely — for any nonzero total,
    # all three must be present and verified, otherwise a customer could get
    # a fully confirmed order (stock decremented, coupon consumed) for free
    # simply by omitting them.
    if round(total, 2) > 0:
        if not (
            payload.razorpay_payment_id
            and payload.razorpay_order_id
            and payload.razorpay_signature
        ):
            raise HTTPException(status_code=402, detail="Payment is required for this order")
        intent_result = await db.execute(
            select(PaymentIntent)
            .where(
                PaymentIntent.razorpay_order_id == payload.razorpay_order_id,
                PaymentIntent.user_id == user.id,
            )
            .with_for_update()
        )
        payment_intent = intent_result.scalar_one_or_none()
        if payment_intent is not None and payment_intent.status == "consumed":
            if (
                payment_intent.razorpay_payment_id == payload.razorpay_payment_id
                and payment_intent.consumed_order_id
            ):
                existing_result = await db.execute(
                    select(Order)
                    .options(
                        selectinload(Order.items),
                        selectinload(Order.tracking_events),
                        selectinload(Order.address),
                    )
                    .where(
                        Order.id == payment_intent.consumed_order_id,
                        Order.user_id == user.id,
                    )
                )
                existing_order = existing_result.scalar_one_or_none()
                if existing_order is not None:
                    return _order_to_out(existing_order)
            raise HTTPException(status_code=409, detail="Payment has already been used")
        if (
            payment_intent is None
            or payment_intent.status != "verified"
            or payment_intent.razorpay_payment_id != payload.razorpay_payment_id
        ):
            raise HTTPException(status_code=400, detail="Payment is not verified")
        if payment_intent.amount_paise != amount_to_paise(round(total, 2)):
            raise HTTPException(
                status_code=400,
                detail="Paid amount does not match order total",
            )
    else:
        payment_intent = None

    stock_changed: list[Product] = []
    for pid, qty in qty_by_product.items():
        product = products_by_id[pid]
        if product.tracks_inventory:
            product.stock_quantity -= qty
            stock_changed.append(product)

    # Create order
    order = Order(
        user_id=user.id,
        address_id=payload.address_id,
        delivery_address_snapshot=address.full_address,
        delivery_city_snapshot=address.city,
        delivery_pincode_snapshot=address.pincode,
        total_price=total,
        discount=discount,
        delivery_type=payload.delivery_type,
        delivery_charge=delivery_charge,
        coupon_code=applied_coupon.code if applied_coupon is not None else None,
        razorpay_order_id=payload.razorpay_order_id,
        razorpay_payment_id=payload.razorpay_payment_id,
        status="confirmed",
        estimated_delivery=datetime.now(timezone.utc) + timedelta(days=estimated_days),
    )
    db.add(order)
    await db.flush()
    if payment_intent is not None:
        payment_intent.status = "consumed"
        payment_intent.consumed_order_id = order.id

    # Create order items using server-verified prices
    for item_data in payload.items:
        server_price = verified_item_prices[(item_data.product_id, item_data.size)]
        item = OrderItem(
            order_id=order.id,
            product_id=item_data.product_id,
            quantity=item_data.qty,
            selected_size=item_data.size,
            unit_price=server_price,
            image_url=item_data.image_url,
        )
        db.add(item)

    # Initial tracking event
    db.add(DeliveryTracking(order_id=order.id, status="confirmed"))

    if applied_coupon is not None:
        applied_coupon.used_count += 1

    await db.commit()

    # Reload with relationships
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.items),
            selectinload(Order.tracking_events),
            selectinload(Order.address),
        )
        .where(Order.id == order.id)
    )
    order = result.scalar_one()

    # Live update: user's other devices + admin panel (orders list, dashboard)
    await emit_event(
        "order", "created", order.id,
        {"status": order.status, "total_price": order.total_price},
        user_id=user.id,
    )
    # Broadcast new stock levels for tracked products (listings + admin panel)
    for product in stock_changed:
        await emit_event(
            "product", "updated", product.id,
            ProductOut.model_validate(product).model_dump(mode="json"),
        )

    # Send FCM notification
    if user.fcm_token:
        try:
            notify_order_placed(user.fcm_token, order.id)
        except Exception:
            pass  # Non-critical

    return _order_to_out(order)


@router.get("/me", response_model=list[OrderOut])
async def my_orders(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> list[OrderOut]:
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.items),
            selectinload(Order.tracking_events),
            selectinload(Order.address),
        )
        .where(Order.user_id == user.id)
        .order_by(Order.created_at.desc())
    )
    orders = result.scalars().all()
    return [_order_to_out(o) for o in orders]


@router.get("/{order_id}", response_model=OrderOut)
async def get_order(
    order_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> OrderOut:
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.items),
            selectinload(Order.tracking_events),
            selectinload(Order.address),
        )
        .where(Order.id == order_id, Order.user_id == user.id)
    )
    order = result.scalar_one_or_none()
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    return _order_to_out(order)
