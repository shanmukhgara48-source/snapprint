from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..models import Banner
from ..schemas.banner import BannerOut

router = APIRouter(prefix="/banners", tags=["banners"])


@router.get("", response_model=list[BannerOut])
async def list_banners(
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[Banner]:
    now = datetime.now(timezone.utc)
    result = await db.execute(
        select(Banner)
        .where(
            Banner.is_active.is_(True),
            or_(Banner.starts_at.is_(None), Banner.starts_at <= now),
            or_(Banner.ends_at.is_(None), Banner.ends_at >= now),
        )
        .order_by(Banner.sort_order)
    )
    return list(result.scalars().all())
