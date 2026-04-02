from __future__ import annotations

import uuid
from datetime import date
from typing import TYPE_CHECKING

from sqlalchemy import CheckConstraint, ForeignKey, Index, Integer, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPKMixin

if TYPE_CHECKING:
    from app.db.models.user import User


class AttestationPeriod(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "attestation_periods"
    __table_args__ = (
        UniqueConstraint(
            "type",
            "year",
            "season",
            name="uq_attestation_periods_type_year_season",
        ),
        CheckConstraint(
            "type in ('attestation', 'department_seminar')",
            name="chk_attestation_periods_type",
        ),
        CheckConstraint(
            "season in ('spring', 'autumn')",
            name="chk_attestation_periods_season",
        ),
        CheckConstraint(
            "status in ('draft', 'active', 'completed', 'archived')",
            name="chk_attestation_periods_status",
        ),
        CheckConstraint(
            "start_date <= end_date",
            name="chk_attestation_periods_dates",
        ),
        CheckConstraint(
            "year >= 2000",
            name="chk_attestation_periods_year",
        ),
        Index("ix_attestation_periods_type", "type"),
        Index("ix_attestation_periods_status", "status"),
        Index("ix_attestation_periods_year_season", "year", "season"),
    )

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    type: Mapped[str] = mapped_column(String(50), nullable=False)
    year: Mapped[int] = mapped_column(Integer, nullable=False)
    season: Mapped[str] = mapped_column(String(20), nullable=False)

    start_date: Mapped[date] = mapped_column(nullable=False)
    end_date: Mapped[date] = mapped_column(nullable=False)

    status: Mapped[str] = mapped_column(String(50), nullable=False, default="draft")

    created_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )