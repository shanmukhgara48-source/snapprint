from datetime import datetime, timezone
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..dependencies import require_customer
from ..models import Order, OrderItem, Product, Review, ReviewVote, User
from ..models.review import _mask_phone
from ..schemas.product import ProductOut
from ..schemas.review import (
    HelpfulOut,
    RatingsBatchRequest,
    ReviewCreate,
    ReviewOut,
    ReviewSummary,
    ReviewUpdate,
)
from ..services.event_bus import emit_event

router = APIRouter(tags=["reviews"])


def _to_out(review: Review, phone: str | None, voted: bool = False) -> ReviewOut:
    return ReviewOut(
        id=review.id,
        product_id=review.product_id,
        rating=review.rating,
        title=review.title,
        body=review.body,
        reviewer=_mask_phone(phone),
        verified_purchase=review.verified_purchase,
        helpful_count=review.helpful_count,
        voted=voted,
        seller_response=review.seller_response,
        status=review.status,
        created_at=review.created_at,
        updated_at=review.updated_at,
    )


async def _voted_ids(db: AsyncSession, user_id: str, review_ids: list[str]) -> set[str]:
    if not review_ids:
        return set()
    result = await db.execute(
        select(ReviewVote.review_id).where(
            ReviewVote.user_id == user_id, ReviewVote.review_id.in_(review_ids)
        )
    )
    return set(result.scalars().all())


@router.get("/products/{product_id}/reviews/summary", response_model=ReviewSummary)
async def review_summary(
    product_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ReviewSummary:
    agg = await db.execute(
        select(func.count(Review.id), func.coalesce(func.avg(Review.rating), 0)).where(
            Review.product_id == product_id, Review.status == "published"
        )
    )
    count, avg = agg.one()
    hist_result = await db.execute(
        select(Review.rating, func.count(Review.id))
        .where(Review.product_id == product_id, Review.status == "published")
        .group_by(Review.rating)
    )
    histogram = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
    for rating, n in hist_result.all():
        histogram[int(rating)] = int(n)
    return ReviewSummary(
        product_id=product_id,
        avg_rating=round(float(avg), 1),
        review_count=int(count),
        histogram=histogram,
    )


@router.get("/products/{product_id}/reviews", response_model=list[ReviewOut])
async def list_reviews(
    product_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    sort: Literal["helpful", "recent"] = Query("helpful"),
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=50),
) -> list[ReviewOut]:
    query = (
        select(Review, User.phone)
        .join(User, User.id == Review.user_id)
        .where(Review.product_id == product_id, Review.status == "published")
    )
    if sort == "helpful":
        query = query.order_by(Review.helpful_count.desc(), Review.created_at.desc())
    else:
        query = query.order_by(Review.created_at.desc())
    result = await db.execute(query.offset((page - 1) * limit).limit(limit))
    return [_to_out(review, phone) for review, phone in result.all()]


