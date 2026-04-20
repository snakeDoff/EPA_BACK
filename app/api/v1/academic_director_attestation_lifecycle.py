from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.schemas.attestation_lifecycle import (
    AttestationHistoryYearRead,
    AttestationStageRead,
    AttestationStageUpdatePayload,
    CurrentAttestationRead,
)
from app.services.attestation_lifecycle_service import AttestationLifecycleService

router = APIRouter(
    prefix="/academic-director/attestation",
    tags=["academic-director-attestation-lifecycle"],
)


@router.get("/current", response_model=CurrentAttestationRead | None)
def get_current_attestation(
    db: Session = Depends(get_db),
) -> CurrentAttestationRead | None:
    service = AttestationLifecycleService(db)
    item = service.get_current_attestation()

    if item is None:
        return None

    return CurrentAttestationRead(**item)


@router.get("/stages", response_model=list[AttestationStageRead])
def list_attestation_stages() -> list[AttestationStageRead]:
    return [AttestationStageRead(**item) for item in AttestationLifecycleService.list_stages()]


@router.get("/history", response_model=list[AttestationHistoryYearRead])
def get_attestation_history(
    db: Session = Depends(get_db),
) -> list[AttestationHistoryYearRead]:
    service = AttestationLifecycleService(db)
    items = service.get_history()
    return [AttestationHistoryYearRead(**item) for item in items]


@router.patch("/periods/{period_id}/stage", response_model=CurrentAttestationRead)
def update_attestation_stage(
    period_id: UUID,
    payload: AttestationStageUpdatePayload,
    db: Session = Depends(get_db),
) -> CurrentAttestationRead:
    service = AttestationLifecycleService(db)

    try:
        item = service.update_stage(
            period_id=period_id,
            current_stage_number=payload.current_stage_number,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return CurrentAttestationRead(**item)