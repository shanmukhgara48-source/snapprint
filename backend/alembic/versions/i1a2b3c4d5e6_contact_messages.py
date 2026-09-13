"""contact messages table + order lookup index for /orders/me

Revision ID: i1a2b3c4d5e6
Revises: h8d3f6a0c457

Idempotent: app lifespan boots databases via create_all, so the table may
already exist when this runs — create only what is missing.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


revision: str = "i1a2b3c4d5e6"
down_revision: Union[str, None] = "h8d3f6a0c457"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    if not inspector.has_table("contact_messages"):
        op.create_table(
            "contact_messages",
            sa.Column("id", sa.String(), nullable=False),
            sa.Column("name", sa.String(length=120), nullable=False),
            sa.Column("email", sa.String(length=254), nullable=False),
            sa.Column("subject", sa.String(length=160), nullable=False),
            sa.Column("message", sa.Text(), nullable=False),
            sa.Column("user_id", sa.String(), nullable=True),
            sa.Column("ip_address", sa.String(length=64), nullable=True),
            sa.Column("is_read", sa.Boolean(), nullable=False, server_default=sa.false()),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.PrimaryKeyConstraint("id"),
        )
    existing = {i["name"] for i in inspector.get_indexes("contact_messages")}
    if "ix_contact_messages_created_at" not in existing:
        op.create_index("ix_contact_messages_created_at", "contact_messages", ["created_at"])
    # Speeds up GET /orders/me (WHERE user_id = … ORDER BY created_at DESC).
    order_indexes = {i["name"] for i in inspector.get_indexes("orders")}
    if "ix_orders_user_created" not in order_indexes:
        op.create_index(
            "ix_orders_user_created", "orders", ["user_id", sa.text("created_at DESC")]
        )


def downgrade() -> None:
    op.drop_index("ix_orders_user_created", table_name="orders")
    op.drop_index("ix_contact_messages_created_at", table_name="contact_messages")
    op.drop_table("contact_messages")
