from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


class StudentAttestationCriterionRead(BaseModel):
    id: UUID
    template_criterion_id: UUID
    code: str
    name: str
    description: str | None
    evaluation_type: str
    max_score: Decimal | None
    unit_label: str | None
    checked_by_student: bool
    checked_by_supervisor: bool
    sort_order: int
    created_at: datetime

    model_config = {"from_attributes": True}


class StudentAttestationRead(BaseModel):
    id: UUID
    attestation_period_id: UUID
    student_id: UUID
    department_id: UUID
    supervisor_user_id: UUID | None
    criterion_template_id: UUID
    status: str
    is_admitted: bool
    admission_comment: str | None
    debt_note: str | None
    final_decision: str | None
    final_comment: str | None
    result_sent_at: datetime | None
    created_at: datetime
    updated_at: datetime
    criteria: list[StudentAttestationCriterionRead]

    model_config = {"from_attributes": True}


class GenerateStudentAttestationsPayload(BaseModel):
    department_id: UUID | None = None
    only_active_students: bool = True


class GenerateStudentAttestationsResult(BaseModel):
    created_count: int
    skipped_count: int
    skipped_students: list[dict] = Field(default_factory=list)


class ManagerStudentAttestationTableRow(BaseModel):
    student_attestation_id: UUID
    student_id: UUID

    admission_year: int | None
    course: int
    fio: str

    funding_type: str | None
    education_program_name: str
    duration_years: int
    specialty: str | None

    academic_status: str | None
    department_name: str
    supervisor_name: str | None
    dissertation_topic: str | None

    is_admitted: bool
    debt_note: str | None
    status: str
    attestation_result: str | None

    average_score: float | None
    publications_count: int | None
    pedagogical_practice: bool | None
    research_practice: bool | None
    implementation_act: bool | None
    predefense_date: str | None
    status_change_reason: str | None


class StudentAttestationAdmissionUpdateItem(BaseModel):
    student_attestation_id: UUID
    is_admitted: bool
    debt_note: str | None = None
    admission_comment: str | None = None

    @field_validator("debt_note", "admission_comment", mode="before")
    @classmethod
    def strip_optional_strings(cls, value: object) -> object:
        if value is None:
            return None
        if isinstance(value, str):
            value = value.strip()
            return value or None
        return value


class StudentAttestationBulkAdmissionUpdatePayload(BaseModel):
    items: list[StudentAttestationAdmissionUpdateItem]


class StudentAttestationBulkAdmissionUpdateResult(BaseModel):
    updated_count: int