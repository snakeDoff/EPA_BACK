from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.schemas.attestation_criterion import (
    AttestationCriterionTemplateCreate,
    AttestationCriterionTemplateRead,
)
from app.services.attestation_criterion_service import AttestationCriterionService

router = APIRouter(
    prefix="/academic-director/criterion-templates",
    tags=["academic-director-criterion-templates"],
)


@router.get("", response_model=list[AttestationCriterionTemplateRead])
def list_criterion_templates(
    db: Session = Depends(get_db),
) -> list[AttestationCriterionTemplateRead]:
    service = AttestationCriterionService(db)
    templates = service.list_templates()
    return [AttestationCriterionTemplateRead.model_validate(template) for template in templates]


@router.post("", response_model=AttestationCriterionTemplateRead, status_code=201)
def create_criterion_template(
    payload: AttestationCriterionTemplateCreate,
    db: Session = Depends(get_db),
) -> AttestationCriterionTemplateRead:
    service = AttestationCriterionService(db)
    template = service.create_template(payload)
    return AttestationCriterionTemplateRead.model_validate(template)


@router.get("/{template_id}", response_model=AttestationCriterionTemplateRead)
def get_criterion_template(
    template_id: UUID,
    db: Session = Depends(get_db),
) -> AttestationCriterionTemplateRead:
    service = AttestationCriterionService(db)
    template = service.get_template(template_id)

    if template is None:
        raise HTTPException(status_code=404, detail="Criterion template not found")

    return AttestationCriterionTemplateRead.model_validate(template)