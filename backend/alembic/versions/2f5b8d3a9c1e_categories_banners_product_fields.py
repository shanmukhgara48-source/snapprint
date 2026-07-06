"""categories_banners_product_fields

Revision ID: 2f5b8d3a9c1e
Revises: 7a2f9c1e4b6d
Create Date: 2026-07-05 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '2f5b8d3a9c1e'
down_revision: Union[str, None] = '7a2f9c1e4b6d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'categories',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('icon', sa.String(), nullable=False),
        sa.Column('image_url', sa.String(), nullable=True),
        sa.Column('sort_order', sa.Integer(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('name'),
    )

    op.create_table(
        'banners',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('image_url', sa.String(), nullable=False),
        sa.Column('link_action', sa.String(), nullable=True),
        sa.Column('sort_order', sa.Integer(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('starts_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('ends_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )

    op.add_column('products', sa.Column('category_id', sa.String(), nullable=True))
    op.add_column('products', sa.Column('sort_order', sa.Integer(), nullable=False, server_default='0'))
    op.add_column('products', sa.Column('is_featured', sa.Boolean(), nullable=False, server_default='false'))
    op.create_index(op.f('ix_products_category_id'), 'products', ['category_id'], unique=False)
    op.create_foreign_key(
        'fk_products_category_id_categories', 'products', 'categories', ['category_id'], ['id']
    )


def downgrade() -> None:
    op.drop_constraint('fk_products_category_id_categories', 'products', type_='foreignkey')
    op.drop_index(op.f('ix_products_category_id'), table_name='products')
    op.drop_column('products', 'is_featured')
    op.drop_column('products', 'sort_order')
    op.drop_column('products', 'category_id')
    op.drop_table('banners')
    op.drop_table('categories')
