"""initial homecare schema

Revision ID: d7b6224911cb
Revises:
Create Date: 2026-09-11 18:51:20.815844

Creates the original/base Homecare Platform schema.
Later migrations add: service_categories.image_url (b2c8f4a91d37),
service_request_images (c4e91b7f2a08), and password_reset_tokens plus
contact_messages (a94c1e62f7b3). Those objects are intentionally NOT
created here so the migration chain applies cleanly on a fresh database.

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'd7b6224911cb'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'service_categories',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_service_categories_name'), 'service_categories', ['name'], unique=True)

    op.create_table(
        'users',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('first_name', sa.String(length=100), nullable=False),
        sa.Column('last_name', sa.String(length=100), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('phone_number', sa.String(length=30), nullable=False),
        sa.Column('password_hash', sa.String(length=255), nullable=False),
        sa.Column('role', sa.Enum('CUSTOMER', 'SERVICE_PROVIDER', 'ADMIN', name='user_role'), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)
    op.create_index(op.f('ix_users_phone_number'), 'users', ['phone_number'], unique=True)

    op.create_table(
        'notifications',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('notification_type', sa.Enum('SERVICE_REQUEST', 'ASSIGNMENT', 'QUOTE', 'PAYMENT', 'ISSUE', 'GENERAL', name='notification_type'), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('message', sa.Text(), nullable=False),
        sa.Column('reference_id', sa.UUID(), nullable=True),
        sa.Column('is_read', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_notifications_reference_id'), 'notifications', ['reference_id'], unique=False)
    op.create_index(op.f('ix_notifications_user_id'), 'notifications', ['user_id'], unique=False)

    op.create_table(
        'provider_profiles',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('business_name', sa.String(length=255), nullable=True),
        sa.Column('bio', sa.Text(), nullable=True),
        sa.Column('approval_status', sa.Enum('PENDING', 'APPROVED', 'REJECTED', name='provider_approval_status'), nullable=False),
        sa.Column('is_available', sa.Boolean(), nullable=False),
        sa.Column('average_rating', sa.Float(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id')
    )

    op.create_table(
        'service_requests',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('customer_id', sa.UUID(), nullable=False),
        sa.Column('status', sa.Enum('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', name='service_request_status'), nullable=False),
        sa.Column('address', sa.String(length=255), nullable=False),
        sa.Column('latitude', sa.Numeric(precision=9, scale=6), nullable=False),
        sa.Column('longitude', sa.Numeric(precision=9, scale=6), nullable=False),
        sa.Column('preferred_date', sa.DateTime(timezone=True), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['customer_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_service_requests_customer_id'), 'service_requests', ['customer_id'], unique=False)
    op.create_index(op.f('ix_service_requests_status'), 'service_requests', ['status'], unique=False)

    op.create_table(
        'provider_locations',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('provider_id', sa.UUID(), nullable=False),
        sa.Column('latitude', sa.Numeric(precision=9, scale=6), nullable=False),
        sa.Column('longitude', sa.Numeric(precision=9, scale=6), nullable=False),
        sa.Column('address', sa.String(length=255), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['provider_id'], ['provider_profiles.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('provider_id')
    )

    op.create_table(
        'provider_services',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('provider_id', sa.UUID(), nullable=False),
        sa.Column('service_category_id', sa.UUID(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['provider_id'], ['provider_profiles.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['service_category_id'], ['service_categories.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('provider_id', 'service_category_id', name='uq_provider_service')
    )

    op.create_table(
        'service_request_items',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('service_request_id', sa.UUID(), nullable=False),
        sa.Column('service_category_id', sa.UUID(), nullable=False),
        sa.Column('status', sa.Enum('PENDING', 'SEARCHING_PROVIDER', 'PROVIDER_ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', name='service_request_item_status'), nullable=False),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['service_category_id'], ['service_categories.id'], ondelete='RESTRICT'),
        sa.ForeignKeyConstraint(['service_request_id'], ['service_requests.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_service_request_items_service_category_id'), 'service_request_items', ['service_category_id'], unique=False)
    op.create_index(op.f('ix_service_request_items_service_request_id'), 'service_request_items', ['service_request_id'], unique=False)
    op.create_index(op.f('ix_service_request_items_status'), 'service_request_items', ['status'], unique=False)

    op.create_table(
        'assignments',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('service_request_id', sa.UUID(), nullable=False),
        sa.Column('service_request_item_id', sa.UUID(), nullable=False),
        sa.Column('provider_id', sa.UUID(), nullable=False),
        sa.Column('status', sa.Enum('PENDING', 'ACCEPTED', 'DECLINED', 'ON_THE_WAY', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', name='assignment_status'), nullable=False),
        sa.Column('assigned_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('accepted_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['provider_id'], ['provider_profiles.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['service_request_id'], ['service_requests.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['service_request_item_id'], ['service_request_items.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_assignments_provider_id'), 'assignments', ['provider_id'], unique=False)
    op.create_index(op.f('ix_assignments_service_request_id'), 'assignments', ['service_request_id'], unique=False)
    op.create_index(op.f('ix_assignments_service_request_item_id'), 'assignments', ['service_request_item_id'], unique=False)
    op.create_index(op.f('ix_assignments_status'), 'assignments', ['status'], unique=False)

    op.create_table(
        'quotes',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('service_request_id', sa.UUID(), nullable=False),
        sa.Column('service_request_item_id', sa.UUID(), nullable=False),
        sa.Column('provider_id', sa.UUID(), nullable=False),
        sa.Column('amount', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('currency', sa.String(length=10), nullable=False),
        sa.Column('status', sa.Enum('PENDING', 'APPROVED', 'REJECTED', name='quote_status'), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['provider_id'], ['provider_profiles.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['service_request_id'], ['service_requests.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['service_request_item_id'], ['service_request_items.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_quotes_provider_id'), 'quotes', ['provider_id'], unique=False)
    op.create_index(op.f('ix_quotes_service_request_id'), 'quotes', ['service_request_id'], unique=False)
    op.create_index(op.f('ix_quotes_service_request_item_id'), 'quotes', ['service_request_item_id'], unique=False)
    op.create_index(op.f('ix_quotes_status'), 'quotes', ['status'], unique=False)

    op.create_table(
        'issues',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('service_request_id', sa.UUID(), nullable=False),
        sa.Column('assignment_id', sa.UUID(), nullable=True),
        sa.Column('reported_by_id', sa.UUID(), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('status', sa.Enum('OPEN', 'UNDER_REVIEW', 'RESOLVED', name='issue_status'), nullable=False),
        sa.Column('resolution', sa.Text(), nullable=True),
        sa.Column('resolved_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['assignment_id'], ['assignments.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['reported_by_id'], ['users.id'], ondelete='RESTRICT'),
        sa.ForeignKeyConstraint(['service_request_id'], ['service_requests.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_issues_assignment_id'), 'issues', ['assignment_id'], unique=False)
    op.create_index(op.f('ix_issues_reported_by_id'), 'issues', ['reported_by_id'], unique=False)
    op.create_index(op.f('ix_issues_service_request_id'), 'issues', ['service_request_id'], unique=False)
    op.create_index(op.f('ix_issues_status'), 'issues', ['status'], unique=False)

    op.create_table(
        'payments',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('service_request_id', sa.UUID(), nullable=False),
        sa.Column('quote_id', sa.UUID(), nullable=False),
        sa.Column('customer_id', sa.UUID(), nullable=False),
        sa.Column('amount', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('currency', sa.String(length=10), nullable=False),
        sa.Column('payment_method', sa.Enum('MOBILE_MONEY', 'CARD', 'CASH', name='payment_method'), nullable=False),
        sa.Column('status', sa.Enum('PENDING', 'PROCESSING', 'PAID', 'FAILED', 'REFUNDED', name='payment_status'), nullable=False),
        sa.Column('transaction_reference', sa.String(length=255), nullable=True),
        sa.Column('paid_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['customer_id'], ['users.id'], ondelete='RESTRICT'),
        sa.ForeignKeyConstraint(['quote_id'], ['quotes.id'], ondelete='RESTRICT'),
        sa.ForeignKeyConstraint(['service_request_id'], ['service_requests.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_payments_customer_id'), 'payments', ['customer_id'], unique=False)
    op.create_index(op.f('ix_payments_quote_id'), 'payments', ['quote_id'], unique=False)
    op.create_index(op.f('ix_payments_service_request_id'), 'payments', ['service_request_id'], unique=False)
    op.create_index(op.f('ix_payments_status'), 'payments', ['status'], unique=False)
    op.create_index(op.f('ix_payments_transaction_reference'), 'payments', ['transaction_reference'], unique=True)

    op.create_table(
        'reviews',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('customer_id', sa.UUID(), nullable=False),
        sa.Column('provider_id', sa.UUID(), nullable=False),
        sa.Column('assignment_id', sa.UUID(), nullable=False),
        sa.Column('rating', sa.Integer(), nullable=False),
        sa.Column('comment', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.CheckConstraint('rating >= 1 AND rating <= 5', name='check_review_rating'),
        sa.ForeignKeyConstraint(['assignment_id'], ['assignments.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['customer_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['provider_id'], ['provider_profiles.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_reviews_assignment_id'), 'reviews', ['assignment_id'], unique=True)
    op.create_index(op.f('ix_reviews_customer_id'), 'reviews', ['customer_id'], unique=False)
    op.create_index(op.f('ix_reviews_provider_id'), 'reviews', ['provider_id'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_reviews_provider_id'), table_name='reviews')
    op.drop_index(op.f('ix_reviews_customer_id'), table_name='reviews')
    op.drop_index(op.f('ix_reviews_assignment_id'), table_name='reviews')
    op.drop_table('reviews')

    op.drop_index(op.f('ix_payments_transaction_reference'), table_name='payments')
    op.drop_index(op.f('ix_payments_status'), table_name='payments')
    op.drop_index(op.f('ix_payments_service_request_id'), table_name='payments')
    op.drop_index(op.f('ix_payments_quote_id'), table_name='payments')
    op.drop_index(op.f('ix_payments_customer_id'), table_name='payments')
    op.drop_table('payments')

    op.drop_index(op.f('ix_issues_status'), table_name='issues')
    op.drop_index(op.f('ix_issues_service_request_id'), table_name='issues')
    op.drop_index(op.f('ix_issues_reported_by_id'), table_name='issues')
    op.drop_index(op.f('ix_issues_assignment_id'), table_name='issues')
    op.drop_table('issues')

    op.drop_index(op.f('ix_quotes_status'), table_name='quotes')
    op.drop_index(op.f('ix_quotes_service_request_item_id'), table_name='quotes')
    op.drop_index(op.f('ix_quotes_service_request_id'), table_name='quotes')
    op.drop_index(op.f('ix_quotes_provider_id'), table_name='quotes')
    op.drop_table('quotes')

    op.drop_index(op.f('ix_assignments_status'), table_name='assignments')
    op.drop_index(op.f('ix_assignments_service_request_item_id'), table_name='assignments')
    op.drop_index(op.f('ix_assignments_service_request_id'), table_name='assignments')
    op.drop_index(op.f('ix_assignments_provider_id'), table_name='assignments')
    op.drop_table('assignments')

    op.drop_index(op.f('ix_service_request_items_status'), table_name='service_request_items')
    op.drop_index(op.f('ix_service_request_items_service_request_id'), table_name='service_request_items')
    op.drop_index(op.f('ix_service_request_items_service_category_id'), table_name='service_request_items')
    op.drop_table('service_request_items')

    op.drop_table('provider_services')
    op.drop_table('provider_locations')

    op.drop_index(op.f('ix_service_requests_status'), table_name='service_requests')
    op.drop_index(op.f('ix_service_requests_customer_id'), table_name='service_requests')
    op.drop_table('service_requests')

    op.drop_table('provider_profiles')

    op.drop_index(op.f('ix_notifications_user_id'), table_name='notifications')
    op.drop_index(op.f('ix_notifications_reference_id'), table_name='notifications')
    op.drop_table('notifications')

    op.drop_index(op.f('ix_users_phone_number'), table_name='users')
    op.drop_index(op.f('ix_users_email'), table_name='users')
    op.drop_table('users')

    op.drop_index(op.f('ix_service_categories_name'), table_name='service_categories')
    op.drop_table('service_categories')

    for enum_name in (
        'user_role',
        'provider_approval_status',
        'service_request_status',
        'service_request_item_status',
        'assignment_status',
        'quote_status',
        'payment_method',
        'payment_status',
        'issue_status',
        'notification_type',
    ):
        op.execute(f'DROP TYPE IF EXISTS {enum_name}')
