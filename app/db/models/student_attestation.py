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
    from app.db.models.attestation_commission import AttestationCommission
    from app.db.models.attestation_criterion import AttestationCriterion, AttestationCriterionTemplate
    from app.db.models.attestation_period import AttestationPeriod
    from app.db.models.commission_evaluation import CommissionMemberEvaluation
    from app.db.models.department import Department
    from app.db.models.student import Student
    from app.db.models.user import User


class StudentAttestation(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "student_attestations"
    __table_args__ = (
        UniqueConstraint(
            "attestation_period_id",
            "student_id",
            name="uq_student_attestations_period_student",
        ),
        CheckConstraint(
            "status in ('draft', 'admitted', 'ready_for_commission', 'scheduled', 'attested', 'result_sent')",
            name="chk_student_attestations_status",
        ),
        CheckConstraint(
            "final_decision is null or final_decision in ('passed', 'passed_conditionally', 'revision_required', 'not_passed')",
            name="chk_student_attestations_final_decision",
        ),
        Index("ix_student_attestations_period_id", "attestation_period_id"),
        Index("ix_student_attestations_student_id", "student_id"),
        Index("ix_student_attestations_department_id", "department_id"),
        Index("ix_student_attestations_status", "status"),
        Index("ix_student_attestations_criterion_template_id", "criterion_template_id"),
        Index("ix_student_attestations_commission_id", "commission_id"),
    )

    attestation_period_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("attestation_periods.id", ondelete="RESTRICT"),
        nullable=False,
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("students.id", ondelete="RESTRICT"),
        nullable=False,
    )

    department_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("departments.id", ondelete="RESTRICT"),
        nullable=False,
    )
    supervisor_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )

    criterion_template_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("attestation_criterion_templates.id", ondelete="RESTRICT"),
        nullable=False,
    )

    commission_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("attestation_commissions.id", ondelete="SET NULL"),
        nullable=True,
    )

    status: Mapped[str] = mapped_column(String(50), nullable=False, default="draft")
    is_admitted: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    admission_comment: Mapped[str | None] = mapped_column(Text, nullable=True)
    debt_note: Mapped[str | None] = mapped_column(Text, nullable=True)

    final_decision: Mapped[str | None] = mapped_column(String(50), nullable=True)
    final_comment: Mapped[str | None] = mapped_column(Text, nullable=True)
    result_sent_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    period: Mapped["AttestationPeriod"] = relationship()
    student: Mapped["Student"] = relationship()
    department: Mapped["Department"] = relationship()
    supervisor: Mapped["User | None"] = relationship(foreign_keys=[supervisor_user_id])
    criterion_template: Mapped["AttestationCriterionTemplate"] = relationship()
    commission: Mapped["AttestationCommission | None"] = relationship(back_populates="student_attestations")

    criteria: Mapped[list["StudentAttestationCriterion"]] = relationship(
        back_populates="student_attestation",
        cascade="all, delete-orphan",
        order_by="StudentAttestationCriterion.sort_order",
    )
    member_evaluations: Mapped[list["CommissionMemberEvaluation"]] = relationship(
        back_populates="student_attestation",
        cascade="all, delete-orphan",
    )


class StudentAttestationCriterion(UUIDPKMixin, Base):
    __tablename__ = "student_attestation_criteria"
    __table_args__ = (
        UniqueConstraint(
            "student_attestation_id",
            "code",
            name="uq_student_attestation_criteria_attestation_code",
        ),
        CheckConstraint(
            "evaluation_type in ('score', 'boolean', 'count')",
            name="chk_student_attestation_criteria_evaluation_type",
        ),
        CheckConstraint(
            "max_score is null or max_score >= 0",
            name="chk_student_attestation_criteria_max_score_non_negative",
        ),
        CheckConstraint(
            "(evaluation_type = 'score' and max_score is not null) "
            "or (evaluation_type in ('boolean', 'count'))",
            name="chk_student_attestation_criteria_score_requires_max_score",
        ),
        CheckConstraint(
            "checked_by_student or checked_by_supervisor",
            name="chk_student_attestation_criteria_checked_by_someone",
        ),
        Index("ix_student_attestation_criteria_student_attestation_id", "student_attestation_id"),
        Index("ix_student_attestation_criteria_sort_order", "student_attestation_id", "sort_order"),
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    student_attestation_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("student_attestations.id", ondelete="CASCADE"),
        nullable=False,
    )
    template_criterion_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("attestation_criteria.id", ondelete="RESTRICT"),
        nullable=False,
    )

    code: Mapped[str] = mapped_column(String(100), nullable=False)
    name: Mapped[str] = mapped_column(String(500), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    evaluation_type: Mapped[str] = mapped_column(String(50), nullable=False)
    max_score: Mapped[Decimal | None] = mapped_column(Numeric(6, 2), nullable=True)
    unit_label: Mapped[str | None] = mapped_column(String(100), nullable=True)

    checked_by_student: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    checked_by_supervisor: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    student_attestation: Mapped["StudentAttestation"] = relationship(back_populates="criteria")
    template_criterion: Mapped["AttestationCriterion"] = relationship()