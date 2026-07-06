from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..database import get_db
from ..dependencies import require_customer
from ..models import Address, Coupon, DeliveryTracking, Order, OrderItem, Product, User
from ..models.delivery_setting import DeliverySetting
from ..schemas.order import OrderCreate, OrderOut
from ..schemas.product import ProductOut
from ..services.event_bus import emit_event
from ..services.firebase_service import notify_order_placed
from ..services.payment_service import verify_razorpay_signature

router = APIRouter(prefix="/orders", tags=["orders"])


def _order_to_out(order: Order) -> OrderOut:
    address_str = None
    if order.address:
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
    # Verify payment if provided
    if payload.razorpay_payment_id and payload.razorpay_order_id and payload.razorpay_signature:
        ok = verify_razorpay_signature(
            payload.razorpay_order_id,
            payload.razorpay_payment_id,
            payload.razorpay_signature,
        )
        if not ok:
            raise HTTPException(status_code=400, detail="Payment verification failed")

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
        select(DeliverySetting).where(DeliverySetting.type == payload.delivery_type)
    )
    setting = setting_result.scalar_one_or_none()
    delivery_charge = setting.price if setting else 0

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
        product = products_by_id.get(item.product_id)
        if product is None:
            raise HTTPException(status_code=400, detail=f"Product {item.product_id} not found or inactive")
        # Find the authoritative price for the requested size
        server_price: float | None = None
        if item.size:
            for size_entry in product.sizes:
                if isinstance(size_entry, dict) and size_entry.get("label") == item.size:
                    server_price = float(size_entry["price"])
                    break
        if server_price is None:
            server_price = product.base_price
        verified_item_prices[(item.product_id, item.size)] = server_price
        items_total += server_price * item.qty

    # Decrement stock. stock_quantity > 0 means tracked inventory; 0 means
    # untracked/unlimited (legacy products), so it is never enforced.
    qty_by_product: dict[str, int] = {}
    for item in payload.items:
        qty_by_product[item.product_id] = qty_by_product.get(item.product_id, 0) + item.qty
    stock_changed: list[Product] = []
    for pid, qty in qty_by_product.items():
        product = products_by_id[pid]
        if product.stock_quantity > 0:
            if qty > product.stock_quantity:
                raise HTTPException(
                    status_code=409,
                    detail=f"Only {product.stock_quantity} left in stock for {product.name}",
                )
            product.stock_quantity -= qty
            stock_changed.append(product)

    # Apply coupon discount if provided
    discount = 0.0
    applied_coupon: Coupon | None = None
    if payload.coupon_code:
        coupon_result = await db.execute(
            select(Coupon)
            .where(
                Coupon.code == payload.coupon_code.upper(),
                Coupon.is_active.is_(True),
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

    # Create order
    order = Order(
        user_id=user.id,
        address_id=payload.address_id,
        total_price=total,
        discount=discount,
        delivery_type=payload.delivery_type,
        delivery_charge=delivery_charge,
        coupon_code=payload.coupon_code,
        razorpay_payment_id=payload.razorpay_payment_id,
        status="confirmed",
        estimated_delivery=datetime.now(timezone.utc) + timedelta(days=5),
    )
    db.add(order)
    await db.flush()

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
