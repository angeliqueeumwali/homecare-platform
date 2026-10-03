"""add image_url to service_categories

Revision ID: b2c8f4a91d37
Revises: d7b6224911cb
Create Date: 2026-09-30

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "b2c8f4a91d37"
down_revision: Union[str, Sequence[str], None] = "d7b6224911cb"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "service_categories",
        sa.Column("image_url", sa.String(length=500), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("service_categories", "image_url")
