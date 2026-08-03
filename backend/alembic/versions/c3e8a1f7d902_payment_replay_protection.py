"""payment replay protection

Revision ID: c3e8a1f7d902
Revises: 4d8e6f2a1b3c
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c3e8a1f7d902"
down_revision: Union[str, None] = "4d8e6f2a1b3c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    inspector = sa.inspect(op.get_bind())
    if "payment_intents" not in inspector.get_table_names():
        op.create_table(
            "payment_intents",
            sa.Column("id", sa.String(), nullable=False),
            sa.Column("razorpay_order_id", sa.String(), nullable=False),
            sa.Column("user_id", sa.String(), nullable=False),
            sa.Column("amount_paise", sa.Integer(), nullable=False),
            sa.Column("status", sa.String(), nullable=False),
            sa.Column("razorpay_payment_id", sa.String(), nullable=True),
            sa.Column("consumed_order_id", sa.String(), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
            sa.ForeignKeyConstraint(
                ["user_id"], ["users.id"], ondelete="CASCADE"
            ),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("razorpay_order_id"),
        )
    intent_indexes = {
        item["name"] for item in sa.inspect(op.get_bind()).get_indexes("payment_intents")
    }
    if op.f("ix_payment_intents_razorpay_order_id") not in intent_indexes:
        op.create_index(
            op.f("ix_payment_intents_razorpay_order_id"),
            "payment_intents",
            ["razorpay_order_id"],
            unique=True,
        )
    if op.f("ix_payment_intents_user_id") not in intent_indexes:
        op.create_index(
            op.f("ix_payment_intents_user_id"),
            "payment_intents",
            ["user_id"],
            unique=False,
        )
    op.create_index(
        "uq_orders_razorpay_order_id",
        "orders",
        ["razorpay_order_id"],
        unique=True,
        postgresql_where=sa.text("razorpay_order_id IS NOT NULL"),
    )
    op.create_index(
        "uq_orders_razorpay_payment_id",
        "orders",
        ["razorpay_payment_id"],
        unique=True,
        postgresql_where=sa.text("razorpay_payment_id IS NOT NULL"),
    )


def downgrade() -> None:
    op.drop_index("uq_orders_razorpay_payment_id", table_name="orders")
    op.drop_index("uq_orders_razorpay_order_id", table_name="orders")
    op.drop_index(op.f("ix_payment_intents_user_id"), table_name="payment_intents")
    op.drop_index(
        op.f("ix_payment_intents_razorpay_order_id"),
        table_name="payment_intents",
    )
    op.drop_table("payment_intents")
