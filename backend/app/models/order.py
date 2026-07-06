import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"))
    address_id: Mapped[str | None] = mapped_column(
        String, ForeignKey("addresses.id"), nullable=True
    )
    delivery_partner_id: Mapped[str | None] = mapped_column(
        String, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    status: Mapped[str] = mapped_column(String, default="pending")
    total_price: Mapped[float] = mapped_column(Float)
    delivery_type: Mapped[str] = mapped_column(String, default="free")
    delivery_charge: Mapped[float] = mapped_column(Float, default=0)
    discount: Mapped[float] = mapped_column(Float, default=0)
    coupon_code: Mapped[str | None] = mapped_column(String, nullable=True)
    razorpay_order_id: Mapped[str | None] = mapped_column(String, nullable=True)
    razorpay_payment_id: Mapped[str | None] = mapped_column(String, nullable=True)
    notes: Mapped[str | None] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    estimated_delivery: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    customer: Mapped["User"] = relationship(back_populates="orders", foreign_keys=[user_id])  # noqa: F821
    address: Mapped["Address"] = relationship()  # noqa: F821
    items: Mapped[list["OrderItem"]] = relationship(back_populates="order", cascade="all, delete-orphan")  # noqa: F821
    tracking_events: Mapped[list["DeliveryTracking"]] = relationship(back_populates="order", cascade="all, delete-orphan")  # noqa: F821
