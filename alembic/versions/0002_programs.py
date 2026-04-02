from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "0002_programs"
down_revision = "0001_initial.py"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "education_programs",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("name", sa.String(length=500), nullable=False),
        sa.Column("short_name", sa.String(length=255), nullable=True),
        sa.Column("duration_years", sa.SmallInteger(), nullable=False),
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
        sa.CheckConstraint(
            "duration_years in (3, 4)",
            name="chk_education_programs_duration",
        ),
    )
    op.create_index(
        "ux_education_programs_name",
        "education_programs",
        [sa.text("lower(name)")],
        unique=True,
    )

    op.add_column("students", sa.Column("education_program_id", postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column("students", sa.Column("education_program_raw", sa.String(length=500), nullable=True))
    op.create_index("ix_students_education_program_id", "students", ["education_program_id"])
    op.create_foreign_key(
        "fk_students_education_program_id",
        "students",
        "education_programs",
        ["education_program_id"],
        ["id"],
        ondelete="RESTRICT",
    )

    # временно переносим старую строковую программу в raw
    op.execute(
        """
        update students
        set education_program_raw = education_program
        """
    )

    op.drop_column("students", "program_duration_years")
    op.drop_column("students", "education_program")


def downgrade() -> None:
    op.add_column("students", sa.Column("education_program", sa.String(length=500), nullable=True))
    op.add_column("students", sa.Column("program_duration_years", sa.Integer(), nullable=True))

    op.execute(
        """
        update students
        set education_program = education_program_raw
        """
    )

    op.drop_constraint("fk_students_education_program_id", "students", type_="foreignkey")
    op.drop_index("ix_students_education_program_id", table_name="students")
    op.drop_column("students", "education_program_raw")
    op.drop_column("students", "education_program_id")

    op.drop_index("ux_education_programs_name", table_name="education_programs")
    op.drop_table("education_programs")