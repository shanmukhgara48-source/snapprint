"""fk_ondelete_rules

Revision ID: 4d8e6f2a1b3c
Revises: 9b1a7d4c2e3f
Create Date: 2026-07-06 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = '4d8e6f2a1b3c'
down_revision: Union[str, None] = '9b1a7d4c2e3f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # payment_attempts.user_id: nullable, admin-facing audit trail — keep the
    # row, null the reference, so account deletion doesn't crash on a user's
    # own payment history.
    op.drop_constraint('payment_attempts_user_id_fkey', 'payment_attempts', type_='foreignkey')
    op.create_foreign_key(
        'payment_attempts_user_id_fkey', 'payment_attempts', 'users',
        ['user_id'], ['id'], ondelete='SET NULL',
    )

    # orders.delivery_partner_id: nullable — deleting a delivery partner's
    # account must not break orders they delivered for other customers.
    op.drop_constraint('orders_delivery_partner_id_fkey', 'orders', type_='foreignkey')
    op.create_foreign_key(
        'orders_delivery_partner_id_fkey', 'orders', 'users',
        ['delivery_partner_id'], ['id'], ondelete='SET NULL',
    )

    # orders.user_id / addresses.user_id: already cascade-deleted at the ORM
    # layer (User.orders / User.addresses use cascade="all, delete-orphan").
    # Add the same rule at the DB level as a backstop for any deletion path
    # that bypasses the ORM session (e.g. raw SQL, future admin tooling).
    op.drop_constraint('orders_user_id_fkey', 'orders', type_='foreignkey')
    op.create_foreign_key(
        'orders_user_id_fkey', 'orders', 'users',
        ['user_id'], ['id'], ondelete='CASCADE',
    )
    op.drop_constraint('addresses_user_id_fkey', 'addresses', type_='foreignkey')
    op.create_foreign_key(
        'addresses_user_id_fkey', 'addresses', 'users',
        ['user_id'], ['id'], ondelete='CASCADE',
    )

    # admin_login_history.admin_user_id: nullable audit trail — preserve login
    # history rows even if the admin account is later removed.
    op.drop_constraint('admin_login_history_admin_user_id_fkey', 'admin_login_history', type_='foreignkey')
    op.create_foreign_key(
        'admin_login_history_admin_user_id_fkey', 'admin_login_history', 'admin_users',
        ['admin_user_id'], ['id'], ondelete='SET NULL',
    )


def downgrade() -> None:
    op.drop_constraint('admin_login_history_admin_user_id_fkey', 'admin_login_history', type_='foreignkey')
    op.create_foreign_key(
        'admin_login_history_admin_user_id_fkey', 'admin_login_history', 'admin_users',
        ['admin_user_id'], ['id'],
    )

    op.drop_constraint('addresses_user_id_fkey', 'addresses', type_='foreignkey')
    op.create_foreign_key('addresses_user_id_fkey', 'addresses', 'users', ['user_id'], ['id'])

    op.drop_constraint('orders_user_id_fkey', 'orders', type_='foreignkey')
    op.create_foreign_key('orders_user_id_fkey', 'orders', 'users', ['user_id'], ['id'])

    op.drop_constraint('orders_delivery_partner_id_fkey', 'orders', type_='foreignkey')
    op.create_foreign_key('orders_delivery_partner_id_fkey', 'orders', 'users', ['delivery_partner_id'], ['id'])

    op.drop_constraint('payment_attempts_user_id_fkey', 'payment_attempts', type_='foreignkey')
    op.create_foreign_key('payment_attempts_user_id_fkey', 'payment_attempts', 'users', ['user_id'], ['id'])
