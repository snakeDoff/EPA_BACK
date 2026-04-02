from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "0003_periods"
down_revision = "0002_programs"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "attestation_periods",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("type", sa.String(length=50), nullable=False),
        sa.Column("year", sa.Integer(), nullable=False),
        sa.Column("season", sa.String(length=20), nullable=False),
        sa.Column("start_date", sa.Date(), nullable=False),
        sa.Column("end_date", sa.Date(), nullable=False),
        sa.Column("status", sa.String(length=50), nullable=False, server_default=sa.text("'draft'")),
        sa.Column(
            "created_by",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.UniqueConstraint(
            "type",
            "year",
            "season",
            name="uq_attestation_periods_type_year_season",
        ),
        sa.CheckConstraint(
            "type in ('attestation', 'department_seminar')",
            name="chk_attestation_periods_type",
        ),
        sa.CheckConstraint(
            "season in ('spring', 'autumn')",
            name="chk_attestation_periods_season",
        ),
        sa.CheckConstraint(
            "status in ('draft', 'active', 'completed', 'archived')",
            name="chk_attestation_periods_status",
        ),
        sa.CheckConstraint(
            "start_date <= end_date",
            name="chk_attestation_periods_dates",
        ),
        sa.CheckConstraint(
            "year >= 2000",
            name="chk_attestation_periods_year",
        ),
    )

    op.create_index("ix_attestation_periods_type", "attestation_periods", ["type"])
    op.create_index("ix_attestation_periods_status", "attestation_periods", ["status"])
    op.create_index("ix_attestation_periods_year_season", "attestation_periods", ["year", "season"])


def downgrade() -> None:
    op.drop_index("ix_attestation_periods_year_season", table_name="attestation_periods")
    op.drop_index("ix_attestation_periods_status", table_name="attestation_periods")
    op.drop_index("ix_attestation_periods_type", table_name="attestation_periods")
    op.drop_table("attestation_periods")