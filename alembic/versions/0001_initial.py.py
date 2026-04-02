from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "0001_initial.py"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    print("MIGRATION UPGRADE STARTED")

    op.execute("create extension if not exists pgcrypto")

    op.create_table(
        "users",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("password_hash", sa.String(length=255), nullable=True),
        sa.Column("last_name", sa.String(length=100), nullable=False),
        sa.Column("first_name", sa.String(length=100), nullable=False),
        sa.Column("middle_name", sa.String(length=100), nullable=True),
        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
        sa.Column(
            "is_deleted",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column("last_login_at", sa.DateTime(timezone=True), nullable=True),
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
    )
    op.create_index(
        "ux_users_email",
        "users",
        [sa.text("lower(email)")],
        unique=True,
        postgresql_where=sa.text("is_deleted = false"),
    )

    op.create_table(
        "roles",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("code", sa.String(length=50), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
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
    )
    op.create_index("ux_roles_code", "roles", ["code"], unique=True)

    op.create_table(
        "departments",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("short_name", sa.String(length=100), nullable=True),
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
    )
    op.create_index(
        "ux_departments_name",
        "departments",
        [sa.text("lower(name)")],
        unique=True,
    )
    op.create_index(
        "ux_departments_short_name",
        "departments",
        [sa.text("lower(short_name)")],
        unique=True,
        postgresql_where=sa.text("short_name is not null"),
    )

    op.create_table(
        "user_roles",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "role_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("roles.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column(
            "department_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("departments.id", ondelete="RESTRICT"),
            nullable=True,
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
            "user_id",
            "role_id",
            "department_id",
            name="uq_user_roles_user_role_department",
        ),
    )
    op.create_index("ix_user_roles_user_id", "user_roles", ["user_id"])
    op.create_index("ix_user_roles_role_id", "user_roles", ["role_id"])
    op.create_index("ix_user_roles_department_id", "user_roles", ["department_id"])

    op.create_table(
        "students",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
            unique=True,
        ),
        sa.Column("last_name", sa.String(length=100), nullable=False),
        sa.Column("first_name", sa.String(length=100), nullable=False),
        sa.Column("middle_name", sa.String(length=100), nullable=True),
        sa.Column("email", sa.String(length=255), nullable=True),
        sa.Column("admission_year", sa.Integer(), nullable=True),
        sa.Column("course", sa.Integer(), nullable=False),
        sa.Column("program_duration_years", sa.Integer(), nullable=False),
        sa.Column("funding_type", sa.String(length=100), nullable=True),
        sa.Column("education_program", sa.String(length=500), nullable=False),
        sa.Column("specialty", sa.String(length=255), nullable=True),
        sa.Column("academic_status", sa.String(length=100), nullable=False),
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
        sa.Column("supervisor_name_raw", sa.String(length=255), nullable=True),
        sa.Column("dissertation_topic", sa.Text(), nullable=True),
        sa.Column("status_change_reason", sa.Text(), nullable=True),
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
        sa.CheckConstraint("course >= 1", name="chk_students_course_positive"),
        sa.CheckConstraint(
            "program_duration_years in (3, 4)",
            name="chk_students_program_duration",
        ),
        sa.CheckConstraint(
            "admission_year is null or admission_year >= 2000",
            name="chk_students_admission_year",
        ),
    )
    op.create_index("ix_students_department_id", "students", ["department_id"])
    op.create_index("ix_students_supervisor_user_id", "students", ["supervisor_user_id"])
    op.create_index("ix_students_course", "students", ["course"])
    op.create_index(
        "ix_students_program_duration_years",
        "students",
        ["program_duration_years"],
    )
    op.create_index("ix_students_academic_status", "students", ["academic_status"])
    op.create_index(
        "ux_students_email",
        "students",
        [sa.text("lower(email)")],
        unique=True,
        postgresql_where=sa.text("email is not null"),
    )

    print("MIGRATION UPGRADE FINISHED")


def downgrade() -> None:
    print("MIGRATION DOWNGRADE STARTED")

    op.drop_index("ux_students_email", table_name="students")
    op.drop_index("ix_students_academic_status", table_name="students")
    op.drop_index("ix_students_program_duration_years", table_name="students")
    op.drop_index("ix_students_course", table_name="students")
    op.drop_index("ix_students_supervisor_user_id", table_name="students")
    op.drop_index("ix_students_department_id", table_name="students")
    op.drop_table("students")

    op.drop_index("ix_user_roles_department_id", table_name="user_roles")
    op.drop_index("ix_user_roles_role_id", table_name="user_roles")
    op.drop_index("ix_user_roles_user_id", table_name="user_roles")
    op.drop_table("user_roles")

    op.drop_index("ux_departments_short_name", table_name="departments")
    op.drop_index("ux_departments_name", table_name="departments")
    op.drop_table("departments")

    op.drop_index("ux_roles_code", table_name="roles")
    op.drop_table("roles")

    op.drop_index("ux_users_email", table_name="users")
    op.drop_table("users")

    print("MIGRATION DOWNGRADE FINISHED")