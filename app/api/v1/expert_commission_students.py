from __future__ import annotations

from app.schemas.expert_commission_students import ExpertCommissionStudentsGroupRead

from datetime import date, time
from decimal import Decimal
from uuid import UUID

from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.api.dependencies import get_db
from app.db.models import (
    AttestationCommission,
    CommissionMember,
    CommissionMemberCriterionEvaluation,
    CommissionMemberEvaluation,
    StaffMember,
    Student,
    StudentAttestation,
)


router = APIRouter(
    prefix="/expert/commission-students",
    tags=["expert-commission-students"],
)


COMPLETION_STATUSES = {
    "not_started": {
        "code": "not_started",
        "name": "Не начато",
        "color": "gray",
    },
    "partial": {
        "code": "partial",
        "name": "Частично заполнено",
        "color": "yellow",
    },
    "completed": {
        "code": "completed",
        "name": "Заполнено",
        "color": "green",
    },
}


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


@router.get("", response_model=list[ExpertCommissionStudentsGroupRead])
def list_expert_commission_students(
    attestation_period_id: UUID | None = None,
    current_user_id: UUID = Depends(get_current_expert_user_id),
    db: Session = Depends(get_db),
) -> list[dict]:
    staff_member = db.scalar(
        select(StaffMember).where(StaffMember.user_id == current_user_id)
    )

    if staff_member is None:
        raise HTTPException(status_code=400, detail="Expert staff profile not found")

    stmt = (
        select(CommissionMember)
        .join(CommissionMember.commission)
        .options(
            selectinload(CommissionMember.commission)
            .selectinload(AttestationCommission.department),
            selectinload(CommissionMember.commission)
            .selectinload(AttestationCommission.student_attestations)
            .selectinload(StudentAttestation.student)
            .selectinload(Student.education_program),
            selectinload(CommissionMember.commission)
            .selectinload(AttestationCommission.student_attestations)
            .selectinload(StudentAttestation.department),
            selectinload(CommissionMember.commission)
            .selectinload(AttestationCommission.student_attestations)
            .selectinload(StudentAttestation.criteria),
            selectinload(CommissionMember.evaluations)
            .selectinload(CommissionMemberEvaluation.criterion_values),
        )
        .where(CommissionMember.staff_member_id == staff_member.id)
        .order_by(AttestationCommission.meeting_date, AttestationCommission.name)
    )

    if attestation_period_id is not None:
        stmt = stmt.where(AttestationCommission.attestation_period_id == attestation_period_id)

    commission_members = list(db.scalars(stmt).unique().all())

    result: list[dict] = []

    for commission_member in commission_members:
        commission = commission_member.commission

        evaluations_by_attestation_id = {
            evaluation.student_attestation_id: evaluation
            for evaluation in commission_member.evaluations
        }

        student_attestations = sorted(
            commission.student_attestations,
            key=lambda item: _student_sort_key(item),
        )

        students = []

        for student_attestation in student_attestations:
            student = student_attestation.student
            if student is None:
                continue

            evaluation = evaluations_by_attestation_id.get(student_attestation.id)
            completion_info = _build_completion_info(
                evaluation=evaluation,
                total_criteria_count=len(student_attestation.criteria),
            )

            students.append(
                {
                    "student_attestation_id": str(student_attestation.id),
                    "student_id": str(student.id),
                    "fio": _build_student_fio(student),
                    "email": student.email,
                    "admission_year": student.admission_year,
                    "course": student.course,
                    "funding_type": student.funding_type,
                    "specialty": student.specialty,
                    "academic_status": student.academic_status,
                    "dissertation_topic": student.dissertation_topic,
                    "department_id": str(student_attestation.department_id),
                    "department_name": (
                        student_attestation.department.name
                        if student_attestation.department is not None
                        else None
                    ),
                    "education_program_id": str(student.education_program_id),
                    "education_program_name": (
                        student.education_program.name
                        if student.education_program is not None
                        else student.education_program_raw
                    ),
                    "supervisor_user_id": (
                        str(student.supervisor_user_id)
                        if student.supervisor_user_id is not None
                        else None
                    ),
                    "supervisor_name": student.supervisor_name_raw,
                    "student_attestation_status": student_attestation.status,
                    "is_admitted": student_attestation.is_admitted,
                    "debt_note": student_attestation.debt_note,
                    "final_decision": student_attestation.final_decision,
                    "evaluation_id": str(evaluation.id) if evaluation is not None else None,
                    "evaluation_status": evaluation.status if evaluation is not None else None,
                    "submitted_at": _serialize_value(evaluation.submitted_at)
                    if evaluation is not None
                    else None,
                    "overall_integral_score": _decimal_to_float(
                        evaluation.overall_integral_score
                    )
                    if evaluation is not None
                    else None,
                    "logic_hypothesis_score": _decimal_to_float(
                        evaluation.logic_hypothesis_score
                    )
                    if evaluation is not None
                    else None,
                    "methods_score": _decimal_to_float(evaluation.methods_score)
                    if evaluation is not None
                    else None,
                    "scientific_foundation_score": _decimal_to_float(
                        evaluation.scientific_foundation_score
                    )
                    if evaluation is not None
                    else None,
                    "text_progress_score": _decimal_to_float(
                        evaluation.text_progress_score
                    )
                    if evaluation is not None
                    else None,
                    **completion_info,
                }
            )

        result.append(
            {
                "commission_id": str(commission.id),
                "commission_name": commission.name,
                "commission_status": commission.status,
                "attestation_period_id": str(commission.attestation_period_id),
                "department_id": str(commission.department_id),
                "department_name": (
                    commission.department.name
                    if commission.department is not None
                    else None
                ),
                "meeting_date": _serialize_value(commission.meeting_date),
                "start_time": _serialize_value(commission.start_time),
                "end_time": _serialize_value(commission.end_time),
                "meeting_location": commission.meeting_location,
                "commission_member_id": str(commission_member.id),
                "role_in_commission": commission_member.role_in_commission,
                "membership_type": commission_member.membership_type,
                "is_voting_member": commission_member.is_voting_member,
                "students_count": len(students),
                "students": students,
            }
        )

    return result


