from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


class AttestationCriterionCreate(BaseModel):
    code: str
    name: str
    description: str | None = None

    evaluation_type: str
    max_score: Decimal | None = None
    unit_label: str | None = None

    checked_by_student: bool = False
    checked_by_supervisor: bool = False

    sort_order: int = 0
    is_active: bool = True

    @field_validator("code", "name", "description", "evaluation_type", "unit_label", mode="before")
    @classmethod
    def strip_strings(cls, value: object) -> object:
        if isinstance(value, str):
            value = value.strip()
            return value or None
        return value

    @field_validator("evaluation_type")
    @classmethod
    def validate_evaluation_type(cls, value: str) -> str:
        allowed = {"score", "boolean", "count"}
        if value not in allowed:
            raise ValueError(f"evaluation_type must be one of: {sorted(allowed)}")
        return value

    @field_validator("max_score")
    @classmethod
    def validate_max_score(cls, value: Decimal | None) -> Decimal | None:
        if value is not None and value < 0:
            raise ValueError("max_score must be >= 0")
        return value

    @field_validator("checked_by_supervisor")
    @classmethod
    def validate_checked_flags(cls, value: bool, info) -> bool:
        checked_by_student = info.data.get("checked_by_student", False)
        if not checked_by_student and not value:
            raise ValueError("criterion must be checked by student or supervisor")
        return value


class AttestationCriterionRead(AttestationCriterionCreate):
    id: UUID
    template_id: UUID
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class AttestationCriterionTemplateCreate(BaseModel):
    name: str
    period_type: str
    program_duration_years: int = Field(ge=3, le=4)
    course: int = Field(ge=1)
    season: str
    is_active: bool = True
    criteria: list[AttestationCriterionCreate]

    @field_validator("name", "period_type", "season", mode="before")
    @classmethod
    def strip_strings(cls, value: object) -> object:
        if isinstance(value, str):
            value = value.strip()
            return value or None
        return value

    @field_validator("period_type")
    @classmethod
    def validate_period_type(cls, value: str) -> str:
        allowed = {"attestation", "department_seminar"}
        if value not in allowed:
            raise ValueError(f"period_type must be one of: {sorted(allowed)}")
        return value

    @field_validator("season")
    @classmethod
    def validate_season(cls, value: str) -> str:
        allowed = {"spring", "autumn"}
        if value not in allowed:
            raise ValueError(f"season must be one of: {sorted(allowed)}")
        return value


class AttestationCriterionTemplateRead(BaseModel):
    id: UUID
    name: str
    period_type: str
    program_duration_years: int
    course: int
    season: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
    criteria: list[AttestationCriterionRead]

    model_config = {"from_attributes": True}