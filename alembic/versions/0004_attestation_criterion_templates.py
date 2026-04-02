from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "0004_templates"
down_revision = "0003_periods"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "attestation_criterion_templates",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("period_type", sa.String(length=50), nullable=False),
        sa.Column("program_duration_years", sa.Integer(), nullable=False),
        sa.Column("course", sa.Integer(), nullable=False),
        sa.Column("season", sa.String(length=20), nullable=False),
        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
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
            "period_type",
            "program_duration_years",
            "course",
            "season",
            name="uq_attestation_criterion_templates_lookup",
        ),
        sa.CheckConstraint(
            "period_type in ('attestation', 'department_seminar')",
            name="chk_criterion_templates_period_type",
        ),
        sa.CheckConstraint(
            "program_duration_years in (3, 4)",
            name="chk_criterion_templates_program_duration",
        ),
        sa.CheckConstraint(
            "course >= 1",
            name="chk_criterion_templates_course_positive",
        ),
        sa.CheckConstraint(
            "season in ('spring', 'autumn')",
            name="chk_criterion_templates_season",
        ),
    )

    op.create_index(
        "ix_attestation_criterion_templates_lookup",
        "attestation_criterion_templates",
        ["period_type", "program_duration_years", "course", "season"],
    )

    op.create_table(
        "attestation_criteria",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "template_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("attestation_criterion_templates.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("code", sa.String(length=100), nullable=False),
        sa.Column("name", sa.String(length=500), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("evaluation_type", sa.String(length=50), nullable=False),
        sa.Column("max_score", sa.Numeric(6, 2), nullable=True),
        sa.Column("unit_label", sa.String(length=100), nullable=True),
        sa.Column(
            "checked_by_student",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column(
            "checked_by_supervisor",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column(
            "sort_order",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("0"),
        ),
        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
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
            "template_id",
            "code",
            name="uq_attestation_criteria_template_code",
        ),
        sa.CheckConstraint(
            "evaluation_type in ('score', 'boolean', 'count')",
            name="chk_attestation_criteria_evaluation_type",
        ),
        sa.CheckConstraint(
            "max_score is null or max_score >= 0",
            name="chk_attestation_criteria_max_score_non_negative",
        ),
        sa.CheckConstraint(
            "(evaluation_type = 'score' and max_score is not null) "
            "or (evaluation_type in ('boolean', 'count'))",
            name="chk_attestation_criteria_score_requires_max_score",
        ),
        sa.CheckConstraint(
            "checked_by_student or checked_by_supervisor",
            name="chk_attestation_criteria_checked_by_someone",
        ),
    )

    op.create_index("ix_attestation_criteria_template_id", "attestation_criteria", ["template_id"])
    op.create_index("ix_attestation_criteria_sort_order", "attestation_criteria", ["template_id", "sort_order"])


def downgrade() -> None:
    op.drop_index("ix_attestation_criteria_sort_order", table_name="attestation_criteria")
    op.drop_index("ix_attestation_criteria_template_id", table_name="attestation_criteria")
    op.drop_table("attestation_criteria")

    op.drop_index(
        "ix_attestation_criterion_templates_lookup",
        table_name="attestation_criterion_templates",
    )
    op.drop_table("attestation_criterion_templates")