def _build_completion_info(
    evaluation: CommissionMemberEvaluation | None,
    total_criteria_count: int,
) -> dict:
    filled_criteria_count = 0

    if evaluation is not None:
        for item in evaluation.criterion_values:
            if _is_criterion_value_filled(item):
                filled_criteria_count += 1

    if total_criteria_count == 0 or filled_criteria_count == 0:
        status_code = "not_started"
    elif filled_criteria_count >= total_criteria_count:
        status_code = "completed"
    else:
        status_code = "partial"

    status = COMPLETION_STATUSES[status_code]

    return {
        "completion_status": status["code"],
        "completion_status_name": status["name"],
        "completion_status_color": status["color"],
        "filled_criteria_count": filled_criteria_count,
        "total_criteria_count": total_criteria_count,
    }


def _is_criterion_value_filled(
    item: CommissionMemberCriterionEvaluation,
) -> bool:
    if item.evaluation_type == "score":
        return item.score_value is not None

    if item.evaluation_type == "boolean":
        return item.boolean_value is not None

    if item.evaluation_type == "count":
        return item.count_value is not None

    return False


def _build_student_fio(student: Student) -> str:
    parts = [student.last_name, student.first_name, student.middle_name]
    return " ".join(part for part in parts if part)


def _student_sort_key(student_attestation: StudentAttestation) -> tuple[str, str, str]:
    student = student_attestation.student

    if student is None:
        return "", "", ""

    return (
        student.last_name or "",
        student.first_name or "",
        student.middle_name or "",
    )


def _decimal_to_float(value: Decimal | None) -> float | None:
    if value is None:
        return None

    return float(value)


def _serialize_value(value):
    if value is None:
        return None

    if isinstance(value, (date, time)):
        return value.isoformat()

    return value