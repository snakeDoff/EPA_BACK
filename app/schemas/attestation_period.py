from __future__ import annotations

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, field_validator


class AttestationPeriodBase(BaseModel):
    title: str
    type: str
    year: int
    season: str

    start_date: date | None = None
    end_date: date | None = None

    status: str = "draft"
    description: str | None = None

    is_active: bool = False
    is_completed: bool = False
    current_stage_number: int | None = None

    @field_validator("title", "type", "season", "status", "description", mode="before")
    @classmethod
    def strip_strings(cls, value: object) -> object:
        if value is None:
            return None
        if isinstance(value, str):
            value = value.strip()
            return value or None
        return value

    @field_validator("type")
    @classmethod
    def validate_type(cls, value: str) -> str:
        allowed = {"attestation", "department_seminar"}
        if value not in allowed:
            raise ValueError(f"type must be one of: {sorted(allowed)}")
        return value

    @field_validator("season")
    @classmethod
    def validate_season(cls, value: str) -> str:
        allowed = {"spring", "autumn"}
        if value not in allowed:
            raise ValueError(f"season must be one of: {sorted(allowed)}")
        return value

    @field_validator("status")
    @classmethod
    def validate_status(cls, value: str) -> str:
        allowed = {"draft", "active", "completed", "cancelled"}
        if value not in allowed:
            raise ValueError(f"status must be one of: {sorted(allowed)}")
        return value

    @field_validator("current_stage_number")
    @classmethod
    def validate_current_stage_number(cls, value: int | None) -> int | None:
        if value is None:
            return None
        if not 1 <= value <= 6:
            raise ValueError("current_stage_number must be between 1 and 6")
        return value

    @field_validator("end_date")
    @classmethod
    def validate_dates(cls, value: date | None, info) -> date | None:
        start_date = info.data.get("start_date")
        if value is not None and start_date is not None and value < start_date:
            raise ValueError("end_date must be greater than or equal to start_date")
        return value


class AttestationPeriodCreate(AttestationPeriodBase):
    pass


class AttestationPeriodUpdate(BaseModel):
    title: str | None = None
    type: str | None = None
    year: int | None = None
    season: str | None = None

    start_date: date | None = None
    end_date: date | None = None

    status: str | None = None
    description: str | None = None

    is_active: bool | None = None
    is_completed: bool | None = None
    current_stage_number: int | None = None

    @field_validator("title", "type", "season", "status", "description", mode="before")
    @classmethod
    def strip_strings(cls, value: object) -> object:
        if value is None:
            return None
        if isinstance(value, str):
            value = value.strip()
            return value or None
        return value

    @field_validator("type")
    @classmethod
    def validate_type(cls, value: str | None) -> str | None:
        if value is None:
            return None
        allowed = {"attestation", "department_seminar"}
        if value not in allowed:
            raise ValueError(f"type must be one of: {sorted(allowed)}")
        return value

    @field_validator("season")
    @classmethod
    def validate_season(cls, value: str | None) -> str | None:
        if value is None:
            return None
        allowed = {"spring", "autumn"}
        if value not in allowed:
            raise ValueError(f"season must be one of: {sorted(allowed)}")
        return value

    @field_validator("status")
    @classmethod
    def validate_status(cls, value: str | None) -> str | None:
        if value is None:
            return None
        allowed = {"draft", "active", "completed", "cancelled"}
        if value not in allowed:
            raise ValueError(f"status must be one of: {sorted(allowed)}")
        return value

    @field_validator("current_stage_number")
    @classmethod
    def validate_current_stage_number(cls, value: int | None) -> int | None:
        if value is None:
            return None
        if not 1 <= value <= 6:
            raise ValueError("current_stage_number must be between 1 and 6")
        return value


class AttestationPeriodRead(BaseModel):
    id: UUID
    title: str
    type: str
    year: int
    season: str

    start_date: date | None
    end_date: date | None

    status: str
    description: str | None

    is_active: bool
    is_completed: bool
    current_stage_number: int | None

    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class CurrentAttestationRead(BaseModel):
    id: UUID
    current_attestation: str
    start_date: date | None
    end_date: date | None
    current_stage_number: int | None