import uuid
from datetime import date, datetime, timezone

from sqlalchemy import Boolean, Date, DateTime, Float, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class Product(Base):
    __tablename__ = "products"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    name: Mapped[str] = mapped_column(String)
    category: Mapped[str] = mapped_column(String, index=True)
    category_id: Mapped[str | None] = mapped_column(
        String, ForeignKey("categories.id"), nullable=True, index=True
    )
    base_price: Mapped[float] = mapped_column(Float)
    # JSON: [{"label": "4x6", "price": 10.0}, ...]
    sizes: Mapped[list] = mapped_column(JSON, default=list)
    # JSON: ["https://...", ...] — first entry is the primary/cover image
    images: Mapped[list] = mapped_column(JSON, default=list)
    description: Mapped[str | None] = mapped_column(String, nullable=True)
    material: Mapped[str | None] = mapped_column(Text, nullable=True)
    dimensions: Mapped[str | None] = mapped_column(Text, nullable=True)
    options_summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    delivery_info: Mapped[str | None] = mapped_column(Text, nullable=True)
    price_note: Mapped[str | None] = mapped_column(Text, nullable=True)
    source_url: Mapped[str | None] = mapped_column(String(2048), nullable=True)
    source_checked_on: Mapped[date | None] = mapped_column(Date, nullable=True)
    source_rating: Mapped[float | None] = mapped_column(Float, nullable=True)
    source_review_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    stock_quantity: Mapped[int] = mapped_column(Integer, default=0)
    tracks_inventory: Mapped[bool] = mapped_column(Boolean, default=False)
    # Amazon-parity merchandising: seller SKU, strike-through MRP
    # (compare_at_price is display-only — orders always use base_price/sizes),
    # and an editorial bestseller flag for badges.
    sku: Mapped[str | None] = mapped_column(String(64), nullable=True, unique=True)
    compare_at_price: Mapped[float | None] = mapped_column(Float, nullable=True)
    is_bestseller: Mapped[bool] = mapped_column(Boolean, default=False)
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False)
    is_trending: Mapped[bool] = mapped_column(Boolean, default=False)
    is_orderable: Mapped[bool] = mapped_column(Boolean, default=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    order_items: Mapped[list["OrderItem"]] = relationship(back_populates="product")  # noqa: F821
