from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPKMixin

if TYPE_CHECKING:
    from app.db.models.attestation_commission import CommissionMember
    from app.db.models.student_attestation import StudentAttestation, StudentAttestationCriterion


class CommissionMemberEvaluation(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "commission_member_evaluations"
    __table_args__ = (
        UniqueConstraint(
            "student_attestation_id",
            "commission_member_id",
            name="uq_member_evaluations_attestation_member",
        ),
        CheckConstraint(
            "status in ('draft', 'submitted')",
            name="chk_member_evaluations_status",
        ),
        CheckConstraint(
            "overall_recommendation is null or overall_recommendation in "
            "('passed', 'passed_conditionally', 'revision_required', 'not_passed')",
            name="chk_member_evaluations_overall_recommendation",
        ),
        Index("ix_member_evaluations_student_attestation_id", "student_attestation_id"),
        Index("ix_member_evaluations_commission_member_id", "commission_member_id"),
        Index("ix_member_evaluations_status", "status"),
    )

    student_attestation_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("student_attestations.id", ondelete="CASCADE"),
        nullable=False,
    )
    commission_member_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("commission_members.id", ondelete="CASCADE"),
        nullable=False,
    )

    status: Mapped[str] = mapped_column(String(50), nullable=False, default="draft")
    overall_comment: Mapped[str | None] = mapped_column(Text, nullable=True)
    overall_recommendation: Mapped[str | None] = mapped_column(String(50), nullable=True)
    submitted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    student_attestation: Mapped["StudentAttestation"] = relationship(back_populates="member_evaluations")
    commission_member: Mapped["CommissionMember"] = relationship(back_populates="evaluations")

    criterion_values: Mapped[list["CommissionMemberCriterionEvaluation"]] = relationship(
        back_populates="member_evaluation",
        cascade="all, delete-orphan",
        order_by="CommissionMemberCriterionEvaluation.sort_order",
    )


class CommissionMemberCriterionEvaluation(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "commission_member_criterion_evaluations"
    __table_args__ = (
        UniqueConstraint(
            "member_evaluation_id",
            "student_attestation_criterion_id",
            name="uq_member_criterion_evaluations_eval_criterion",
        ),
        CheckConstraint(
            "evaluation_type in ('score', 'boolean', 'count')",
            name="chk_member_criterion_evaluations_type",
        ),
        CheckConstraint(
            "score_value is null or score_value >= 0",
            name="chk_member_criterion_evaluations_score_non_negative",
        ),
        CheckConstraint(
            "count_value is null or count_value >= 0",
            name="chk_member_criterion_evaluations_count_non_negative",
        ),
        Index("ix_member_criterion_evaluations_member_evaluation_id", "member_evaluation_id"),
        Index("ix_member_criterion_evaluations_student_attestation_criterion_id", "student_attestation_criterion_id"),
    )

    member_evaluation_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("commission_member_evaluations.id", ondelete="CASCADE"),
        nullable=False,
    )
    student_attestation_criterion_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("student_attestation_criteria.id", ondelete="RESTRICT"),
        nullable=False,
    )

    evaluation_type: Mapped[str] = mapped_column(String(50), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    score_value: Mapped[Decimal | None] = mapped_column(Numeric(6, 2), nullable=True)
    boolean_value: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    count_value: Mapped[int | None] = mapped_column(Integer, nullable=True)

    comment: Mapped[str | None] = mapped_column(Text, nullable=True)

    member_evaluation: Mapped["CommissionMemberEvaluation"] = relationship(back_populates="criterion_values")
    student_attestation_criterion: Mapped["StudentAttestationCriterion"] = relationship()