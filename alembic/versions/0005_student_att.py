from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "0005_student_att"
down_revision = "0004_templates"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "student_attestations",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "attestation_period_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("attestation_periods.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column(
            "student_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("students.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column(
            "department_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("departments.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column(
            "supervisor_user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "criterion_template_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("attestation_criterion_templates.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column(
            "status",
            sa.String(length=50),
            nullable=False,
            server_default=sa.text("'draft'"),
        ),
        sa.Column(
            "is_admitted",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column("admission_comment", sa.Text(), nullable=True),
        sa.Column("debt_note", sa.Text(), nullable=True),
        sa.Column("final_decision", sa.String(length=50), nullable=True),
        sa.Column("final_comment", sa.Text(), nullable=True),
        sa.Column("result_sent_at", sa.DateTime(timezone=True), nullable=True),
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
            "attestation_period_id",
            "student_id",
            name="uq_student_attestations_period_student",
        ),
        sa.CheckConstraint(
            "status in ('draft', 'admitted', 'ready_for_commission', 'scheduled', 'attested', 'result_sent')",
            name="chk_student_attestations_status",
        ),
        sa.CheckConstraint(
            "final_decision is null or final_decision in ('passed', 'passed_conditionally', 'revision_required', 'not_passed')",
            name="chk_student_attestations_final_decision",
        ),
    )

    op.create_index("ix_student_attestations_period_id", "student_attestations", ["attestation_period_id"])
    op.create_index("ix_student_attestations_student_id", "student_attestations", ["student_id"])
    op.create_index("ix_student_attestations_department_id", "student_attestations", ["department_id"])
    op.create_index("ix_student_attestations_status", "student_attestations", ["status"])
    op.create_index(
        "ix_student_attestations_criterion_template_id",
        "student_attestations",
        ["criterion_template_id"],
    )

    op.create_table(
        "student_attestation_criteria",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column(
            "student_attestation_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("student_attestations.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "template_criterion_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("attestation_criteria.id", ondelete="RESTRICT"),
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
        sa.UniqueConstraint(
            "student_attestation_id",
            "code",
            name="uq_student_attestation_criteria_attestation_code",
        ),
        sa.CheckConstraint(
            "evaluation_type in ('score', 'boolean', 'count')",
            name="chk_student_attestation_criteria_evaluation_type",
        ),
        sa.CheckConstraint(
            "max_score is null or max_score >= 0",
            name="chk_student_attestation_criteria_max_score_non_negative",
        ),
        sa.CheckConstraint(
            "(evaluation_type = 'score' and max_score is not null) "
            "or (evaluation_type in ('boolean', 'count'))",
            name="chk_student_attestation_criteria_score_requires_max_score",
        ),
        sa.CheckConstraint(
            "checked_by_student or checked_by_supervisor",
            name="chk_student_attestation_criteria_checked_by_someone",
        ),
    )

    op.create_index(
        "ix_student_attestation_criteria_student_attestation_id",
        "student_attestation_criteria",
        ["student_attestation_id"],
    )
    op.create_index(
        "ix_student_attestation_criteria_sort_order",
        "student_attestation_criteria",
        ["student_attestation_id", "sort_order"],
    )


def downgrade() -> None:
    op.drop_index("ix_student_attestation_criteria_sort_order", table_name="student_attestation_criteria")
    op.drop_index("ix_student_attestation_criteria_student_attestation_id", table_name="student_attestation_criteria")
    op.drop_table("student_attestation_criteria")

    op.drop_index("ix_student_attestations_criterion_template_id", table_name="student_attestations")
    op.drop_index("ix_student_attestations_status", table_name="student_attestations")
    op.drop_index("ix_student_attestations_department_id", table_name="student_attestations")
    op.drop_index("ix_student_attestations_student_id", table_name="student_attestations")
    op.drop_index("ix_student_attestations_period_id", table_name="student_attestations")
    op.drop_table("student_attestations")