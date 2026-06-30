import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    firebase_uid: Mapped[str] = mapped_column(String, unique=True, index=True)
    phone: Mapped[str] = mapped_column(String, unique=True, index=True)
    role: Mapped[str] = mapped_column(String, default="customer")  # customer | delivery | admin
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    fcm_token: Mapped[str | None] = mapped_column(String, nullable=True)
    referral_code: Mapped[str | None] = mapped_column(String, unique=True, nullable=True)
    referred_by_id: Mapped[str | None] = mapped_column(String, nullable=True)  # id of user who referred
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    addresses: Mapped[list["Address"]] = relationship(back_populates="user", cascade="all, delete-orphan")  # noqa: F821
    orders: Mapped[list["Order"]] = relationship(back_populates="customer", cascade="all, delete-orphan", foreign_keys="Order.user_id")  # noqa: F821
