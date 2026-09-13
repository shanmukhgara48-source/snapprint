from datetime import datetime

from pydantic import BaseModel, Field


class ReviewCreate(BaseModel):
    rating: int = Field(ge=1, le=5)
    title: str = Field(default="", max_length=120)
    body: str = Field(default="", max_length=2000)


class ReviewUpdate(BaseModel):
    rating: int | None = Field(default=None, ge=1, le=5)
    title: str | None = Field(default=None, max_length=120)
    body: str | None = Field(default=None, max_length=2000)


class ReviewOut(BaseModel):
    id: str
    product_id: str
    rating: int
    title: str
    body: str
    reviewer: str
    verified_purchase: bool
    helpful_count: int
    voted: bool = False
    seller_response: str | None = None
    status: str = "published"
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class ReviewSummary(BaseModel):
    product_id: str
    avg_rating: float
    review_count: int
    histogram: dict[int, int]


class RatingsBatchRequest(BaseModel):
    ids: list[str] = Field(min_length=1, max_length=100)


class HelpfulOut(BaseModel):
    id: str
    helpful_count: int
    voted: bool


class AdminReviewOut(ReviewOut):
    user_id: str
    order_id: str | None = None
    product_name: str | None = None


class AdminReviewUpdate(BaseModel):
    status: str | None = Field(default=None, max_length=32)
    seller_response: str | None = Field(default=None, max_length=2000)
