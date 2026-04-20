from __future__ import annotations

import uuid
from datetime import date, time
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, Date, ForeignKey, Index, Integer, String, Text, Time
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPKMixin

if TYPE_CHECKING:
    from app.db.models.department import Department
    from app.db.models.staff_member import StaffMember
    from app.db.models.student_attestation import StudentAttestation


class AttestationCommission(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "attestation_commissions"
    __table_args__ = (
        Index("ix_attestation_commissions_attestation_period_id", "attestation_period_id"),
        Index("ix_attestation_commissions_department_id", "department_id"),
        Index("ix_attestation_commissions_status", "status"),
        Index("ix_attestation_commissions_created_by", "created_by"),
    )

    attestation_period_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("attestation_periods.id", ondelete="CASCADE"),
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

    meeting_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    start_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    end_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    meeting_location: Mapped[str | None] = mapped_column(String(255), nullable=True)

    created_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )

    department: Mapped["Department"] = relationship()
    members: Mapped[list["CommissionMember"]] = relationship(
        back_populates="commission",
        cascade="all, delete-orphan",
    )
    student_attestations: Mapped[list["StudentAttestation"]] = relationship(
        back_populates="commission"
    )


class CommissionMember(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "commission_members"
    __table_args__ = (
        Index("ix_commission_members_commission_id", "commission_id"),
        Index("ix_commission_members_staff_member_id", "staff_member_id"),
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
    participation_note: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_voting_member: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    commission: Mapped["AttestationCommission"] = relationship(
        back_populates="members"
    )
    staff_member: Mapped["StaffMember"] = relationship(
        back_populates="commission_memberships"
    )