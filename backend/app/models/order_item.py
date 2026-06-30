import uuid

from sqlalchemy import Float, ForeignKey, Integer, JSON, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class OrderItem(Base):
    __tablename__ = "order_items"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    order_id: Mapped[str] = mapped_column(String, ForeignKey("orders.id"))
    product_id: Mapped[str] = mapped_column(String, ForeignKey("products.id"))
    quantity: Mapped[int] = mapped_column(Integer, default=1)
    selected_size: Mapped[str] = mapped_column(String, default="")
    unit_price: Mapped[float] = mapped_column(Float)
    image_url: Mapped[str | None] = mapped_column(String, nullable=True)
    # JSON: {"size": "4x6", "paper": "glossy", ...}
    customization_data: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    order: Mapped["Order"] = relationship(back_populates="items")  # noqa: F821
    product: Mapped["Product"] = relationship(back_populates="order_items")  # noqa: F821
