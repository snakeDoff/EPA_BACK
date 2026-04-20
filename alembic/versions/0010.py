from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "0010_att_period_desc"
down_revision = "0009_att_lifecycle"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "attestation_periods",
        sa.Column("description", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("attestation_periods", "description")