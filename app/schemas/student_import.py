from __future__ import annotations

from pydantic import BaseModel, EmailStr, Field, field_validator


class StudentImportRow(BaseModel):
    last_name: str
    first_name: str
    middle_name: str | None = None

    email: EmailStr | None = None

    admission_year: int | None = None
    course: int = Field(ge=1)

    funding_type: str | None = None
    education_program_raw: str
    specialty: str | None = None
    academic_status: str

    department_name: str
    supervisor_name_raw: str | None = None

    dissertation_topic: str | None = None
    status_change_reason: str | None = None

    @field_validator(
        "last_name",
        "first_name",
        "middle_name",
        "funding_type",
        "education_program_raw",
        "specialty",
        "academic_status",
        "department_name",
        "supervisor_name_raw",
        "dissertation_topic",
        "status_change_reason",
        mode="before",
    )
    @classmethod
    def strip_strings(cls, value: object) -> object:
        if value is None:
            return None
        if isinstance(value, str):
            value = value.strip()
            return value or None
        return value

    @field_validator("admission_year")
    @classmethod
    def validate_admission_year(cls, value: int | None) -> int | None:
        if value is None:
            return None
        if value < 2000:
            raise ValueError("admission_year must be >= 2000")
        return value