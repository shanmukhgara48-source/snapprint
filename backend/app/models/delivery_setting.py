from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Float, String
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class DeliverySetting(Base):
    """
    Admin-controlled delivery option pricing.
    There are exactly 3 rows (free / standard / express) seeded on startup.
    Admin can update price, label, and days_label via the admin panel.
    """

    __tablename__ = "delivery_settings"

    type: Mapped[str] = mapped_column(String, primary_key=True)   # free | standard | express
    label: Mapped[str] = mapped_column(String)
    price: Mapped[float] = mapped_column(Float)
    days_label: Mapped[str] = mapped_column(String)               # e.g. "5-7 business days"
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )
