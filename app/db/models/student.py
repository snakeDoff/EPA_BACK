from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, CheckConstraint, ForeignKey, Index, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPKMixin

if TYPE_CHECKING:
    from app.db.models.department import Department
    from app.db.models.education_program import EducationProgram
    from app.db.models.user import User


class Student(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "students"
    __table_args__ = (
        CheckConstraint("course >= 1", name="chk_students_course_positive"),
        CheckConstraint(
            "admission_year is null or admission_year >= 2000",
            name="chk_students_admission_year",
        ),
        Index("ix_students_department_id", "department_id"),
        Index("ix_students_supervisor_user_id", "supervisor_user_id"),
        Index("ix_students_course", "course"),
        Index("ix_students_academic_status", "academic_status"),
        Index("ix_students_education_program_id", "education_program_id"),
    )

    user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        unique=True,
    )

    last_name: Mapped[str] = mapped_column(String(100), nullable=False)
    first_name: Mapped[str] = mapped_column(String(100), nullable=False)
    middle_name: Mapped[str | None] = mapped_column(String(100), nullable=True)

    email: Mapped[str | None] = mapped_column(String(255), nullable=True)

    admission_year: Mapped[int | None] = mapped_column(Integer, nullable=True)
    course: Mapped[int] = mapped_column(Integer, nullable=False)

    funding_type: Mapped[str | None] = mapped_column(String(100), nullable=True)

    education_program_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("education_programs.id", ondelete="RESTRICT"),
        nullable=False,
    )
    education_program_raw: Mapped[str | None] = mapped_column(String(500), nullable=True)

    specialty: Mapped[str | None] = mapped_column(String(255), nullable=True)
    academic_status: Mapped[str] = mapped_column(String(100), nullable=False)

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
    supervisor_name_raw: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    dissertation_topic: Mapped[str | None] = mapped_column(Text, nullable=True)
    status_change_reason: Mapped[str | None] = mapped_column(Text, nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    user: Mapped["User | None"] = relationship(
        back_populates="student_profile",
        foreign_keys=[user_id],
    )

    supervisor: Mapped["User | None"] = relationship(
        back_populates="supervised_students",
        foreign_keys=[supervisor_user_id],
    )

    department: Mapped["Department"] = relationship(back_populates="students")
    education_program: Mapped["EducationProgram"] = relationship(back_populates="students")