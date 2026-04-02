from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db.models import (
    CommissionMember,
    CommissionMemberCriterionEvaluation,
    CommissionMemberEvaluation,
    StudentAttestation,
)
from app.schemas.commission_evaluation import CommissionMemberEvaluationUpsertPayload


class CommissionEvaluationService:
    def __init__(self, session: Session) -> None:
        self.session = session

    def get_or_create_evaluation(
        self,
        student_attestation_id,
        commission_member_id,
    ) -> CommissionMemberEvaluation:
        attestation = self._get_attestation(student_attestation_id)
        member = self._get_commission_member(commission_member_id)

        self._validate_member_attestation_relation(attestation, member)

        stmt = (
            select(CommissionMemberEvaluation)
            .options(
                selectinload(CommissionMemberEvaluation.criterion_values).selectinload(
                    CommissionMemberCriterionEvaluation.student_attestation_criterion
                )
            )
            .where(CommissionMemberEvaluation.student_attestation_id == student_attestation_id)
            .where(CommissionMemberEvaluation.commission_member_id == commission_member_id)
        )
        evaluation = self.session.scalar(stmt)

        if evaluation is None:
            evaluation = CommissionMemberEvaluation(
                student_attestation_id=student_attestation_id,
                commission_member_id=commission_member_id,
                status="draft",
            )
            self.session.add(evaluation)
            self.session.flush()

        existing = {
            item.student_attestation_criterion_id: item
            for item in evaluation.criterion_values
        }

        for criterion in attestation.criteria:
            if criterion.id in existing:
                continue

            self.session.add(
                CommissionMemberCriterionEvaluation(
                    member_evaluation_id=evaluation.id,
                    student_attestation_criterion_id=criterion.id,
                    evaluation_type=criterion.evaluation_type,
                    sort_order=criterion.sort_order,
                )
            )

        self.session.commit()
        return self.get_evaluation(evaluation.id)

    def get_evaluation(self, evaluation_id) -> CommissionMemberEvaluation:
        stmt = (
            select(CommissionMemberEvaluation)
            .options(
                selectinload(CommissionMemberEvaluation.criterion_values).selectinload(
                    CommissionMemberCriterionEvaluation.student_attestation_criterion
                )
            )
            .where(CommissionMemberEvaluation.id == evaluation_id)
        )
        evaluation = self.session.scalar(stmt)
        if evaluation is None:
            raise ValueError("Evaluation not found")
        return evaluation

    def upsert_evaluation(
        self,
        student_attestation_id,
        commission_member_id,
        payload: CommissionMemberEvaluationUpsertPayload,
    ) -> CommissionMemberEvaluation:
        evaluation = self.get_or_create_evaluation(
            student_attestation_id=student_attestation_id,
            commission_member_id=commission_member_id,
        )

        values_by_criterion_id = {
            item.student_attestation_criterion_id: item
            for item in evaluation.criterion_values
        }

        for item in payload.criteria:
            value_row = values_by_criterion_id.get(item.student_attestation_criterion_id)
            if value_row is None:
                raise ValueError(
                    f"Criterion not found in evaluation: {item.student_attestation_criterion_id}"
                )

            if value_row.evaluation_type == "score":
                if item.count_value is not None or item.boolean_value is not None:
                    raise ValueError("Score criterion accepts only score_value")
                if item.score_value is not None:
                    max_score = value_row.student_attestation_criterion.max_score
                    if max_score is not None and Decimal(item.score_value) > max_score:
                        raise ValueError(
                            f"score_value exceeds max_score for criterion {value_row.student_attestation_criterion_id}"
                        )
                value_row.score_value = item.score_value
                value_row.boolean_value = None
                value_row.count_value = None

            elif value_row.evaluation_type == "boolean":
                if item.count_value is not None or item.score_value is not None:
                    raise ValueError("Boolean criterion accepts only boolean_value")
                value_row.boolean_value = item.boolean_value
                value_row.score_value = None
                value_row.count_value = None

            elif value_row.evaluation_type == "count":
                if item.boolean_value is not None or item.score_value is not None:
                    raise ValueError("Count criterion accepts only count_value")
                if item.count_value is not None and item.count_value < 0:
                    raise ValueError("count_value must be >= 0")
                value_row.count_value = item.count_value
                value_row.score_value = None
                value_row.boolean_value = None

            value_row.comment = item.comment

        evaluation.status = payload.status
        evaluation.overall_comment = payload.overall_comment
        evaluation.overall_recommendation = payload.overall_recommendation

        if payload.status == "submitted":
            self._validate_submittable(evaluation)
            evaluation.submitted_at = datetime.now(timezone.utc)
        else:
            evaluation.submitted_at = None

        self.session.commit()
        return self.get_evaluation(evaluation.id)

    def _validate_submittable(self, evaluation: CommissionMemberEvaluation) -> None:
        for item in evaluation.criterion_values:
            if item.evaluation_type == "score" and item.score_value is None:
                raise ValueError(f"Criterion {item.student_attestation_criterion_id} has no score_value")
            if item.evaluation_type == "boolean" and item.boolean_value is None:
                raise ValueError(f"Criterion {item.student_attestation_criterion_id} has no boolean_value")
            if item.evaluation_type == "count" and item.count_value is None:
                raise ValueError(f"Criterion {item.student_attestation_criterion_id} has no count_value")

    def _get_attestation(self, student_attestation_id) -> StudentAttestation:
        stmt = (
            select(StudentAttestation)
            .options(selectinload(StudentAttestation.criteria))
            .where(StudentAttestation.id == student_attestation_id)
        )
        attestation = self.session.scalar(stmt)
        if attestation is None:
            raise ValueError("Student attestation not found")
        return attestation

    def _get_commission_member(self, commission_member_id) -> CommissionMember:
        member = self.session.get(CommissionMember, commission_member_id)
        if member is None:
            raise ValueError("Commission member not found")
        return member

    def _validate_member_attestation_relation(
        self,
        attestation: StudentAttestation,
        member: CommissionMember,
    ) -> None:
        if attestation.commission_id is None:
            raise ValueError("Student attestation is not assigned to a commission")
        if member.commission_id != attestation.commission_id:
            raise ValueError("Commission member does not belong to attestation commission")