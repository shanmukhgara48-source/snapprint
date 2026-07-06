from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..database import get_db
from ..dependencies import require_delivery
from ..models import Address, DeliveryTracking, Order, User
from ..schemas.delivery import DeliveryOrderOut, DeliveryStatusUpdate
from ..services.event_bus import emit_event
from ..services.firebase_service import (
    notify_delivered,
    notify_out_for_delivery,
    notify_order_confirmed,
)

router = APIRouter(prefix="/delivery", tags=["delivery"])

VALID_STATUS_TRANSITIONS = {
    "confirmed": "picked_up",
    "picked_up": "out_for_delivery",
    "out_for_delivery": "delivered",
}


def _to_delivery_out(order: Order) -> DeliveryOrderOut:
    address = order.address
    return DeliveryOrderOut(
        id=order.id,
        status=order.status,
        customer_phone=order.customer.phone if order.customer else "",
        pickup_address="SnapPrint Fulfillment Center, Mumbai",  # replace with actual
        delivery_address=address.full_address if address else "",
        delivery_city=address.city if address else "",
        delivery_pincode=address.pincode if address else "",
        total_price=order.total_price,
        item_count=len(order.items),
        proof_url=order.tracking_events[-1].proof_url
        if order.tracking_events
        else None,
    )


@router.get("/assigned", response_model=list[DeliveryOrderOut])
async def get_assigned_orders(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_delivery)],
) -> list[DeliveryOrderOut]:
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.items),
            selectinload(Order.address),
            selectinload(Order.tracking_events),
            selectinload(Order.customer),
        )
        .where(Order.delivery_partner_id == user.id)
        .order_by(Order.created_at.desc())
    )
    orders = result.scalars().all()
    return [_to_delivery_out(o) for o in orders]


@router.patch("/{order_id}/status", response_model=DeliveryOrderOut)
async def update_delivery_status(
    order_id: str,
    payload: DeliveryStatusUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_delivery)],
) -> DeliveryOrderOut:
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.items),
            selectinload(Order.address),
            selectinload(Order.tracking_events),
            selectinload(Order.customer),
        )
        .where(Order.id == order_id, Order.delivery_partner_id == user.id)
    )
    order = result.scalar_one_or_none()
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")

    expected_next = VALID_STATUS_TRANSITIONS.get(order.status)
    if payload.status != expected_next and payload.status != "delivered":
        raise HTTPException(
            status_code=400,
            detail=f"Cannot transition from {order.status!r} to {payload.status!r}",
        )

    order.status = payload.status
    tracking = DeliveryTracking(
        order_id=order.id,
        status=payload.status,
        proof_url=payload.proof_url,
    )
    db.add(tracking)
    await db.commit()
    await db.refresh(order)

    # Live update: customer's open Orders/Order Detail screens + admin panel
    await emit_event(
        "order", "status_changed", order.id,
        {"status": order.status},
        user_id=order.user_id,
    )

    # Send FCM to customer
    customer_token = order.customer.fcm_token if order.customer else None
    if customer_token:
        try:
            if payload.status == "out_for_delivery":
                notify_out_for_delivery(customer_token, order.id)
            elif payload.status == "delivered":
                notify_delivered(customer_token, order.id)
            elif payload.status == "picked_up":
                notify_order_confirmed(customer_token, order.id)
        except Exception:
            pass

    return _to_delivery_out(order)
