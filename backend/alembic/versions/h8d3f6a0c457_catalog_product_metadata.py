"""add catalog-only ordering state and product source metadata

Revision ID: h8d3f6a0c457
Revises: g7c2e5f9b346
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


revision: str = "h8d3f6a0c457"
down_revision: Union[str, None] = "g7c2e5f9b346"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "products",
        sa.Column("is_orderable", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.add_column("products", sa.Column("material", sa.Text(), nullable=True))
    op.add_column("products", sa.Column("dimensions", sa.Text(), nullable=True))
    op.add_column("products", sa.Column("options_summary", sa.Text(), nullable=True))
    op.add_column("products", sa.Column("delivery_info", sa.Text(), nullable=True))
    op.add_column("products", sa.Column("price_note", sa.Text(), nullable=True))
    op.add_column("products", sa.Column("source_url", sa.String(length=2048), nullable=True))
    op.add_column("products", sa.Column("source_checked_on", sa.Date(), nullable=True))
    op.add_column("products", sa.Column("source_rating", sa.Float(), nullable=True))
    op.add_column("products", sa.Column("source_review_count", sa.Integer(), nullable=True))


def downgrade() -> None:
    op.drop_column("products", "source_review_count")
    op.drop_column("products", "source_rating")
    op.drop_column("products", "source_checked_on")
    op.drop_column("products", "source_url")
    op.drop_column("products", "price_note")
    op.drop_column("products", "delivery_info")
    op.drop_column("products", "options_summary")
    op.drop_column("products", "dimensions")
    op.drop_column("products", "material")
    op.drop_column("products", "is_orderable")
