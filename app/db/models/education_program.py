from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy import Boolean, CheckConstraint, Index, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPKMixin

if TYPE_CHECKING:
    from app.db.models.student import Student


class EducationProgram(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "education_programs"
    __table_args__ = (
        CheckConstraint(
            "duration_years in (3, 4)",
            name="chk_education_programs_duration",
        ),
        Index("ux_education_programs_name", "name", unique=True),
    )

    name: Mapped[str] = mapped_column(String(500), nullable=False)
    short_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    duration_years: Mapped[int] = mapped_column(nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    students: Mapped[list["Student"]] = relationship(back_populates="education_program")