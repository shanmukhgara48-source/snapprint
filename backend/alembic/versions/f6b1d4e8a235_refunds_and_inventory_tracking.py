"""track payment refunds and explicit product inventory

Revision ID: f6b1d4e8a235
Revises: e5a0c3b9f124
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "f6b1d4e8a235"
down_revision: Union[str, None] = "e5a0c3b9f124"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "products",
        sa.Column("tracks_inventory", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.execute("UPDATE products SET tracks_inventory = true WHERE stock_quantity > 0")
    op.alter_column("products", "tracks_inventory", server_default=None)
    op.add_column("orders", sa.Column("razorpay_refund_id", sa.String(), nullable=True))
    op.add_column("orders", sa.Column("refund_status", sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column("orders", "refund_status")
    op.drop_column("orders", "razorpay_refund_id")
    op.drop_column("products", "tracks_inventory")
