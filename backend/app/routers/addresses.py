from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..dependencies import require_customer
from ..models import Address, Order, User
from ..schemas.address import AddressCreate, AddressOut

router = APIRouter(prefix="/addresses", tags=["addresses"])

MAX_ADDRESSES = 5


@router.get("", response_model=list[AddressOut])
async def list_addresses(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> list[Address]:
    result = await db.execute(
        select(Address).where(Address.user_id == user.id)
    )
    return list(result.scalars().all())


@router.post("", response_model=AddressOut, status_code=201)
async def create_address(
    payload: AddressCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> Address:
    count_result = await db.execute(
        select(Address).where(Address.user_id == user.id)
    )
    if len(count_result.scalars().all()) >= MAX_ADDRESSES:
        raise HTTPException(
            status_code=400,
            detail=f"Maximum {MAX_ADDRESSES} addresses allowed",
        )

    # If setting as default, unset others
    if payload.is_default:
        await db.execute(
            update(Address)
            .where(Address.user_id == user.id)
            .values(is_default=False)
        )

    address = Address(user_id=user.id, **payload.model_dump())
    db.add(address)
    await db.commit()
    await db.refresh(address)
    return address


@router.put("/{address_id}", response_model=AddressOut)
async def update_address(
    address_id: str,
    payload: AddressCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> Address:
    result = await db.execute(
        select(Address).where(Address.id == address_id, Address.user_id == user.id)
    )
    address = result.scalar_one_or_none()
    if address is None:
        raise HTTPException(status_code=404, detail="Address not found")

    if payload.is_default:
        await db.execute(
            update(Address)
            .where(Address.user_id == user.id)
            .values(is_default=False)
        )

    for field, value in payload.model_dump().items():
        setattr(address, field, value)

    await db.commit()
    await db.refresh(address)
    return address


@router.delete("/{address_id}", status_code=204)
async def delete_address(
    address_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> None:
    result = await db.execute(
        select(Address).where(Address.id == address_id, Address.user_id == user.id)
    )
    address = result.scalar_one_or_none()
    if address is None:
        raise HTTPException(status_code=404, detail="Address not found")

    order_check = await db.execute(
        select(Order.id).where(Order.address_id == address_id).limit(1)
    )
    if order_check.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=409,
            detail="Address used in past orders — cannot delete",
        )

    await db.delete(address)
    await db.commit()


@router.put("/{address_id}/default", response_model=AddressOut)
async def set_default_address(
    address_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> Address:
    await db.execute(
        update(Address).where(Address.user_id == user.id).values(is_default=False)
    )
    result = await db.execute(
        select(Address).where(Address.id == address_id, Address.user_id == user.id)
    )
    address = result.scalar_one_or_none()
    if address is None:
        raise HTTPException(status_code=404, detail="Address not found")
    address.is_default = True
    await db.commit()
    await db.refresh(address)
    return address
