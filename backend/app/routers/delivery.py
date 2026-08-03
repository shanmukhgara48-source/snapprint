import asyncio
import logging
import uuid
from pathlib import PurePosixPath
from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile
from PIL import Image
from pydantic import BaseModel
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..database import get_db
from ..config import settings
from ..dependencies import require_delivery
from ..models import DeliveryTracking, Order, User
from ..schemas.delivery import DeliveryOrderOut, DeliveryStatusUpdate
from ..services.event_bus import emit_event
from ..services.firebase_service import (
    notify_delivered,
    notify_out_for_delivery,
)
from ..services.order_status import validate_order_status_transition
from ..services.r2_storage import (
    build_media_url,
    hosted_media_key,
    media_base_url,
    r2_client,
)

router = APIRouter(prefix="/delivery", tags=["delivery"])
limiter = Limiter(key_func=get_remote_address)
logger = logging.getLogger(__name__)

_PROOF_TYPES = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"}
_PROOF_FORMATS = {"image/jpeg": "JPEG", "image/png": "PNG", "image/webp": "WEBP"}
_MAX_PROOF_BYTES = 10 * 1024 * 1024
_MAX_PROOF_PIXELS = 25_000_000


class DeliveryProofOut(BaseModel):
    proof_url: str


def _to_delivery_out(order: Order) -> DeliveryOrderOut:
    address = order.address
    proof_events = [event for event in order.tracking_events if event.proof_url]
    latest_proof = max(
        proof_events,
        key=lambda event: (event.timestamp, event.id),
        default=None,
    )
    return DeliveryOrderOut(
        id=order.id,
        status=order.status,
        customer_phone=order.customer.phone if order.customer else "",
        pickup_address="SnapPrint Fulfillment Center, Mumbai",  # replace with actual
        delivery_address=order.delivery_address_snapshot
        or (address.full_address if address else ""),
        delivery_city=order.delivery_city_snapshot
        or (address.city if address else ""),
        delivery_pincode=order.delivery_pincode_snapshot
        or (address.pincode if address else ""),
        total_price=order.total_price,
        item_count=len(order.items),
        proof_url=latest_proof.proof_url if latest_proof else None,
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

    changed = validate_order_status_transition(
        order.status,
        payload.status,
        delivery_partner=True,
    )
    if payload.status == "delivered":
        key = hosted_media_key(payload.proof_url or "")
        if key is None or not key.startswith(f"delivery-proofs/{order.id}/"):
            raise HTTPException(400, "A valid delivery proof photo is required.")
        try:
            stored = await asyncio.to_thread(
                r2_client().head_object,
                Bucket=settings.r2_bucket_name,
                Key=key,
            )
        except Exception as exc:
            raise HTTPException(400, "Delivery proof photo was not found.") from exc
        if stored.get("ContentType") not in _PROOF_TYPES:
            raise HTTPException(400, "Delivery proof photo is invalid.")

    if not changed:
        return _to_delivery_out(order)

    order.status = payload.status
    tracking = DeliveryTracking(
        status=payload.status,
        proof_url=payload.proof_url,
    )
    order.tracking_events.append(tracking)
    await db.commit()
    await db.refresh(order)

    # Live update: customer's open Orders/Order Detail screens + admin panel
    await emit_event(
        "order", "status_changed", order.id,
        {"status": order.status},
        user_id=order.user_id,
    )

    # Send FCM to customer. "picked_up" has no customer-facing notification —
    # the "confirmed" one already fired earlier, in admin.py's admin_update_order,
    # when the order first transitioned from pending to confirmed.
    customer_token = order.customer.fcm_token if order.customer else None
    if customer_token:
        try:
            if payload.status == "out_for_delivery":
                notify_out_for_delivery(customer_token, order.id)
            elif payload.status == "delivered":
                notify_delivered(customer_token, order.id)
        except Exception:
            pass

    return _to_delivery_out(order)


@router.post("/{order_id}/proof", response_model=DeliveryProofOut, status_code=201)
@limiter.limit("10/minute")
async def upload_delivery_proof(
    request: Request,
    order_id: str,
    file: Annotated[UploadFile, File(...)],
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_delivery)],
) -> DeliveryProofOut:
    order_result = await db.execute(
        select(Order).where(
            Order.id == order_id,
            Order.delivery_partner_id == user.id,
        )
    )
    order = order_result.scalar_one_or_none()
    if order is None:
        raise HTTPException(404, "Order not found")
    if order.status != "out_for_delivery":
        raise HTTPException(409, "Proof can only be uploaded while out for delivery.")

    content_type = (file.content_type or "").lower()
    if content_type not in _PROOF_TYPES:
        raise HTTPException(415, "Only JPEG, PNG and WebP proof photos are allowed.")
    total = 0
    while chunk := await file.read(1024 * 1024):
        total += len(chunk)
        if total > _MAX_PROOF_BYTES:
            raise HTTPException(413, "Proof photo exceeds the 10 MB limit.")
    if total == 0:
        raise HTTPException(400, "Proof photo is empty.")

    await file.seek(0)
    try:
        with Image.open(file.file) as image:
            image_format = image.format
            width, height = image.size
            image.verify()
    except (OSError, RuntimeError, ValueError) as exc:
        raise HTTPException(400, "Proof photo is corrupt or unsupported.") from exc
    if image_format != _PROOF_FORMATS[content_type]:
        raise HTTPException(400, "Declared image type does not match the proof photo.")
    if width <= 0 or height <= 0 or width * height > _MAX_PROOF_PIXELS:
        raise HTTPException(413, "Proof photo dimensions exceed the limit.")

    extension = _PROOF_TYPES[content_type]
    key = PurePosixPath(
        "delivery-proofs",
        order.id,
        f"{uuid.uuid4()}.{extension}",
    )
    await file.seek(0)
    try:
        await asyncio.to_thread(
            r2_client().upload_fileobj,
            file.file,
            settings.r2_bucket_name,
            str(key),
            ExtraArgs={
                "ContentType": content_type,
                "CacheControl": "private, max-age=31536000, immutable",
            },
        )
    except Exception as exc:
        logger.exception("Failed to store delivery proof")
        raise HTTPException(502, "Could not store delivery proof.") from exc
    return DeliveryProofOut(
        proof_url=build_media_url(
            media_base_url(str(request.base_url)),
            str(key),
            signed=True,
        )
    )
