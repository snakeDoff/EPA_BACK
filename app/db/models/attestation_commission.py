from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from sqlalchemy import CheckConstraint, ForeignKey, Index, Integer, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPKMixin

if TYPE_CHECKING:
    from app.db.models.attestation_period import AttestationPeriod
    from app.db.models.commission_evaluation import CommissionMemberEvaluation
    from app.db.models.department import Department
    from app.db.models.staff_member import StaffMember
    from app.db.models.student_attestation import StudentAttestation
    from app.db.models.user import User


class AttestationCommission(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "attestation_commissions"
    __table_args__ = (
        UniqueConstraint(
            "attestation_period_id",
            "name",
            name="uq_attestation_commissions_period_name",
        ),
        CheckConstraint(
            "status in ('draft', 'formed', 'completed')",
            name="chk_attestation_commissions_status",
        ),
        Index("ix_attestation_commissions_period_id", "attestation_period_id"),
        Index("ix_attestation_commissions_department_id", "department_id"),
        Index("ix_attestation_commissions_status", "status"),
    )

    attestation_period_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("attestation_periods.id", ondelete="RESTRICT"),
        nullable=False,
    )
    department_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("departments.id", ondelete="RESTRICT"),
        nullable=False,
    )

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    status: Mapped[str] = mapped_column(String(50), nullable=False, default="draft")
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )

    period: Mapped["AttestationPeriod"] = relationship()
    department: Mapped["Department"] = relationship()
    creator: Mapped["User | None"] = relationship(foreign_keys=[created_by])

    members: Mapped[list["CommissionMember"]] = relationship(
        back_populates="commission",
        cascade="all, delete-orphan",
        order_by="CommissionMember.sort_order",
    )

    student_attestations: Mapped[list["StudentAttestation"]] = relationship(
        back_populates="commission",
    )


class CommissionMember(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "commission_members"
    __table_args__ = (
        UniqueConstraint(
            "commission_id",
            "staff_member_id",
            name="uq_commission_members_commission_staff_member",
        ),
        CheckConstraint(
            "role_in_commission in ('chair', 'deputy_chair', 'member', 'secretary')",
            name="chk_commission_members_role",
        ),
        CheckConstraint(
            "membership_type in ('mandatory', 'additional')",
            name="chk_commission_members_membership_type",
        ),
        Index("ix_commission_members_commission_id", "commission_id"),
        Index("ix_commission_members_staff_member_id", "staff_member_id"),
        Index("ix_commission_members_sort_order", "commission_id", "sort_order"),
    )

    commission_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("attestation_commissions.id", ondelete="CASCADE"),
        nullable=False,
    )
    staff_member_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("staff_members.id", ondelete="RESTRICT"),
        nullable=False,
    )

    role_in_commission: Mapped[str] = mapped_column(String(50), nullable=False)
    membership_type: Mapped[str] = mapped_column(String(50), nullable=False)
    is_voting_member: Mapped[bool] = mapped_column(nullable=False, default=True)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    commission: Mapped["AttestationCommission"] = relationship(back_populates="members")
    staff_member: Mapped["StaffMember"] = relationship(back_populates="commission_memberships")
    evaluations: Mapped[list["CommissionMemberEvaluation"]] = relationship(
        back_populates="commission_member",
        cascade="all, delete-orphan",
    )