"""quarantine legacy invalid orders and repair catalog links

Revision ID: g7c2e5f9b346
Revises: f6b1d4e8a235
"""
from typing import Sequence, Union

from alembic import op


revision: str = "g7c2e5f9b346"
down_revision: Union[str, None] = "f6b1d4e8a235"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        UPDATE products p
        SET category_id = c.id, category = c.name
        FROM categories c
        WHERE p.category_id IS NULL
          AND lower(trim(p.category)) = lower(trim(c.name))
        """
    )
    op.execute(
        """
        UPDATE products
        SET is_active = false
        WHERE is_active = true AND base_price <= 0
          AND (sizes IS NULL OR jsonb_array_length(sizes::jsonb) = 0)
        """
    )
    op.execute(
        """
        UPDATE orders
        SET status = 'cancelled',
            refund_status = 'not_paid',
            notes = concat_ws(E'\n', notes, 'Automatically cancelled: legacy order has no verified payment reference.')
        WHERE total_price > 0
          AND (razorpay_order_id IS NULL OR razorpay_payment_id IS NULL)
          AND status NOT IN ('delivered', 'cancelled')
        """
    )
    op.execute(
        """
        INSERT INTO delivery_tracking (id, order_id, status, timestamp)
        SELECT 'legacy-cancelled-' || o.id, o.id, 'cancelled', now()
        FROM orders o
        WHERE o.refund_status = 'not_paid'
          AND NOT EXISTS (
              SELECT 1 FROM delivery_tracking t
              WHERE t.order_id = o.id AND t.status = 'cancelled'
          )
        """
    )


def downgrade() -> None:
    # Data quarantine is intentionally irreversible; restoring unverified
    # orders to fulfillment would be unsafe.
    pass
