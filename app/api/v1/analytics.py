from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.services.analytics_service import AnalyticsService

router = APIRouter(
    prefix="/analytics/attestation-periods",
    tags=["analytics"],
)


@router.get("/{period_id}/departments-score")
def get_departments_score(
    period_id: UUID,
    db: Session = Depends(get_db),
) -> list[dict]:
    service = AnalyticsService(db)
    return service.get_departments_score(period_id=period_id)


@router.get("/{period_id}/departments-risk")
def get_departments_risk(
    period_id: UUID,
    db: Session = Depends(get_db),
) -> list[dict]:
    service = AnalyticsService(db)
    return service.get_departments_risk(period_id=period_id)


@router.get("/{period_id}/departments/{department_id}/criteria")
def get_department_criteria(
    period_id: UUID,
    department_id: UUID,
    db: Session = Depends(get_db),
) -> list[dict]:
    service = AnalyticsService(db)
    return service.get_department_criteria(
        period_id=period_id,
        department_id=department_id,
    )


@router.get("/{period_id}/readiness-dynamics")
def get_readiness_dynamics(
    period_id: UUID,
    db: Session = Depends(get_db),
) -> list[dict]:
    service = AnalyticsService(db)
    return service.get_readiness_dynamics(period_id=period_id)


@router.get("/{period_id}/education-programs-score")
def get_education_programs_score(
    period_id: UUID,
    db: Session = Depends(get_db),
) -> list[dict]:
    service = AnalyticsService(db)
    return service.get_education_programs_score(period_id=period_id)


@router.get("/{period_id}/specialties-rating")
def get_specialties_rating(
    period_id: UUID,
    db: Session = Depends(get_db),
) -> dict:
    service = AnalyticsService(db)
    return service.get_specialties_rating(period_id=period_id)


@router.get("/{period_id}/supervisors-rating")
def get_supervisors_rating(
    period_id: UUID,
    db: Session = Depends(get_db),
) -> list[dict]:
    service = AnalyticsService(db)
    return service.get_supervisors_rating(period_id=period_id)


@router.get("/{period_id}/supervisors/{supervisor_user_id}/criteria")
def get_supervisor_criteria(
    period_id: UUID,
    supervisor_user_id: UUID,
    db: Session = Depends(get_db),
) -> list[dict]:
    service = AnalyticsService(db)
    return service.get_supervisor_criteria(
        period_id=period_id,
        supervisor_user_id=supervisor_user_id,
    )

@router.get("/departments")
def list_departments(
    only_active: bool = True,
    db: Session = Depends(get_db),
) -> list[dict]:
    service = AnalyticsService(db)
    return service.list_departments(only_active=only_active)