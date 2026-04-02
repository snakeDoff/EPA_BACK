from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.schemas.student_attestation import (
    GenerateStudentAttestationsPayload,
    GenerateStudentAttestationsResult,
    ManagerStudentAttestationTableRow,
    StudentAttestationBulkAdmissionUpdatePayload,
    StudentAttestationBulkAdmissionUpdateResult,
    StudentAttestationRead,
)
from app.services.student_attestation_service import StudentAttestationService

router = APIRouter(
    prefix="/manager/attestation-periods",
    tags=["manager-student-attestations"],
)


@router.post("/{period_id}/student-attestations/generate", response_model=GenerateStudentAttestationsResult)
def generate_student_attestations(
    period_id: UUID,
    payload: GenerateStudentAttestationsPayload,
    db: Session = Depends(get_db),
) -> GenerateStudentAttestationsResult:
    service = StudentAttestationService(db)
    result = service.generate_for_period(
        period_id=period_id,
        department_id=payload.department_id,
        only_active_students=payload.only_active_students,
    )
    return GenerateStudentAttestationsResult(**result)


@router.get("/{period_id}/student-attestations", response_model=list[StudentAttestationRead])
def list_student_attestations(
    period_id: UUID,
    db: Session = Depends(get_db),
) -> list[StudentAttestationRead]:
    service = StudentAttestationService(db)
    items = service.list_by_period(period_id)
    return [StudentAttestationRead.model_validate(item) for item in items]


@router.get("/{period_id}/student-attestations-table", response_model=list[ManagerStudentAttestationTableRow])
def list_student_attestations_table(
    period_id: UUID,
    db: Session = Depends(get_db),
) -> list[ManagerStudentAttestationTableRow]:
    service = StudentAttestationService(db)
    rows = service.list_table_rows(period_id)
    return [ManagerStudentAttestationTableRow.model_validate(row) for row in rows]


@router.patch(
    "/{period_id}/student-attestations/admission",
    response_model=StudentAttestationBulkAdmissionUpdateResult,
)
def bulk_update_student_attestations_admission(
    period_id: UUID,
    payload: StudentAttestationBulkAdmissionUpdatePayload,
    db: Session = Depends(get_db),
) -> StudentAttestationBulkAdmissionUpdateResult:
    service = StudentAttestationService(db)
    result = service.bulk_update_admission(period_id=period_id, payload=payload)
    return StudentAttestationBulkAdmissionUpdateResult(**result)


@router.get("/student-attestations/{attestation_id}", response_model=StudentAttestationRead)
def get_student_attestation(
    attestation_id: UUID,
    db: Session = Depends(get_db),
) -> StudentAttestationRead:
    service = StudentAttestationService(db)
    item = service.get_by_id(attestation_id)

    if item is None:
        raise HTTPException(status_code=404, detail="Student attestation not found")

    return StudentAttestationRead.model_validate(item)