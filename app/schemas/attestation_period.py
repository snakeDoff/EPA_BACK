from __future__ import annotations

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


class AttestationPeriodBase(BaseModel):
    title: str
    type: str
    year: int = Field(ge=2000)
    season: str
    start_date: date
    end_date: date
    status: str = "draft"

    @field_validator("title", "type", "season", "status", mode="before")
    @classmethod
    def strip_strings(cls, value: object) -> object:
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
        allowed = {"draft", "active", "completed", "archived"}
        if value not in allowed:
            raise ValueError(f"status must be one of: {sorted(allowed)}")
        return value

    @field_validator("end_date")
    @classmethod
    def validate_dates(cls, end_date: date, info) -> date:
        start_date = info.data.get("start_date")
        if start_date and end_date < start_date:
            raise ValueError("end_date must be >= start_date")
        return end_date


class AttestationPeriodCreate(AttestationPeriodBase):
    pass


class AttestationPeriodUpdate(BaseModel):
    title: str | None = None
    type: str | None = None
    year: int | None = Field(default=None, ge=2000)
    season: str | None = None
    start_date: date | None = None
    end_date: date | None = None
    status: str | None = None


class AttestationPeriodRead(AttestationPeriodBase):
    id: UUID
    created_by: UUID | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}