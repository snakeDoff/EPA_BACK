from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr, field_validator


class ManagerStudentRow(BaseModel):
    student_id: UUID
    user_id: UUID | None

    admission_year: int | None
    course: int
    fio: str
    email: EmailStr | None

    funding_type: str | None
    education_program_id: UUID | None
    education_program_name: str | None
    specialty: str | None

    academic_status: str | None
    department_id: UUID | None
    department_name: str | None

    supervisor_user_id: UUID | None
    supervisor_name: str | None
    supervisor_name_raw: str | None

    dissertation_topic: str | None
    status_change_reason: str | None
    is_active: bool

    created_at: datetime
    updated_at: datetime


class ManagerStudentRead(ManagerStudentRow):
    pass


class ManagerStudentUpdatePayload(BaseModel):
    admission_year: int | None = None
    course: int | None = None
    funding_type: str | None = None
    education_program_id: UUID | None = None
    specialty: str | None = None
    academic_status: str | None = None
    department_id: UUID | None = None
    supervisor_user_id: UUID | None = None
    supervisor_name_raw: str | None = None
    dissertation_topic: str | None = None
    status_change_reason: str | None = None
    is_active: bool | None = None

    @field_validator(
        "funding_type",
        "specialty",
        "academic_status",
        "supervisor_name_raw",
        "dissertation_topic",
        "status_change_reason",
        mode="before",
    )
    @classmethod
    def strip_optional_strings(cls, value: object) -> object:
        if value is None:
            return None
        if isinstance(value, str):
            value = value.strip()
            return value or None
        return value