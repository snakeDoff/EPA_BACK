from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Header, HTTPException, Response
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.db.models import StaffMember
from app.schemas.commission import (
    AssignStudentAttestationsToCommissionPayload,
    AssignStudentAttestationsToCommissionResult,
    AttestationCommissionCreate,
    AttestationCommissionRead,
    AttestationCommissionUpdate,
    CommissionMemberCreate,
    CommissionMemberRead,
    CommissionMemberUpdate,
    CommissionStudentAttestationsRead,
    ConfirmCommissionResult,
)
from app.schemas.student_attestation import ManagerStudentAttestationTableRow
from app.services.commission_service import CommissionService
from app.services.student_attestation_service import StudentAttestationService

router = APIRouter(
    prefix="/expert/attestation-periods",
    tags=["expert-commissions"],
)


def get_current_expert_user_id(
    x_user_id: str | None = Header(default=None),
) -> UUID:
    if x_user_id is None:
        raise HTTPException(
            status_code=400,
            detail="X-User-Id header is required until expert auth is implemented",
        )

    try:
        return UUID(x_user_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid X-User-Id header") from exc


def resolve_expert_department_id(
    db: Session,
    current_user_id: UUID,
) -> UUID:
    staff_member = db.scalar(
        select(StaffMember).where(StaffMember.user_id == current_user_id)
    )

    if staff_member is None:
        raise HTTPException(
            status_code=400,
            detail="Expert staff profile not found",
        )

    if staff_member.department_id is None:
        raise HTTPException(
            status_code=400,
            detail="Expert department is not configured",
        )

    return staff_member.department_id


@router.get("/{period_id}/commissions", response_model=list[AttestationCommissionRead])
def list_commissions(
    period_id: UUID,
    current_user_id: UUID = Depends(get_current_expert_user_id),
    db: Session = Depends(get_db),
) -> list[AttestationCommissionRead]:
    service = CommissionService(db)
    items = service.list_commissions(period_id=period_id, created_by=current_user_id)
    return [AttestationCommissionRead.model_validate(item) for item in items]


@router.post("/{period_id}/commissions", response_model=AttestationCommissionRead, status_code=201)
def create_commission(
    period_id: UUID,
    payload: AttestationCommissionCreate,
    current_user_id: UUID = Depends(get_current_expert_user_id),
    db: Session = Depends(get_db),
) -> AttestationCommissionRead:
    service = CommissionService(db)

    department_id = resolve_expert_department_id(
        db=db,
        current_user_id=current_user_id,
    )

    try:
        item = service.create_commission(
            period_id=period_id,
            department_id=department_id,
            payload=payload,
            created_by=current_user_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return AttestationCommissionRead.model_validate(item)


@router.patch("/commissions/{commission_id}", response_model=AttestationCommissionRead)
def update_commission(
    commission_id: UUID,
    payload: AttestationCommissionUpdate,
    current_user_id: UUID = Depends(get_current_expert_user_id),
    db: Session = Depends(get_db),
) -> AttestationCommissionRead:
    service = CommissionService(db)

    try:
        item = service.update_commission(
            commission_id=commission_id,
            payload=payload,
            created_by=current_user_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return AttestationCommissionRead.model_validate(item)


@router.patch("/commissions/{commission_id}/confirm", response_model=ConfirmCommissionResult)
def confirm_commission(
    commission_id: UUID,
    current_user_id: UUID = Depends(get_current_expert_user_id),
    db: Session = Depends(get_db),
) -> ConfirmCommissionResult:
    service = CommissionService(db)

    try:
        item = service.confirm_commission(
            commission_id=commission_id,
            created_by=current_user_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return ConfirmCommissionResult(id=item.id, status=item.status)


@router.patch(
    "/commissions/{commission_id}/assign-student-attestations",
    response_model=AssignStudentAttestationsToCommissionResult,
)
def assign_student_attestations_to_commission(
    commission_id: UUID,
    payload: AssignStudentAttestationsToCommissionPayload,
    current_user_id: UUID = Depends(get_current_expert_user_id),
    db: Session = Depends(get_db),
) -> AssignStudentAttestationsToCommissionResult:
    service = CommissionService(db)

    try:
        result = service.assign_student_attestations_to_commission(
            commission_id=commission_id,
            payload=payload,
            created_by=current_user_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return AssignStudentAttestationsToCommissionResult(**result)


@router.get(
    "/commissions/{commission_id}/student-attestations",
    response_model=CommissionStudentAttestationsRead,
)
def list_commission_student_attestations(
    commission_id: UUID,
    current_user_id: UUID = Depends(get_current_expert_user_id),
    db: Session = Depends(get_db),
) -> CommissionStudentAttestationsRead:
    commission_service = CommissionService(db)

    try:
        items = commission_service.list_commission_student_attestations(
            commission_id=commission_id,
            created_by=current_user_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    student_attestation_service = StudentAttestationService(db)
    rows: list[ManagerStudentAttestationTableRow] = []

    for item in items:
        student = item.student
        program = student.education_program

        fio_parts = [student.last_name, student.first_name, student.middle_name]
        fio = " ".join(part for part in fio_parts if part)

        supervisor_name = None
        if item.supervisor is not None:
            supervisor_parts = [
                item.supervisor.last_name,
                item.supervisor.first_name,
                item.supervisor.middle_name,
            ]
            supervisor_name = " ".join(part for part in supervisor_parts if part)
        elif student.supervisor_name_raw:
            supervisor_name = student.supervisor_name_raw

        rows.append(
            ManagerStudentAttestationTableRow(
                student_attestation_id=item.id,
                student_id=student.id,
                admission_year=student.admission_year,
                course=student.course,
                fio=fio,
                funding_type=student.funding_type,
                education_program_name=program.name,
                duration_years=program.duration_years,
                specialty=student.specialty,
                academic_status=getattr(student, "academic_status", None),
                department_name=item.department.name,
                supervisor_name=supervisor_name,
                dissertation_topic=getattr(student, "dissertation_topic", None),
                is_admitted=item.is_admitted,
                debt_note=item.debt_note,
                status=item.status,
                attestation_result=item.final_decision,
                average_score=student_attestation_service._calculate_average_score(item),
                publications_count=student_attestation_service._extract_int_metric(
                    item,
                    codes={"publications_count", "scientific_publications", "publications"},
                    names={
                        "Научные публикации",
                        "Научные публикации: полное библиографическое описание с указанием списков НИУ ВШЭ",
                    },
                ),
                pedagogical_practice=student_attestation_service._extract_bool_metric(
                    item,
                    codes={"pedagogical_practice", "scientific_pedagogical_practice"},
                    names={"Научно-педагогическая практика"},
                ),
                research_practice=student_attestation_service._extract_bool_metric(
                    item,
                    codes={"research_practice", "scientific_research_practice"},
                    names={
                        "Научно-исследовательская практика",
                        "Научно-исследовательская практика (стажировки, гранты, конференции, РИДы и др.)",
                    },
                ),
                implementation_act=student_attestation_service._extract_bool_metric(
                    item,
                    codes={"implementation_act", "acts_of_implementation"},
                    names={"Акты внедрения", "Акт внедрения"},
                ),
                predefense_date=None,
                status_change_reason=getattr(student, "status_change_reason", None),
            )
        )

    return CommissionStudentAttestationsRead(items=rows)


@router.post("/commissions/{commission_id}/members", response_model=CommissionMemberRead, status_code=201)
def add_commission_member(
    commission_id: UUID,
    payload: CommissionMemberCreate,
    current_user_id: UUID = Depends(get_current_expert_user_id),
    db: Session = Depends(get_db),
) -> CommissionMemberRead:
    service = CommissionService(db)

    try:
        item = service.add_commission_member(
            commission_id=commission_id,
            payload=payload,
            created_by=current_user_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return CommissionMemberRead.model_validate(item)


@router.patch("/commissions/members/{member_id}", response_model=CommissionMemberRead)
def update_commission_member(
    member_id: UUID,
    payload: CommissionMemberUpdate,
    current_user_id: UUID = Depends(get_current_expert_user_id),
    db: Session = Depends(get_db),
) -> CommissionMemberRead:
    service = CommissionService(db)

    try:
        item = service.update_commission_member(
            member_id=member_id,
            payload=payload,
            created_by=current_user_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return CommissionMemberRead.model_validate(item)


@router.delete("/commissions/members/{member_id}", status_code=204)
def delete_commission_member(
    member_id: UUID,
    current_user_id: UUID = Depends(get_current_expert_user_id),
    db: Session = Depends(get_db),
) -> Response:
    service = CommissionService(db)

    try:
        service.delete_commission_member(
            member_id=member_id,
            created_by=current_user_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return Response(status_code=204)