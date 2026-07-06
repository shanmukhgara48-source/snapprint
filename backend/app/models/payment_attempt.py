import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class PaymentAttempt(Base):
    """
    Logged on every Razorpay verify call (success or failure) so failed/pending
    payments are visible to admins — Order rows only exist after a successful
    verify, so without this table failed payments are invisible.
    """

    __tablename__ = "payment_attempts"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    razorpay_order_id: Mapped[str] = mapped_column(String, index=True)
    razorpay_payment_id: Mapped[str | None] = mapped_column(String, nullable=True)
    status: Mapped[str] = mapped_column(String)  # success | failed
    reason: Mapped[str | None] = mapped_column(String, nullable=True)
    user_id: Mapped[str | None] = mapped_column(String, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
