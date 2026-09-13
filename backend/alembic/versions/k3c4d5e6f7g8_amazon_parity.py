"""amazon parity: reviews, wishlist, returns, sku + sale merchandising

Revision ID: k3c4d5e6f7g8
Revises: j2b3c4d5e6f7

Idempotent: app lifespan boots fresh databases via create_all, so every
object here is created only when missing (the same pattern as
i1a2b3c4d5e6). Safe to run on create_all-booted and migration-booted DBs.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "k3c4d5e6f7g8"
down_revision: Union[str, None] = "j2b3c4d5e6f7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_table(conn, name: str) -> bool:
    return sa.inspect(conn).has_table(name)


def _columns(conn, table: str) -> set[str]:
    return {c["name"] for c in sa.inspect(conn).get_columns(table)}


def _has_index(conn, table: str, name: str) -> bool:
    return any(i["name"] == name for i in sa.inspect(conn).get_indexes(table))


def _has_unique(conn, table: str, name: str) -> bool:
    return any(u["name"] == name for u in sa.inspect(conn).get_unique_constraints(table))


def upgrade() -> None:
    conn = op.get_bind()

    if "sku" not in _columns(conn, "products"):
        op.add_column("products", sa.Column("sku", sa.String(length=64), nullable=True))
    if not _has_unique(conn, "products", "uq_products_sku"):
        op.create_unique_constraint("uq_products_sku", "products", ["sku"])
    if "compare_at_price" not in _columns(conn, "products"):
        op.add_column("products", sa.Column("compare_at_price", sa.Float(), nullable=True))
    if "is_bestseller" not in _columns(conn, "products"):
        op.add_column(
            "products",
            sa.Column("is_bestseller", sa.Boolean(), nullable=False, server_default=sa.false()),
        )
        op.alter_column("products", "is_bestseller", server_default=None)

    if not _has_table(conn, "reviews"):
        op.create_table(
            "reviews",
            sa.Column("id", sa.String(), nullable=False),
            sa.Column("product_id", sa.String(), nullable=False),
            sa.Column("user_id", sa.String(), nullable=False),
            sa.Column("order_id", sa.String(), nullable=True),
            sa.Column("rating", sa.SmallInteger(), nullable=False),
            sa.Column("title", sa.String(length=120), nullable=False, server_default=""),
            sa.Column("body", sa.Text(), nullable=False, server_default=""),
            sa.Column("verified_purchase", sa.Boolean(), nullable=False, server_default=sa.false()),
            sa.Column("helpful_count", sa.Integer(), nullable=False, server_default="0"),
            sa.Column("seller_response", sa.Text(), nullable=True),
            sa.Column("status", sa.String(), nullable=False, server_default="published"),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
            sa.ForeignKeyConstraint(["product_id"], ["products.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["order_id"], ["orders.id"], ondelete="SET NULL"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("product_id", "user_id", name="uq_reviews_product_user"),
        )
        op.alter_column("reviews", "title", server_default=None)
        op.alter_column("reviews", "body", server_default=None)
        op.alter_column("reviews", "verified_purchase", server_default=None)
        op.alter_column("reviews", "helpful_count", server_default=None)
        op.alter_column("reviews", "status", server_default=None)
    if not _has_index(conn, "reviews", "ix_reviews_product_status"):
        op.create_index("ix_reviews_product_status", "reviews", ["product_id", "status"])

    if not _has_table(conn, "review_votes"):
        op.create_table(
            "review_votes",
            sa.Column("id", sa.String(), nullable=False),
            sa.Column("review_id", sa.String(), nullable=False),
            sa.Column("user_id", sa.String(), nullable=False),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.ForeignKeyConstraint(["review_id"], ["reviews.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("review_id", "user_id", name="uq_review_votes_review_user"),
        )

    if not _has_table(conn, "wishlist_items"):
        op.create_table(
            "wishlist_items",
            sa.Column("id", sa.String(), nullable=False),
            sa.Column("user_id", sa.String(), nullable=False),
            sa.Column("product_id", sa.String(), nullable=False),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["product_id"], ["products.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("user_id", "product_id", name="uq_wishlist_user_product"),
        )

    if not _has_table(conn, "return_requests"):
        op.create_table(
            "return_requests",
            sa.Column("id", sa.String(), nullable=False),
            sa.Column("order_id", sa.String(), nullable=False),
            sa.Column("user_id", sa.String(), nullable=False),
            sa.Column("reason", sa.String(length=64), nullable=False),
            sa.Column("details", sa.Text(), nullable=True),
            sa.Column("status", sa.String(), nullable=False, server_default="requested"),
            sa.Column("admin_note", sa.Text(), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("decided_at", sa.DateTime(timezone=True), nullable=True),
            sa.ForeignKeyConstraint(["order_id"], ["orders.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )
        op.alter_column("return_requests", "status", server_default=None)
    if not _has_index(conn, "return_requests", "ix_return_requests_order"):
        op.create_index("ix_return_requests_order", "return_requests", ["order_id"])


def downgrade() -> None:
    # Defensive: databases booted via create_all may lack migration-only
    # indexes/constraints — drop only what actually exists.
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    if inspector.has_table("return_requests"):
        existing = {i["name"] for i in inspector.get_indexes("return_requests")}
        if "ix_return_requests_order" in existing:
            op.drop_index("ix_return_requests_order", table_name="return_requests")
        op.drop_table("return_requests")
    if inspector.has_table("wishlist_items"):
        op.drop_table("wishlist_items")
    if inspector.has_table("review_votes"):
        op.drop_table("review_votes")
    if inspector.has_table("reviews"):
        existing = {i["name"] for i in inspector.get_indexes("reviews")}
        if "ix_reviews_product_status" in existing:
            op.drop_index("ix_reviews_product_status", table_name="reviews")
        op.drop_table("reviews")
    cols = {c["name"] for c in inspector.get_columns("products")}
    uniques = {u["name"] for u in inspector.get_unique_constraints("products")}
    if "is_bestseller" in cols:
        op.execute("ALTER TABLE products ALTER COLUMN is_bestseller DROP DEFAULT")
        op.drop_column("products", "is_bestseller")
    if "compare_at_price" in cols:
        op.drop_column("products", "compare_at_price")
    if "uq_products_sku" in uniques:
        op.drop_constraint("uq_products_sku", "products", type_="unique")
    if "sku" in cols:
        op.drop_column("products", "sku")
