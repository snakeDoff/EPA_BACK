from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel


class ExpertCommissionStudentRead(BaseModel):
    student_attestation_id: UUID
    student_id: UUID
    fio: str
    email: str | None = None

    admission_year: int | None = None
    course: int
    funding_type: str | None = None
    specialty: str | None = None
    academic_status: str | None = None
    dissertation_topic: str | None = None

    department_id: UUID
    department_name: str | None = None

    education_program_id: UUID
    education_program_name: str | None = None

    supervisor_user_id: UUID | None = None
    supervisor_name: str | None = None

    student_attestation_status: str
    is_admitted: bool
    debt_note: str | None = None
    final_decision: str | None = None

    evaluation_id: UUID | None = None
    evaluation_status: str | None = None
    submitted_at: str | None = None

    overall_integral_score: float | None = None
    logic_hypothesis_score: float | None = None
    methods_score: float | None = None
    scientific_foundation_score: float | None = None
    text_progress_score: float | None = None

    completion_status: str
    completion_status_name: str
    completion_status_color: str
    filled_criteria_count: int
    total_criteria_count: int


class ExpertCommissionStudentsGroupRead(BaseModel):
    commission_id: UUID
    commission_name: str
    commission_status: str

    attestation_period_id: UUID

    department_id: UUID
    department_name: str | None = None

    meeting_date: str | None = None
    start_time: str | None = None
    end_time: str | None = None
    meeting_location: str | None = None

    commission_member_id: UUID
    role_in_commission: str
    membership_type: str
    is_voting_member: bool

    students_count: int
    students: list[ExpertCommissionStudentRead]