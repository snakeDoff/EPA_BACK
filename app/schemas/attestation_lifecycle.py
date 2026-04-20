from __future__ import annotations

from datetime import date
from uuid import UUID

from pydantic import BaseModel


class CurrentAttestationRead(BaseModel):
    id: UUID
    current_attestation: str
    start_date: date | None
    end_date: date | None
    current_stage_number: int | None


class AttestationStageRead(BaseModel):
    number: int
    description: str


class AttestationHistorySeasonRead(BaseModel):
    id: UUID
    start_date: date | None
    end_date: date | None
    passed_students_count: int
    total_students_count: int


class AttestationHistoryYearRead(BaseModel):
    year: int
    spring: AttestationHistorySeasonRead | None
    autumn: AttestationHistorySeasonRead | None


class AttestationStageUpdatePayload(BaseModel):
    current_stage_number: int