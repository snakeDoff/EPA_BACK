from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "0008_member_eval"
down_revision = "0007_staff_ref"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "commission_member_evaluations",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "student_attestation_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("student_attestations.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "commission_member_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("commission_members.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "status",
            sa.String(length=50),
            nullable=False,
            server_default=sa.text("'draft'"),
        ),
        sa.Column("overall_comment", sa.Text(), nullable=True),
        sa.Column("overall_recommendation", sa.String(length=50), nullable=True),
        sa.Column("submitted_at", sa.DateTime(timezone=True), nullable=True),
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
            "student_attestation_id",
            "commission_member_id",
            name="uq_member_evals_attestation_member",
        ),
        sa.CheckConstraint(
            "status in ('draft', 'submitted')",
            name="chk_member_evals_status",
        ),
        sa.CheckConstraint(
            "overall_recommendation is null or overall_recommendation in "
            "('passed', 'passed_conditionally', 'revision_required', 'not_passed')",
            name="chk_member_evals_recommendation",
        ),
    )
    op.create_index(
        "ix_member_evals_attestation_id",
        "commission_member_evaluations",
        ["student_attestation_id"],
    )
    op.create_index(
        "ix_member_evals_commission_member_id",
        "commission_member_evaluations",
        ["commission_member_id"],
    )
    op.create_index(
        "ix_member_evals_status",
        "commission_member_evaluations",
        ["status"],
    )

    op.create_table(
        "commission_member_criterion_evaluations",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "member_evaluation_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("commission_member_evaluations.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "student_attestation_criterion_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("student_attestation_criteria.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("evaluation_type", sa.String(length=50), nullable=False),
        sa.Column(
            "sort_order",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("0"),
        ),
        sa.Column("score_value", sa.Numeric(6, 2), nullable=True),
        sa.Column("boolean_value", sa.Boolean(), nullable=True),
        sa.Column("count_value", sa.Integer(), nullable=True),
        sa.Column("comment", sa.Text(), nullable=True),
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
            "member_evaluation_id",
            "student_attestation_criterion_id",
            name="uq_member_crit_evals_eval_criterion",
        ),
        sa.CheckConstraint(
            "evaluation_type in ('score', 'boolean', 'count')",
            name="chk_member_crit_evals_type",
        ),
        sa.CheckConstraint(
            "score_value is null or score_value >= 0",
            name="chk_member_crit_evals_score_nonneg",
        ),
        sa.CheckConstraint(
            "count_value is null or count_value >= 0",
            name="chk_member_crit_evals_count_nonneg",
        ),
    )
    op.create_index(
        "ix_member_crit_evals_eval_id",
        "commission_member_criterion_evaluations",
        ["member_evaluation_id"],
    )
    op.create_index(
        "ix_member_crit_evals_att_criterion_id",
        "commission_member_criterion_evaluations",
        ["student_attestation_criterion_id"],
    )


def downgrade() -> None:
    op.drop_index(
        "ix_member_crit_evals_att_criterion_id",
        table_name="commission_member_criterion_evaluations",
    )
    op.drop_index(
        "ix_member_crit_evals_eval_id",
        table_name="commission_member_criterion_evaluations",
    )
    op.drop_table("commission_member_criterion_evaluations")

    op.drop_index(
        "ix_member_evals_status",
        table_name="commission_member_evaluations",
    )
    op.drop_index(
        "ix_member_evals_commission_member_id",
        table_name="commission_member_evaluations",
    )
    op.drop_index(
        "ix_member_evals_attestation_id",
        table_name="commission_member_evaluations",
    )
    op.drop_table("commission_member_evaluations")