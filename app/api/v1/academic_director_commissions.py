from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.schemas.commission import AttestationCommissionRead
from app.services.commission_service import CommissionService

router = APIRouter(
    prefix="/academic-director/attestation-periods",
    tags=["academic-director-commissions"],
)


@router.get("/{period_id}/commissions", response_model=list[AttestationCommissionRead])
def list_all_commissions_for_director(
    period_id: UUID,
    db: Session = Depends(get_db),
) -> list[AttestationCommissionRead]:
    service = CommissionService(db)
    items = service.list_all_commissions_for_director(period_id=period_id)
    return [AttestationCommissionRead.model_validate(item) for item in items]