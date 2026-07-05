"""admin_panel_tables

Revision ID: 7a2f9c1e4b6d
Revises: 1c77601aa98f
Create Date: 2026-07-02 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7a2f9c1e4b6d'
down_revision: Union[str, None] = '1c77601aa98f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('orders', sa.Column('notes', sa.String(), nullable=True))

    op.create_table('admin_users',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('username', sa.String(), nullable=False),
        sa.Column('password_hash', sa.String(), nullable=False),
        sa.Column('role', sa.String(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('last_login_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_admin_users_username'), 'admin_users', ['username'], unique=True)

    op.create_table('admin_audit_logs',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('admin_user_id', sa.String(), nullable=False),
        sa.Column('action', sa.String(), nullable=False),
        sa.Column('resource_type', sa.String(), nullable=False),
        sa.Column('resource_id', sa.String(), nullable=True),
        sa.Column('details', sa.JSON(), nullable=True),
        sa.Column('ip_address', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['admin_user_id'], ['admin_users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )

    op.create_table('admin_login_history',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('admin_user_id', sa.String(), nullable=True),
        sa.Column('username_attempted', sa.String(), nullable=False),
        sa.Column('ip_address', sa.String(), nullable=True),
        sa.Column('success', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['admin_user_id'], ['admin_users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )

    op.create_table('payment_attempts',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('razorpay_order_id', sa.String(), nullable=False),
        sa.Column('razorpay_payment_id', sa.String(), nullable=True),
        sa.Column('status', sa.String(), nullable=False),
        sa.Column('reason', sa.String(), nullable=True),
        sa.Column('user_id', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_payment_attempts_razorpay_order_id'), 'payment_attempts', ['razorpay_order_id'], unique=False)

    op.create_table('app_settings',
        sa.Column('key', sa.String(), nullable=False),
        sa.Column('value', sa.JSON(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('key'),
    )


def downgrade() -> None:
    op.drop_table('app_settings')
    op.drop_index(op.f('ix_payment_attempts_razorpay_order_id'), table_name='payment_attempts')
    op.drop_table('payment_attempts')
    op.drop_table('admin_login_history')
    op.drop_table('admin_audit_logs')
    op.drop_index(op.f('ix_admin_users_username'), table_name='admin_users')
    op.drop_table('admin_users')
    op.drop_column('orders', 'notes')
