"""add criterion groups and normalized scores

Revision ID: 0014_norm_eval
Revises: 0013_man_tabl
Create Date: 2026-05-04
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


revision: str = "0014_norm_eval"
down_revision: Union[str, None] = "0013_man_tabl"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE attestation_criteria "
        "ADD COLUMN IF NOT EXISTS group_code varchar(100)"
    )
    op.execute(
        "ALTER TABLE attestation_criteria "
        "ADD COLUMN IF NOT EXISTS group_name varchar(255)"
    )
    op.execute(
        "ALTER TABLE attestation_criteria "
        "ADD COLUMN IF NOT EXISTS group_sort_order integer"
    )
    op.execute(
        "ALTER TABLE attestation_criteria "
        "ADD COLUMN IF NOT EXISTS count_norm numeric(10, 2)"
    )

    op.execute(
        "ALTER TABLE student_attestation_criteria "
        "ADD COLUMN IF NOT EXISTS group_code varchar(100)"
    )
    op.execute(
        "ALTER TABLE student_attestation_criteria "
        "ADD COLUMN IF NOT EXISTS group_name varchar(255)"
    )
    op.execute(
        "ALTER TABLE student_attestation_criteria "
        "ADD COLUMN IF NOT EXISTS group_sort_order integer"
    )
    op.execute(
        "ALTER TABLE student_attestation_criteria "
        "ADD COLUMN IF NOT EXISTS count_norm numeric(10, 2)"
    )

    op.execute(
        "ALTER TABLE commission_member_criterion_evaluations "
        "ADD COLUMN IF NOT EXISTS normalized_score numeric(8, 4)"
    )

    op.execute(
        "ALTER TABLE commission_member_evaluations "
        "ADD COLUMN IF NOT EXISTS logic_hypothesis_score numeric(8, 4)"
    )
    op.execute(
        "ALTER TABLE commission_member_evaluations "
        "ADD COLUMN IF NOT EXISTS methods_score numeric(8, 4)"
    )
    op.execute(
        "ALTER TABLE commission_member_evaluations "
        "ADD COLUMN IF NOT EXISTS scientific_foundation_score numeric(8, 4)"
    )
    op.execute(
        "ALTER TABLE commission_member_evaluations "
        "ADD COLUMN IF NOT EXISTS text_progress_score numeric(8, 4)"
    )
    op.execute(
        "ALTER TABLE commission_member_evaluations "
        "ADD COLUMN IF NOT EXISTS overall_integral_score numeric(8, 4)"
    )

    op.execute(
        "ALTER TABLE commission_member_evaluations "
        "DROP CONSTRAINT IF EXISTS chk_member_evaluations_overall_recommendation"
    )
    op.execute(
        "ALTER TABLE commission_member_evaluations "
        "DROP CONSTRAINT IF EXISTS chk_member_evals_recommendation"
    )


def downgrade() -> None:
    op.execute(
        "ALTER TABLE commission_member_evaluations "
        "DROP COLUMN IF EXISTS overall_integral_score"
    )
    op.execute(
        "ALTER TABLE commission_member_evaluations "
        "DROP COLUMN IF EXISTS text_progress_score"
    )
    op.execute(
        "ALTER TABLE commission_member_evaluations "
        "DROP COLUMN IF EXISTS scientific_foundation_score"
    )
    op.execute(
        "ALTER TABLE commission_member_evaluations "
        "DROP COLUMN IF EXISTS methods_score"
    )
    op.execute(
        "ALTER TABLE commission_member_evaluations "
        "DROP COLUMN IF EXISTS logic_hypothesis_score"
    )

    op.execute(
        "ALTER TABLE commission_member_criterion_evaluations "
        "DROP COLUMN IF EXISTS normalized_score"
    )

    op.execute(
        "ALTER TABLE student_attestation_criteria "
        "DROP COLUMN IF EXISTS count_norm"
    )
    op.execute(
        "ALTER TABLE student_attestation_criteria "
        "DROP COLUMN IF EXISTS group_sort_order"
    )
    op.execute(
        "ALTER TABLE student_attestation_criteria "
        "DROP COLUMN IF EXISTS group_name"
    )
    op.execute(
        "ALTER TABLE student_attestation_criteria "
        "DROP COLUMN IF EXISTS group_code"
    )

    op.execute(
        "ALTER TABLE attestation_criteria "
        "DROP COLUMN IF EXISTS count_norm"
    )
    op.execute(
        "ALTER TABLE attestation_criteria "
        "DROP COLUMN IF EXISTS group_sort_order"
    )
    op.execute(
        "ALTER TABLE attestation_criteria "
        "DROP COLUMN IF EXISTS group_name"
    )
    op.execute(
        "ALTER TABLE attestation_criteria "
        "DROP COLUMN IF EXISTS group_code"
    )

    op.execute(
        """
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM pg_constraint
                WHERE conname = 'chk_member_evaluations_overall_recommendation'
            ) THEN
                ALTER TABLE commission_member_evaluations
                ADD CONSTRAINT chk_member_evaluations_overall_recommendation
                CHECK (
                    overall_recommendation IS NULL
                    OR overall_recommendation IN (
                        'passed',
                        'passed_conditionally',
                        'revision_required',
                        'not_passed'
                    )
                );
            END IF;
        END
        $$;
        """
    )