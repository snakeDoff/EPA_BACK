from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, field_validator


class CommissionMemberCriterionEvaluationUpdateItem(BaseModel):
    student_attestation_criterion_id: UUID
    score_value: Decimal | None = None
    boolean_value: bool | None = None
    count_value: int | None = None
    comment: str | None = None

    @field_validator("comment", mode="before")
    @classmethod
    def strip_comment(cls, value: object) -> object:
        if value is None:
            return None
        if isinstance(value, str):
            value = value.strip()
            return value or None
        return value


class CommissionMemberEvaluationUpsertPayload(BaseModel):
    status: str = "draft"
    overall_comment: str | None = None
    overall_recommendation: str | None = None
    criteria: list[CommissionMemberCriterionEvaluationUpdateItem]

    @field_validator("status")
    @classmethod
    def validate_status(cls, value: str) -> str:
        allowed = {"draft", "submitted"}
        if value not in allowed:
            raise ValueError(f"status must be one of: {sorted(allowed)}")
        return value

    @field_validator("overall_comment", mode="before")
    @classmethod
    def strip_overall_comment(cls, value: object) -> object:
        if value is None:
            return None
        if isinstance(value, str):
            value = value.strip()
            return value or None
        return value

    @field_validator("overall_recommendation")
    @classmethod
    def validate_recommendation(cls, value: str | None) -> str | None:
        if value is None:
            return None
        allowed = {"passed", "passed_conditionally", "revision_required", "not_passed"}
        if value not in allowed:
            raise ValueError(f"overall_recommendation must be one of: {sorted(allowed)}")
        return value


class CommissionMemberCriterionEvaluationRead(BaseModel):
    id: UUID
    student_attestation_criterion_id: UUID
    code: str
    name: str
    evaluation_type: str
    max_score: Decimal | None
    unit_label: str | None
    sort_order: int
    score_value: Decimal | None
    boolean_value: bool | None
    count_value: int | None
    comment: str | None
    created_at: datetime
    updated_at: datetime


class CommissionMemberEvaluationRead(BaseModel):
    id: UUID
    student_attestation_id: UUID
    commission_member_id: UUID
    status: str
    overall_comment: str | None
    overall_recommendation: str | None
    submitted_at: datetime | None
    created_at: datetime
    updated_at: datetime
    criterion_values: list[CommissionMemberCriterionEvaluationRead]