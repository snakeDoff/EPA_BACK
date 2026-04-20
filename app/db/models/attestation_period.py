from __future__ import annotations

from datetime import date
from typing import TYPE_CHECKING

from sqlalchemy import CheckConstraint, Date, Index, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPKMixin

if TYPE_CHECKING:
    from app.db.models.student_attestation import StudentAttestation


class AttestationPeriod(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "attestation_periods"
    __table_args__ = (
        CheckConstraint(
            "type in ('attestation', 'department_seminar')",
            name="chk_attestation_periods_type",
        ),
        CheckConstraint(
            "season in ('spring', 'autumn')",
            name="chk_attestation_periods_season",
        ),
        CheckConstraint(
            "status in ('draft', 'active', 'completed', 'cancelled')",
            name="chk_attestation_periods_status",
        ),
        CheckConstraint(
            "current_stage_number is null or current_stage_number between 1 and 6",
            name="chk_attestation_periods_current_stage_number",
        ),
        Index("ix_attestation_periods_type", "type"),
        Index("ix_attestation_periods_year", "year"),
        Index("ix_attestation_periods_season", "season"),
        Index("ix_attestation_periods_status", "status"),
        Index("ix_attestation_periods_is_active", "is_active"),
        Index("ix_attestation_periods_is_completed", "is_completed"),
    )

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    type: Mapped[str] = mapped_column(String(50), nullable=False)
    year: Mapped[int] = mapped_column(nullable=False)
    season: Mapped[str] = mapped_column(String(20), nullable=False)

    start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    status: Mapped[str] = mapped_column(String(50), nullable=False, default="draft")
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    is_active: Mapped[bool] = mapped_column(nullable=False, default=False)
    is_completed: Mapped[bool] = mapped_column(nullable=False, default=False)
    current_stage_number: Mapped[int | None] = mapped_column(Integer, nullable=True)

    student_attestations: Mapped[list["StudentAttestation"]] = relationship(back_populates="period")