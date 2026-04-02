from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.schemas.commission import (
    AssignStudentAttestationsToCommissionPayload,
    AssignStudentAttestationsToCommissionResult,
    AttestationCommissionCreate,
    AttestationCommissionRead,
)
from app.services.commission_service import CommissionService

router = APIRouter(
    prefix="/expert/attestation-periods",
    tags=["expert-commissions"],
)


@router.get("/{period_id}/commissions", response_model=list[AttestationCommissionRead])
def list_commissions(
    period_id: UUID,
    db: Session = Depends(get_db),
) -> list[AttestationCommissionRead]:
    service = CommissionService(db)
    items = service.list_commissions(period_id)
    return [AttestationCommissionRead.model_validate(item) for item in items]


@router.post("/{period_id}/commissions", response_model=AttestationCommissionRead, status_code=201)
def create_commission(
    period_id: UUID,
    payload: AttestationCommissionCreate,
    db: Session = Depends(get_db),
) -> AttestationCommissionRead:
    service = CommissionService(db)

    try:
        item = service.create_commission(period_id=period_id, payload=payload, created_by=None)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return AttestationCommissionRead.model_validate(item)


@router.patch(
    "/commissions/{commission_id}/assign-student-attestations",
    response_model=AssignStudentAttestationsToCommissionResult,
)
def assign_student_attestations_to_commission(
    commission_id: UUID,
    payload: AssignStudentAttestationsToCommissionPayload,
    db: Session = Depends(get_db),
) -> AssignStudentAttestationsToCommissionResult:
    service = CommissionService(db)

    try:
        result = service.assign_student_attestations_to_commission(
            commission_id=commission_id,
            payload=payload,
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

    return AssignStudentAttestationsToCommissionResult(**result)