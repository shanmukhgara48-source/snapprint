from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..dependencies import require_customer
from ..models import Order, ReturnRequest, User
from ..schemas.returns import OPEN_RETURN_STATUSES, RETURNABLE_STATUSES, ReturnCreate, ReturnOut
from ..services.event_bus import emit_event

router = APIRouter(prefix="/returns", tags=["returns"])


def _to_out(req: ReturnRequest, order: Order | None) -> ReturnOut:
    return ReturnOut(
        id=req.id,
        order_id=req.order_id,
        reason=req.reason,
        details=req.details,
        status=req.status,
        admin_note=req.admin_note,
        order_status=order.status if order else None,
        order_total=order.total_price if order else None,
        created_at=req.created_at,
        decided_at=req.decided_at,
    )


@router.post("", response_model=ReturnOut, status_code=201)
async def request_return(
    payload: ReturnCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> ReturnOut:
    order = await db.get(Order, payload.order_id)
    if order is None or order.user_id != user.id:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.status not in RETURNABLE_STATUSES:
        raise HTTPException(
            status_code=409,
            detail=f"Orders with status {order.status!r} cannot be returned",
        )
    open_result = await db.execute(
        select(ReturnRequest).where(
            ReturnRequest.order_id == order.id,
            ReturnRequest.status.in_(OPEN_RETURN_STATUSES),
        )
    )
    if open_result.scalar_one_or_none() is not None:
        raise HTTPException(status_code=409, detail="A return is already open for this order")
    req = ReturnRequest(
        order_id=order.id,
        user_id=user.id,
        reason=payload.reason,
        details=payload.details,
    )
    db.add(req)
    await db.commit()
    await db.refresh(req)
    await emit_event(
        "order", "return_requested", order.id,
        {"return_id": req.id, "reason": req.reason},
        user_id=user.id,
    )
    return _to_out(req, order)


@router.get("/me", response_model=list[ReturnOut])
async def my_returns(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> list[ReturnOut]:
    result = await db.execute(
        select(ReturnRequest, Order)
        .join(Order, Order.id == ReturnRequest.order_id)
        .where(ReturnRequest.user_id == user.id)
        .order_by(ReturnRequest.created_at.desc())
    )
    return [_to_out(req, order) for req, order in result.all()]
