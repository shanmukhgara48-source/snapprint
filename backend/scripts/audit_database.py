"""Fail CI/release validation when persisted business invariants are broken."""

import asyncio
import sys
from pathlib import Path

from sqlalchemy import text

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.database import engine


CHECKS = {
    "active products without a sellable price": """
        SELECT count(*) FROM products
        WHERE is_active = true AND base_price <= 0
          AND (sizes IS NULL OR jsonb_array_length(sizes::jsonb) = 0)
    """,
    "products with missing or mismatched categories": """
        SELECT count(*) FROM products p
        LEFT JOIN categories c ON c.id = p.category_id
        WHERE p.is_active = true
          AND (p.category_id IS NULL OR c.id IS NULL OR c.name <> p.category)
    """,
    "negative tracked inventory": """
        SELECT count(*) FROM products
        WHERE tracks_inventory = true AND stock_quantity < 0
    """,
    "invalid order totals or quantities": """
        SELECT count(*) FROM orders o
        WHERE o.total_price < 0 OR EXISTS (
            SELECT 1 FROM order_items i
            WHERE i.order_id = o.id AND (i.quantity <= 0 OR i.unit_price <= 0)
        )
    """,
    "paid orders without both Razorpay references": """
        SELECT count(*) FROM orders
        WHERE total_price > 0
          AND (razorpay_order_id IS NULL OR razorpay_payment_id IS NULL)
          AND NOT (status = 'cancelled' AND refund_status = 'not_paid')
    """,
    "duplicate Razorpay order references": """
        SELECT count(*) FROM (
            SELECT razorpay_order_id FROM orders
            WHERE razorpay_order_id IS NOT NULL
            GROUP BY razorpay_order_id HAVING count(*) > 1
        ) duplicates
    """,
    "duplicate Razorpay payment references": """
        SELECT count(*) FROM (
            SELECT razorpay_payment_id FROM orders
            WHERE razorpay_payment_id IS NOT NULL
            GROUP BY razorpay_payment_id HAVING count(*) > 1
        ) duplicates
    """,
    "coupon usage above its limit": """
        SELECT count(*) FROM coupons
        WHERE used_count < 0 OR (max_uses IS NOT NULL AND used_count > max_uses)
    """,
    "unknown order statuses": """
        SELECT count(*) FROM orders
        WHERE status NOT IN ('confirmed', 'picked_up', 'out_for_delivery', 'delivered', 'cancelled')
    """,
    "consumed payment intents without an order": """
        SELECT count(*) FROM payment_intents pi
        LEFT JOIN orders o ON o.id = pi.consumed_order_id
        WHERE pi.status = 'consumed' AND o.id IS NULL
    """,
    "orders missing a confirmation tracking event": """
        SELECT count(*) FROM orders o
        WHERE NOT EXISTS (
            SELECT 1 FROM delivery_tracking t
            WHERE t.order_id = o.id AND t.status = 'confirmed'
        )
    """,
    "active users with duplicate identifiers": """
        SELECT count(*) FROM (
            SELECT phone FROM users WHERE is_active = true
            GROUP BY phone HAVING count(*) > 1
        ) duplicates
    """,
    "orders whose stored total disagrees with their item ledger": """
        SELECT count(*) FROM orders o
        JOIN (
            SELECT order_id, sum(quantity * unit_price) AS item_total
            FROM order_items GROUP BY order_id
        ) items ON items.order_id = o.id
        WHERE abs(o.total_price - (items.item_total + o.delivery_charge - o.discount)) > 0.011
    """,
}


async def main() -> int:
    failures: list[tuple[str, int]] = []
    async with engine.connect() as connection:
        for label, statement in CHECKS.items():
            count = int((await connection.execute(text(statement))).scalar_one())
            print(f"{label}: {count}")
            if count:
                failures.append((label, count))
    await engine.dispose()
    if failures:
        print("Database integrity audit failed.")
        return 1
    print("Database integrity audit passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
