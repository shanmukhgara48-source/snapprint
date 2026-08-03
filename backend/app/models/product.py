import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, JSON, String
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
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    stock_quantity: Mapped[int] = mapped_column(Integer, default=0)
    tracks_inventory: Mapped[bool] = mapped_column(Boolean, default=False)
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False)
    is_trending: Mapped[bool] = mapped_column(Boolean, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    order_items: Mapped[list["OrderItem"]] = relationship(back_populates="product")  # noqa: F821
