from __future__ import annotations

import uuid
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPKMixin


class AttestationCriterionTemplate(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "attestation_criterion_templates"
    __table_args__ = (
        UniqueConstraint(
            "period_type",
            "program_duration_years",
            "course",
            "season",
            name="uq_attestation_criterion_templates_lookup",
        ),
        CheckConstraint(
            "period_type in ('attestation', 'department_seminar')",
            name="chk_criterion_templates_period_type",
        ),
        CheckConstraint(
            "program_duration_years in (3, 4)",
            name="chk_criterion_templates_program_duration",
        ),
        CheckConstraint(
            "course >= 1",
            name="chk_criterion_templates_course_positive",
        ),
        CheckConstraint(
            "season in ('spring', 'autumn')",
            name="chk_criterion_templates_season",
        ),
        Index(
            "ix_attestation_criterion_templates_lookup",
            "period_type",
            "program_duration_years",
            "course",
            "season",
        ),
    )

    name: Mapped[str] = mapped_column(String(255), nullable=False)

    period_type: Mapped[str] = mapped_column(String(50), nullable=False)
    program_duration_years: Mapped[int] = mapped_column(Integer, nullable=False)
    course: Mapped[int] = mapped_column(Integer, nullable=False)
    season: Mapped[str] = mapped_column(String(20), nullable=False)

    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    criteria: Mapped[list["AttestationCriterion"]] = relationship(
        back_populates="template",
        cascade="all, delete-orphan",
        order_by="AttestationCriterion.sort_order",
    )


class AttestationCriterion(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "attestation_criteria"
    __table_args__ = (
        UniqueConstraint(
            "template_id",
            "code",
            name="uq_attestation_criteria_template_code",
        ),
        CheckConstraint(
            "evaluation_type in ('score', 'boolean', 'count')",
            name="chk_attestation_criteria_evaluation_type",
        ),
        CheckConstraint(
            "max_score is null or max_score >= 0",
            name="chk_attestation_criteria_max_score_non_negative",
        ),
        CheckConstraint(
            "(evaluation_type = 'score' and max_score is not null) "
            "or (evaluation_type in ('boolean', 'count'))",
            name="chk_attestation_criteria_score_requires_max_score",
        ),
        CheckConstraint(
            "checked_by_student or checked_by_supervisor",
            name="chk_attestation_criteria_checked_by_someone",
        ),
        Index("ix_attestation_criteria_template_id", "template_id"),
        Index("ix_attestation_criteria_sort_order", "template_id", "sort_order"),
    )

    template_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("attestation_criterion_templates.id", ondelete="CASCADE"),
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
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    template: Mapped["AttestationCriterionTemplate"] = relationship(back_populates="criteria")