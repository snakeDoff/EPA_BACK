from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "0009_att_lifecycle"
down_revision = "0008_member_eval"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "attestation_periods",
        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
    )
    op.add_column(
        "attestation_periods",
        sa.Column(
            "is_completed",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
    )
    op.add_column(
        "attestation_periods",
        sa.Column(
            "current_stage_number",
            sa.Integer(),
            nullable=True,
        ),
    )

    op.create_check_constraint(
        "chk_attestation_periods_current_stage_number",
        "attestation_periods",
        "current_stage_number is null or current_stage_number between 1 and 6",
    )

    op.create_index("ix_attestation_periods_is_active", "attestation_periods", ["is_active"])
    op.create_index("ix_attestation_periods_is_completed", "attestation_periods", ["is_completed"])

    op.execute(
        """
        update attestation_periods
        set is_active = (status = 'active'),
            is_completed = (status = 'completed')
        """
    )


def downgrade() -> None:
    op.drop_index("ix_attestation_periods_is_completed", table_name="attestation_periods")
    op.drop_index("ix_attestation_periods_is_active", table_name="attestation_periods")
    op.drop_constraint(
        "chk_attestation_periods_current_stage_number",
        "attestation_periods",
        type_="check",
    )
    op.drop_column("attestation_periods", "current_stage_number")
    op.drop_column("attestation_periods", "is_completed")
    op.drop_column("attestation_periods", "is_active")