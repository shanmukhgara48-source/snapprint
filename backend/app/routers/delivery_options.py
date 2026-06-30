from fastapi import APIRouter
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Depends
from typing import Annotated
from pydantic import BaseModel

from ..database import get_db
from ..models.delivery_setting import DeliverySetting

router = APIRouter(prefix="/delivery-options", tags=["delivery-options"])


class DeliveryOptionOut(BaseModel):
    type: str
    label: str
    price: float
    days_label: str

    model_config = {"from_attributes": True}


@router.get("", response_model=list[DeliveryOptionOut])
async def get_delivery_options(
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[DeliverySetting]:
    """Public endpoint — returns active delivery options with current prices."""
    result = await db.execute(
        select(DeliverySetting)
        .where(DeliverySetting.is_active.is_(True))
        .order_by(DeliverySetting.price)
    )
    return list(result.scalars().all())