@router.post("/products/ratings")
async def batch_ratings(
    payload: RatingsBatchRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict[str, dict[str, float]]:
    """One-query star aggregates for product cards (avoids N+1)."""
    result = await db.execute(
        select(
            Review.product_id,
            func.count(Review.id),
            func.coalesce(func.avg(Review.rating), 0),
        )
        .where(
            Review.product_id.in_(payload.ids),
            Review.status == "published",
        )
        .group_by(Review.product_id)
    )
    out: dict[str, dict[str, float]] = {pid: {"avg": 0.0, "count": 0} for pid in payload.ids}
    for pid, count, avg in result.all():
        out[pid] = {"avg": round(float(avg), 1), "count": int(count)}
    return out


@router.post("/products/{product_id}/reviews", response_model=ReviewOut, status_code=201)
async def create_review(
    product_id: str,
    payload: ReviewCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> ReviewOut:
    product = await db.get(Product, product_id)
    if product is None or not product.is_active:
        raise HTTPException(status_code=404, detail="Product not found")
    existing = await db.execute(
        select(Review).where(Review.product_id == product_id, Review.user_id == user.id)
    )
    if existing.scalar_one_or_none() is not None:
        raise HTTPException(status_code=409, detail="You have already reviewed this product")
    # Verified purchase: a non-cancelled order containing this product.
    verified_result = await db.execute(
        select(Order.id)
        .join(OrderItem, OrderItem.order_id == Order.id)
        .where(
            Order.user_id == user.id,
            Order.status != "cancelled",
            OrderItem.product_id == product_id,
        )
        .limit(1)
    )
    verified_row = verified_result.first()
    order_result = await db.execute(
        select(Order.id)
        .join(OrderItem, OrderItem.order_id == Order.id)
        .where(Order.user_id == user.id, OrderItem.product_id == product_id)
        .order_by(Order.created_at.desc())
        .limit(1)
    )
    latest_order = order_result.scalar_one_or_none()
    review = Review(
        product_id=product_id,
        user_id=user.id,
        order_id=latest_order,
        rating=payload.rating,
        title=payload.title,
        body=payload.body,
        verified_purchase=verified_row is not None,
    )
    db.add(review)
    await db.commit()
    await db.refresh(review)
    await emit_event(
        "review", "created", product_id,
        {"rating": review.rating, "verified": review.verified_purchase},
    )
    return _to_out(review, user.phone)


@router.patch("/reviews/{review_id}", response_model=ReviewOut)
async def edit_review(
    review_id: str,
    payload: ReviewUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> ReviewOut:
    review = await db.get(Review, review_id)
    if review is None or review.user_id != user.id:
        raise HTTPException(status_code=404, detail="Review not found")
    changes = payload.model_dump(exclude_unset=True)
    for field, value in changes.items():
        setattr(review, field, value)
    await db.commit()
    await db.refresh(review)
    await emit_event("review", "updated", review.product_id, {"rating": review.rating})
    return _to_out(review, user.phone, voted=True)


@router.post("/reviews/{review_id}/helpful", response_model=HelpfulOut)
async def toggle_helpful(
    review_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> HelpfulOut:
    review = await db.get(Review, review_id)
    if review is None or review.status != "published":
        raise HTTPException(status_code=404, detail="Review not found")
    if review.user_id == user.id:
        raise HTTPException(status_code=400, detail="You cannot vote on your own review")
    vote_result = await db.execute(
        select(ReviewVote).where(
            ReviewVote.review_id == review_id, ReviewVote.user_id == user.id
        )
    )
    vote = vote_result.scalar_one_or_none()
    if vote is None:
        db.add(ReviewVote(review_id=review_id, user_id=user.id))
        review.helpful_count += 1
        voted = True
    else:
        await db.delete(vote)
        review.helpful_count = max(0, review.helpful_count - 1)
        voted = False
    await db.commit()
    await db.refresh(review)
    return HelpfulOut(id=review.id, helpful_count=review.helpful_count, voted=voted)


@router.get("/products/{product_id}/bought-together", response_model=list[ProductOut])
async def bought_together(
    product_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    limit: int = Query(4, ge=1, le=10),
) -> list[Product]:
    """Frequently bought together, from real co-purchase history."""
    oi2 = OrderItem.__table__.alias("oi2")
    pairs = await db.execute(
        select(oi2.c.product_id, func.count().label("n"))
        .select_from(OrderItem.__table__.join(oi2, oi2.c.order_id == OrderItem.order_id))
        .join(Order, Order.id == OrderItem.order_id)
        .where(
            OrderItem.product_id == product_id,
            oi2.c.product_id != product_id,
            Order.status != "cancelled",
        )
        .group_by(oi2.c.product_id)
        .order_by(func.count().desc())
        .limit(limit)
    )
    ids = [pid for pid, _ in pairs.all()]
    if not ids:
        return []
    result = await db.execute(
        select(Product).where(Product.id.in_(ids), Product.is_active.is_(True))
    )
    by_id = {p.id: p for p in result.scalars().all()}
    return [by_id[pid] for pid in ids if pid in by_id]


@router.get("/reviews/me", response_model=list[ReviewOut])
async def my_reviews(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(require_customer)],
) -> list[ReviewOut]:
    result = await db.execute(
        select(Review).where(Review.user_id == user.id).order_by(Review.created_at.desc())
    )
    reviews = result.scalars().all()
    voted = await _voted_ids(db, user.id, [r.id for r in reviews])
    return [_to_out(r, user.phone, voted=r.id in voted) for r in reviews]
