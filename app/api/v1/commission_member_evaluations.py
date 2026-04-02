from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.schemas.commission_evaluation import (
    CommissionMemberCriterionEvaluationRead,
    CommissionMemberEvaluationRead,
    CommissionMemberEvaluationUpsertPayload,
)
from app.services.commission_evaluation_service import CommissionEvaluationService

router = APIRouter(
    prefix="/commission-member/student-attestations",
    tags=["commission-member-evaluations"],
)


def _build_read_model(evaluation) -> CommissionMemberEvaluationRead:
    return CommissionMemberEvaluationRead(
        id=evaluation.id,
        student_attestation_id=evaluation.student_attestation_id,
        commission_member_id=evaluation.commission_member_id,
        status=evaluation.status,
        overall_comment=evaluation.overall_comment,
        overall_recommendation=evaluation.overall_recommendation,
        submitted_at=evaluation.submitted_at,
        created_at=evaluation.created_at,
        updated_at=evaluation.updated_at,
        criterion_values=[
            CommissionMemberCriterionEvaluationRead(
                id=item.id,
                student_attestation_criterion_id=item.student_attestation_criterion_id,
                code=item.student_attestation_criterion.code,
                name=item.student_attestation_criterion.name,
                evaluation_type=item.evaluation_type,
                max_score=item.student_attestation_criterion.max_score,
                unit_label=item.student_attestation_criterion.unit_label,
                sort_order=item.sort_order,
                score_value=item.score_value,
                boolean_value=item.boolean_value,
                count_value=item.count_value,
                comment=item.comment,
                created_at=item.created_at,
                updated_at=item.updated_at,
            )
            for item in evaluation.criterion_values
        ],
    )


@router.get(
    "/{student_attestation_id}/commission-members/{commission_member_id}/evaluation",
    response_model=CommissionMemberEvaluationRead,
)
def get_member_evaluation(
    student_attestation_id: UUID,
    commission_member_id: UUID,
    db: Session = Depends(get_db),
) -> CommissionMemberEvaluationRead:
    service = CommissionEvaluationService(db)

    try:
        evaluation = service.get_or_create_evaluation(
            student_attestation_id=student_attestation_id,
            commission_member_id=commission_member_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return _build_read_model(evaluation)


@router.put(
    "/{student_attestation_id}/commission-members/{commission_member_id}/evaluation",
    response_model=CommissionMemberEvaluationRead,
)
def upsert_member_evaluation(
    student_attestation_id: UUID,
    commission_member_id: UUID,
    payload: CommissionMemberEvaluationUpsertPayload,
    db: Session = Depends(get_db),
) -> CommissionMemberEvaluationRead:
    service = CommissionEvaluationService(db)

    try:
        evaluation = service.upsert_evaluation(
            student_attestation_id=student_attestation_id,
            commission_member_id=commission_member_id,
            payload=payload,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return _build_read_model(evaluation)