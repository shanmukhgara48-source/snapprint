from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..dependencies import require_customer
from ..models import User
from ..schemas.cart import CartCalculateRequest, CartCalculateResponse
from ..services.order_service import calculate_cart

router = APIRouter(prefix="/cart", tags=["cart"])


@router.post("/calculate", response_model=CartCalculateResponse)
async def calculate(
    payload: CartCalculateRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> CartCalculateResponse:
    """
    Server-side cart price calculation.
    Always call this before showing the checkout summary — it fetches
    authoritative prices from the DB so client-side totals can't be tampered.
    """
    return await calculate_cart(db, payload, user_id=user.id)
