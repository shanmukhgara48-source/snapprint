"""add order purchase channel (mobile_app / website / admin)

Revision ID: j2b3c4d5e6f7
Revises: i1a2b3c4d5e6
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "j2b3c4d5e6f7"
down_revision: Union[str, None] = "i1a2b3c4d5e6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "orders",
        sa.Column("source", sa.String(), nullable=False, server_default="unknown"),
    )
    op.execute("UPDATE orders SET source = 'unknown' WHERE source IS NULL")
    op.alter_column("orders", "source", server_default=None)


def downgrade() -> None:
    op.drop_column("orders", "source")
