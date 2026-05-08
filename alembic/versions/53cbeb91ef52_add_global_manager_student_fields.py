
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


revision: str = "0013_man_tabl"
down_revision: Union[str, None] = "0012_comm_member_note"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "students",
        sa.Column("publications_count", sa.Integer(), nullable=True),
    )
    op.add_column(
        "students",
        sa.Column("pedagogical_practice", sa.Boolean(), nullable=True),
    )
    op.add_column(
        "students",
        sa.Column("research_practice", sa.Boolean(), nullable=True),
    )
    op.add_column(
        "students",
        sa.Column("implementation_act", sa.Boolean(), nullable=True),
    )
    op.add_column(
        "students",
        sa.Column("predefense_date", sa.Date(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("students", "predefense_date")
    op.drop_column("students", "implementation_act")
    op.drop_column("students", "research_practice")
    op.drop_column("students", "pedagogical_practice")
    op.drop_column("students", "publications_count")