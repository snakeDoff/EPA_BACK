from __future__ import annotations

from datetime import date, datetime, time
from uuid import UUID

from pydantic import BaseModel, field_validator

from app.schemas.staff_member import StaffMemberRead
from app.schemas.student_attestation import ManagerStudentAttestationTableRow


class CommissionMemberCreate(BaseModel):
    staff_member_id: UUID
    role_in_commission: str
    membership_type: str
    participation_note: str | None = None
    is_voting_member: bool = True
    sort_order: int = 0

    @field_validator("role_in_commission")
    @classmethod
    def validate_role(cls, value: str) -> str:
        allowed = {"chair", "deputy_chair", "member", "secretary"}
        if value not in allowed:
            raise ValueError(f"role_in_commission must be one of: {sorted(allowed)}")
        return value

    @field_validator("membership_type")
    @classmethod
    def validate_membership_type(cls, value: str) -> str:
        allowed = {"mandatory", "additional"}
        if value not in allowed:
            raise ValueError(f"membership_type must be one of: {sorted(allowed)}")
        return value

    @field_validator("participation_note", mode="before")
    @classmethod
    def strip_participation_note(cls, value: object) -> object:
        if value is None:
            return None
        if isinstance(value, str):
            value = value.strip()
            return value or None
        return value


class CommissionMemberUpdate(BaseModel):
    role_in_commission: str | None = None
    membership_type: str | None = None
    participation_note: str | None = None
    is_voting_member: bool | None = None
    sort_order: int | None = None

    @field_validator("role_in_commission")
    @classmethod
    def validate_role(cls, value: str | None) -> str | None:
        if value is None:
            return None
        allowed = {"chair", "deputy_chair", "member", "secretary"}
        if value not in allowed:
            raise ValueError(f"role_in_commission must be one of: {sorted(allowed)}")
        return value

    @field_validator("membership_type")
    @classmethod
    def validate_membership_type(cls, value: str | None) -> str | None:
        if value is None:
            return None
        allowed = {"mandatory", "additional"}
        if value not in allowed:
            raise ValueError(f"membership_type must be one of: {sorted(allowed)}")
        return value

    @field_validator("participation_note", mode="before")
    @classmethod
    def strip_participation_note(cls, value: object) -> object:
        if value is None:
            return None
        if isinstance(value, str):
            value = value.strip()
            return value or None
        return value


class CommissionMemberRead(BaseModel):
    id: UUID
    staff_member_id: UUID
    role_in_commission: str
    membership_type: str
    participation_note: str | None
    is_voting_member: bool
    sort_order: int
    created_at: datetime
    updated_at: datetime
    staff_member: StaffMemberRead

    model_config = {"from_attributes": True}


class AttestationCommissionCreate(BaseModel):
    department_id: UUID
    name: str
    status: str = "draft"
    notes: str | None = None
    meeting_date: date | None = None
    start_time: time | None = None
    end_time: time | None = None
    meeting_location: str | None = None
    members: list[CommissionMemberCreate]

    @field_validator("name", "status", "notes", "meeting_location", mode="before")
    @classmethod
    def strip_strings(cls, value: object) -> object:
        if value is None:
            return None
        if isinstance(value, str):
            value = value.strip()
            return value or None
        return value

    @field_validator("status")
    @classmethod
    def validate_status(cls, value: str) -> str:
        allowed = {"draft", "formed", "completed", "confirmed"}
        if value not in allowed:
            raise ValueError(f"status must be one of: {sorted(allowed)}")
        return value


class AttestationCommissionUpdate(BaseModel):
    department_id: UUID | None = None
    name: str | None = None
    status: str | None = None
    notes: str | None = None
    meeting_date: date | None = None
    start_time: time | None = None
    end_time: time | None = None
    meeting_location: str | None = None

    @field_validator("name", "status", "notes", "meeting_location", mode="before")
    @classmethod
    def strip_strings(cls, value: object) -> object:
        if value is None:
            return None
        if isinstance(value, str):
            value = value.strip()
            return value or None
        return value

    @field_validator("status")
    @classmethod
    def validate_status(cls, value: str | None) -> str | None:
        if value is None:
            return None
        allowed = {"draft", "formed", "completed", "confirmed"}
        if value not in allowed:
            raise ValueError(f"status must be one of: {sorted(allowed)}")
        return value


class AttestationCommissionRead(BaseModel):
    id: UUID
    attestation_period_id: UUID
    department_id: UUID
    name: str
    status: str
    notes: str | None
    meeting_date: date | None
    start_time: time | None
    end_time: time | None
    meeting_location: str | None
    created_by: UUID | None
    created_at: datetime
    updated_at: datetime
    members: list[CommissionMemberRead]

    model_config = {"from_attributes": True}


class AssignStudentAttestationsToCommissionPayload(BaseModel):
    student_attestation_ids: list[UUID]


class AssignStudentAttestationsToCommissionResult(BaseModel):
    updated_count: int


class ConfirmCommissionResult(BaseModel):
    id: UUID
    status: str


class CommissionStudentAttestationsRead(BaseModel):
    items: list[ManagerStudentAttestationTableRow]