from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "0011_commission_schedule"
down_revision = "0010_att_period_desc"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "attestation_commissions",
        sa.Column("meeting_date", sa.Date(), nullable=True),
    )
    op.add_column(
        "attestation_commissions",
        sa.Column("start_time", sa.Time(), nullable=True),
    )
    op.add_column(
        "attestation_commissions",
        sa.Column("end_time", sa.Time(), nullable=True),
    )
    op.add_column(
        "attestation_commissions",
        sa.Column("meeting_location", sa.String(length=255), nullable=True),
    )
    op.create_index(
        "ix_attestation_commissions_created_by",
        "attestation_commissions",
        ["created_by"],
    )


def downgrade() -> None:
    op.drop_index("ix_attestation_commissions_created_by", table_name="attestation_commissions")
    op.drop_column("attestation_commissions", "meeting_location")
    op.drop_column("attestation_commissions", "end_time")
    op.drop_column("attestation_commissions", "start_time")
    op.drop_column("attestation_commissions", "meeting_date")