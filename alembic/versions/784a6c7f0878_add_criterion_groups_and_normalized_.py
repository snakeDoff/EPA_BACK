from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


revision = "0014_norm_eval"
down_revision = "0013_man_tabl"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "attestation_criteria",
        sa.Column("group_code", sa.String(length=100), nullable=True),
    )
    op.add_column(
        "attestation_criteria",
        sa.Column("group_name", sa.String(length=255), nullable=True),
    )
    op.add_column(
        "attestation_criteria",
        sa.Column("group_sort_order", sa.Integer(), nullable=True),
    )
    op.add_column(
        "attestation_criteria",
        sa.Column("count_norm", sa.Numeric(10, 2), nullable=True),
    )

    op.add_column(
        "student_attestation_criteria",
        sa.Column("group_code", sa.String(length=100), nullable=True),
    )
    op.add_column(
        "student_attestation_criteria",
        sa.Column("group_name", sa.String(length=255), nullable=True),
    )
    op.add_column(
        "student_attestation_criteria",
        sa.Column("group_sort_order", sa.Integer(), nullable=True),
    )
    op.add_column(
        "student_attestation_criteria",
        sa.Column("count_norm", sa.Numeric(10, 2), nullable=True),
    )

    op.add_column(
        "commission_member_criterion_evaluations",
        sa.Column("normalized_score", sa.Numeric(8, 4), nullable=True),
    )

    op.add_column(
        "commission_member_evaluations",
        sa.Column("logic_hypothesis_score", sa.Numeric(8, 4), nullable=True),
    )
    op.add_column(
        "commission_member_evaluations",
        sa.Column("methods_score", sa.Numeric(8, 4), nullable=True),
    )
    op.add_column(
        "commission_member_evaluations",
        sa.Column("scientific_foundation_score", sa.Numeric(8, 4), nullable=True),
    )
    op.add_column(
        "commission_member_evaluations",
        sa.Column("text_progress_score", sa.Numeric(8, 4), nullable=True),
    )
    op.add_column(
        "commission_member_evaluations",
        sa.Column("overall_integral_score", sa.Numeric(8, 4), nullable=True),
    )

    op.drop_constraint(
        "chk_member_evaluations_overall_recommendation",
        "commission_member_evaluations",
        type_="check",
    )
    op.drop_constraint(
        "chk_member_evals_recommendation",
        "commission_member_evaluations",
        type_="check",
    )


def downgrade() -> None:
    op.create_check_constraint(
        "chk_member_evaluations_overall_recommendation",
        "commission_member_evaluations",
        "overall_recommendation is null or overall_recommendation in "
        "('passed', 'passed_conditionally', 'revision_required', 'not_passed')",
    )

    op.drop_column("commission_member_evaluations", "overall_integral_score")
    op.drop_column("commission_member_evaluations", "text_progress_score")
    op.drop_column("commission_member_evaluations", "scientific_foundation_score")
    op.drop_column("commission_member_evaluations", "methods_score")
    op.drop_column("commission_member_evaluations", "logic_hypothesis_score")

    op.drop_column("commission_member_criterion_evaluations", "normalized_score")

    op.drop_column("student_attestation_criteria", "count_norm")
    op.drop_column("student_attestation_criteria", "group_sort_order")
    op.drop_column("student_attestation_criteria", "group_name")
    op.drop_column("student_attestation_criteria", "group_code")

    op.drop_column("attestation_criteria", "count_norm")
    op.drop_column("attestation_criteria", "group_sort_order")
    op.drop_column("attestation_criteria", "group_name")
    op.drop_column("attestation_criteria", "group_code")