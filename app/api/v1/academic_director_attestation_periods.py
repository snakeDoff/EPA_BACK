from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.schemas.attestation_period import (
    AttestationPeriodCreate,
    AttestationPeriodRead,
    AttestationPeriodUpdate,
)
from app.services.attestation_period_service import AttestationPeriodService

router = APIRouter(
    prefix="/academic-director/attestation",
    tags=["academic-director-attestation-periods"],
)


@router.get("", response_model=list[AttestationPeriodRead])
def list_attestation_periods(
    db: Session = Depends(get_db),
) -> list[AttestationPeriodRead]:
    service = AttestationPeriodService(db)
    periods = service.list_periods()
    return [AttestationPeriodRead.model_validate(item) for item in periods]


@router.get("/{period_id}", response_model=AttestationPeriodRead)
def get_attestation_period(
    period_id: UUID,
    db: Session = Depends(get_db),
) -> AttestationPeriodRead:
    service = AttestationPeriodService(db)
    item = service.get_period(period_id)

    if item is None:
        raise HTTPException(status_code=404, detail="Attestation period not found")

    return AttestationPeriodRead.model_validate(item)


@router.post("", response_model=AttestationPeriodRead, status_code=201)
def create_attestation_period(
    payload: AttestationPeriodCreate,
    db: Session = Depends(get_db),
) -> AttestationPeriodRead:
    service = AttestationPeriodService(db)
    period = service.create_period(payload=payload, created_by=None)
    return AttestationPeriodRead.model_validate(period)


@router.patch("/{period_id}", response_model=AttestationPeriodRead)
def update_attestation_period(
    period_id: UUID,
    payload: AttestationPeriodUpdate,
    db: Session = Depends(get_db),
) -> AttestationPeriodRead:
    service = AttestationPeriodService(db)
    period = service.get_period(period_id)

    if period is None:
        raise HTTPException(status_code=404, detail="Attestation period not found")

    updated = service.update_period(period=period, payload=payload)
    return AttestationPeriodRead.model_validate(updated)