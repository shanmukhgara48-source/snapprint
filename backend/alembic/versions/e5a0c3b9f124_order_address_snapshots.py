"""preserve order delivery address snapshots

Revision ID: e5a0c3b9f124
Revises: d4f9b2a8e013
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "e5a0c3b9f124"
down_revision: Union[str, None] = "d4f9b2a8e013"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "orders",
        sa.Column("delivery_address_snapshot", sa.String(), nullable=True),
    )
    op.add_column(
        "orders",
        sa.Column("delivery_city_snapshot", sa.String(), nullable=True),
    )
    op.add_column(
        "orders",
        sa.Column("delivery_pincode_snapshot", sa.String(), nullable=True),
    )
    op.execute(
        "UPDATE orders SET "
        "delivery_address_snapshot = addresses.full_address, "
        "delivery_city_snapshot = addresses.city, "
        "delivery_pincode_snapshot = addresses.pincode "
        "FROM addresses WHERE orders.address_id = addresses.id"
    )
    op.drop_constraint("orders_address_id_fkey", "orders", type_="foreignkey")
    op.create_foreign_key(
        "orders_address_id_fkey",
        "orders",
        "addresses",
        ["address_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint("orders_address_id_fkey", "orders", type_="foreignkey")
    op.create_foreign_key(
        "orders_address_id_fkey",
        "orders",
        "addresses",
        ["address_id"],
        ["id"],
    )
    op.drop_column("orders", "delivery_pincode_snapshot")
    op.drop_column("orders", "delivery_city_snapshot")
    op.drop_column("orders", "delivery_address_snapshot")
