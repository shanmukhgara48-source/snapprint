import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Index, String, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class Order(Base):
    __tablename__ = "orders"
    __table_args__ = (
        Index(
            "uq_orders_razorpay_order_id",
            "razorpay_order_id",
            unique=True,
            postgresql_where=text("razorpay_order_id IS NOT NULL"),
        ),
        Index(
            "uq_orders_razorpay_payment_id",
            "razorpay_payment_id",
            unique=True,
            postgresql_where=text("razorpay_payment_id IS NOT NULL"),
        ),
    )

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"))
    address_id: Mapped[str | None] = mapped_column(
        String, ForeignKey("addresses.id", ondelete="SET NULL"), nullable=True
    )
    delivery_address_snapshot: Mapped[str | None] = mapped_column(String, nullable=True)
    delivery_city_snapshot: Mapped[str | None] = mapped_column(String, nullable=True)
    delivery_pincode_snapshot: Mapped[str | None] = mapped_column(String, nullable=True)
    delivery_partner_id: Mapped[str | None] = mapped_column(
        String, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    status: Mapped[str] = mapped_column(String, default="pending")
    # Purchase channel: "mobile_app" | "website" | "admin" | "unknown".
    # Set at order creation from payload.source / X-Client-Source header.
    # Shared stock still decrements centrally regardless of channel.
    source: Mapped[str] = mapped_column(String, default="unknown", server_default="unknown")
    # Order-level gift wrap (Amazon-style): flat fee + optional message.
    # Fee is server-authoritative (AppSetting "gift_wrap"), never trusted
    # from the client.
    gift_wrap: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    gift_wrap_charge: Mapped[float] = mapped_column(Float, default=0)
    gift_message: Mapped[str | None] = mapped_column(String(500), nullable=True)
    total_price: Mapped[float] = mapped_column(Float)
    delivery_type: Mapped[str] = mapped_column(String, default="free")
    delivery_charge: Mapped[float] = mapped_column(Float, default=0)
    discount: Mapped[float] = mapped_column(Float, default=0)
    coupon_code: Mapped[str | None] = mapped_column(String, nullable=True)
    razorpay_order_id: Mapped[str | None] = mapped_column(
        String, nullable=True
    )
    razorpay_payment_id: Mapped[str | None] = mapped_column(
        String, nullable=True
    )
    razorpay_refund_id: Mapped[str | None] = mapped_column(String, nullable=True)
    refund_status: Mapped[str | None] = mapped_column(String, nullable=True)
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
