"""bind private reward coupons to their owner

Revision ID: d4f9b2a8e013
Revises: c3e8a1f7d902
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "d4f9b2a8e013"
down_revision: Union[str, None] = "c3e8a1f7d902"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("coupons", sa.Column("owner_user_id", sa.String(), nullable=True))
    op.create_foreign_key(
        "coupons_owner_user_id_fkey",
        "coupons",
        "users",
        ["owner_user_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.create_index(
        op.f("ix_coupons_owner_user_id"),
        "coupons",
        ["owner_user_id"],
        unique=False,
    )
    # Legacy referral rewards were not associated with a recipient and cannot
    # be recovered safely. Deactivate only those generated prefixes.
    op.execute(
        "UPDATE coupons SET is_active = false "
        "WHERE owner_user_id IS NULL "
        "AND (code LIKE 'WELCOME%' OR code LIKE 'REFER%')"
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_coupons_owner_user_id"), table_name="coupons")
    op.drop_constraint(
        "coupons_owner_user_id_fkey",
        "coupons",
        type_="foreignkey",
    )
    op.drop_column("coupons", "owner_user_id")
