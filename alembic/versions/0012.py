from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "0012_comm_member_note"
down_revision = "0011_commission_schedule"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "commission_members",
        sa.Column("participation_note", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("commission_members", "participation_note")