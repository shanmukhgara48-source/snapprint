"""order-level gift wrap option (fee + message)

Revision ID: l4d5e6f7g8h9
Revises: k3c4d5e6f7g8

Idempotent: app lifespan boots databases via create_all, so columns are
added only when missing.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "l4d5e6f7g8h9"
down_revision: Union[str, None] = "k3c4d5e6f7g8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    cols = {c["name"] for c in sa.inspect(conn).get_columns("orders")}
    if "gift_wrap" not in cols:
        op.add_column(
            "orders",
            sa.Column("gift_wrap", sa.Boolean(), nullable=False, server_default=sa.false()),
        )
        op.alter_column("orders", "gift_wrap", server_default=None)
    if "gift_wrap_charge" not in cols:
        op.add_column(
            "orders",
            sa.Column("gift_wrap_charge", sa.Float(), nullable=False, server_default="0"),
        )
        op.alter_column("orders", "gift_wrap_charge", server_default=None)
    if "gift_message" not in cols:
        op.add_column("orders", sa.Column("gift_message", sa.String(length=500), nullable=True))


def downgrade() -> None:
    conn = op.get_bind()
    cols = {c["name"] for c in sa.inspect(conn).get_columns("orders")}
    if "gift_message" in cols:
        op.drop_column("orders", "gift_message")
    if "gift_wrap_charge" in cols:
        op.drop_column("orders", "gift_wrap_charge")
    if "gift_wrap" in cols:
        op.drop_column("orders", "gift_wrap")
