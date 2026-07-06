"""product_stock_trending_images

Revision ID: 9b1a7d4c2e3f
Revises: 2f5b8d3a9c1e
Create Date: 2026-07-06 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9b1a7d4c2e3f'
down_revision: Union[str, None] = '2f5b8d3a9c1e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('products', sa.Column('images', sa.JSON(), nullable=True))
    op.add_column('products', sa.Column('stock_quantity', sa.Integer(), nullable=True))
    op.add_column('products', sa.Column('is_trending', sa.Boolean(), nullable=True))

    # Backfill images from the old single image_url column, then enforce defaults.
    op.execute("""
        UPDATE products
        SET images = CASE
            WHEN image_url IS NOT NULL AND image_url != '' THEN json_build_array(image_url)
            ELSE '[]'::json
        END
    """)
    op.execute("UPDATE products SET stock_quantity = 0 WHERE stock_quantity IS NULL")
    op.execute("UPDATE products SET is_trending = false WHERE is_trending IS NULL")

    op.alter_column('products', 'images', nullable=False, server_default='[]')
    op.alter_column('products', 'stock_quantity', nullable=False, server_default='0')
    op.alter_column('products', 'is_trending', nullable=False, server_default='false')

    op.drop_column('products', 'image_url')


def downgrade() -> None:
    op.add_column('products', sa.Column('image_url', sa.String(), nullable=True))
    op.execute("""
        UPDATE products
        SET image_url = CASE
            WHEN json_array_length(images) > 0 THEN images->>0
            ELSE ''
        END
    """)
    op.alter_column('products', 'image_url', nullable=False, server_default='')
    op.drop_column('products', 'is_trending')
    op.drop_column('products', 'stock_quantity')
    op.drop_column('products', 'images')
