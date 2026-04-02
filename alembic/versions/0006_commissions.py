from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "0006_commissions"
down_revision = "0005_student_att"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "staff_members",
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
        sa.Column(
            "department_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("departments.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("last_name", sa.String(length=100), nullable=False),
        sa.Column("first_name", sa.String(length=100), nullable=False),
        sa.Column("middle_name", sa.String(length=100), nullable=True),
        sa.Column("position_title", sa.String(length=255), nullable=True),
        sa.Column("academic_degree", sa.String(length=255), nullable=True),
        sa.Column("academic_title", sa.String(length=255), nullable=True),
        sa.Column("regalia_text", sa.Text(), nullable=True),
        sa.Column("email", sa.String(length=255), nullable=True),
        sa.Column("phone", sa.String(length=50), nullable=True),
        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
        sa.Column(
            "can_be_commission_member",
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
    op.create_index("ix_staff_members_user_id", "staff_members", ["user_id"])
    op.create_index("ix_staff_members_department_id", "staff_members", ["department_id"])
    op.create_index("ix_staff_members_is_active", "staff_members", ["is_active"])
    op.create_index(
        "ix_staff_members_can_be_commission_member",
        "staff_members",
        ["can_be_commission_member"],
    )

    op.create_table(
        "attestation_commissions",
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
            "department_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("departments.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column(
            "status",
            sa.String(length=50),
            nullable=False,
            server_default=sa.text("'draft'"),
        ),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "created_by",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
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
            "attestation_period_id",
            "name",
            name="uq_attestation_commissions_period_name",
        ),
        sa.CheckConstraint(
            "status in ('draft', 'formed', 'completed')",
            name="chk_attestation_commissions_status",
        ),
    )
    op.create_index("ix_attestation_commissions_period_id", "attestation_commissions", ["attestation_period_id"])
    op.create_index("ix_attestation_commissions_department_id", "attestation_commissions", ["department_id"])
    op.create_index("ix_attestation_commissions_status", "attestation_commissions", ["status"])

    op.create_table(
        "commission_members",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "commission_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("attestation_commissions.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "staff_member_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("staff_members.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("role_in_commission", sa.String(length=50), nullable=False),
        sa.Column("membership_type", sa.String(length=50), nullable=False),
        sa.Column(
            "is_voting_member",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
        sa.Column(
            "sort_order",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("0"),
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
            "commission_id",
            "staff_member_id",
            name="uq_commission_members_commission_staff_member",
        ),
        sa.CheckConstraint(
            "role_in_commission in ('chair', 'deputy_chair', 'member', 'secretary')",
            name="chk_commission_members_role",
        ),
        sa.CheckConstraint(
            "membership_type in ('mandatory', 'additional')",
            name="chk_commission_members_membership_type",
        ),
    )
    op.create_index("ix_commission_members_commission_id", "commission_members", ["commission_id"])
    op.create_index("ix_commission_members_staff_member_id", "commission_members", ["staff_member_id"])
    op.create_index(
        "ix_commission_members_sort_order",
        "commission_members",
        ["commission_id", "sort_order"],
    )

    op.add_column(
        "student_attestations",
        sa.Column("commission_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_student_attestations_commission_id",
        "student_attestations",
        "attestation_commissions",
        ["commission_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_index("ix_student_attestations_commission_id", "student_attestations", ["commission_id"])


def downgrade() -> None:
    op.drop_index("ix_student_attestations_commission_id", table_name="student_attestations")
    op.drop_constraint("fk_student_attestations_commission_id", "student_attestations", type_="foreignkey")
    op.drop_column("student_attestations", "commission_id")

    op.drop_index("ix_commission_members_sort_order", table_name="commission_members")
    op.drop_index("ix_commission_members_staff_member_id", table_name="commission_members")
    op.drop_index("ix_commission_members_commission_id", table_name="commission_members")
    op.drop_table("commission_members")

    op.drop_index("ix_attestation_commissions_status", table_name="attestation_commissions")
    op.drop_index("ix_attestation_commissions_department_id", table_name="attestation_commissions")
    op.drop_index("ix_attestation_commissions_period_id", table_name="attestation_commissions")
    op.drop_table("attestation_commissions")

    op.drop_index("ix_staff_members_can_be_commission_member", table_name="staff_members")
    op.drop_index("ix_staff_members_is_active", table_name="staff_members")
    op.drop_index("ix_staff_members_department_id", table_name="staff_members")
    op.drop_index("ix_staff_members_user_id", table_name="staff_members")
    op.drop_table("staff_members")