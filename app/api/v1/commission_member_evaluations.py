from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.schemas.commission_evaluation import (
    CommissionMemberCriterionEvaluationRead,
    CommissionMemberEvaluationRead,
    CommissionMemberEvaluationUpsertPayload,
    EvaluationCompletionStatusRead,
)
from app.services.commission_evaluation_service import CommissionEvaluationService

router = APIRouter(
    prefix="/commission-member/student-attestations",
    tags=["commission-member-evaluations"],
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


def _build_read_model(
    evaluation,
    service: CommissionEvaluationService,
) -> CommissionMemberEvaluationRead:
    completion_info = service.get_completion_info(evaluation)

    return CommissionMemberEvaluationRead(
        id=evaluation.id,
        student_attestation_id=evaluation.student_attestation_id,
        commission_member_id=evaluation.commission_member_id,
        status=evaluation.status,
        overall_comment=evaluation.overall_comment,
        overall_recommendation=evaluation.overall_recommendation,
        submitted_at=evaluation.submitted_at,
        logic_hypothesis_score=evaluation.logic_hypothesis_score,
        methods_score=evaluation.methods_score,
        scientific_foundation_score=evaluation.scientific_foundation_score,
        text_progress_score=evaluation.text_progress_score,
        overall_integral_score=evaluation.overall_integral_score,
        completion_status=completion_info["completion_status"],
        completion_status_name=completion_info["completion_status_name"],
        completion_status_color=completion_info["completion_status_color"],
        filled_criteria_count=completion_info["filled_criteria_count"],
        total_criteria_count=completion_info["total_criteria_count"],
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
                group_code=item.student_attestation_criterion.group_code,
                group_name=item.student_attestation_criterion.group_name,
                group_sort_order=item.student_attestation_criterion.group_sort_order,
                count_norm=item.student_attestation_criterion.count_norm,
                sort_order=item.sort_order,
                score_value=item.score_value,
                boolean_value=item.boolean_value,
                count_value=item.count_value,
                normalized_score=item.normalized_score,
                comment=item.comment,
                created_at=item.created_at,
                updated_at=item.updated_at,
            )
            for item in evaluation.criterion_values
        ],
    )


@router.get(
    "/evaluation-completion-statuses",
    response_model=list[EvaluationCompletionStatusRead],
)
def list_evaluation_completion_statuses(
    db: Session = Depends(get_db),
) -> list[EvaluationCompletionStatusRead]:
    service = CommissionEvaluationService(db)
    items = service.list_completion_statuses()
    return [EvaluationCompletionStatusRead(**item) for item in items]


@router.get(
    "/{student_attestation_id}/my-evaluation",
    response_model=CommissionMemberEvaluationRead,
)
def get_my_member_evaluation(
    student_attestation_id: UUID,
    current_user_id: UUID = Depends(get_current_expert_user_id),
    db: Session = Depends(get_db),
) -> CommissionMemberEvaluationRead:
    service = CommissionEvaluationService(db)

    try:
        evaluation = service.get_or_create_my_evaluation(
            student_attestation_id=student_attestation_id,
            current_user_id=current_user_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return _build_read_model(evaluation, service)


@router.put(
    "/{student_attestation_id}/my-evaluation",
    response_model=CommissionMemberEvaluationRead,
)
def upsert_my_member_evaluation(
    student_attestation_id: UUID,
    payload: CommissionMemberEvaluationUpsertPayload,
    current_user_id: UUID = Depends(get_current_expert_user_id),
    db: Session = Depends(get_db),
) -> CommissionMemberEvaluationRead:
    service = CommissionEvaluationService(db)

    try:
        evaluation = service.upsert_my_evaluation(
            student_attestation_id=student_attestation_id,
            current_user_id=current_user_id,
            payload=payload,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return _build_read_model(evaluation, service)


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

    return _build_read_model(evaluation, service)


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

    return _build_read_model(evaluation, service)