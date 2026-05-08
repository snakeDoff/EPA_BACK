from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal, ROUND_HALF_UP

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db.models import (
    CommissionMember,
    CommissionMemberCriterionEvaluation,
    CommissionMemberEvaluation,
    StaffMember,
    StudentAttestation,
)
from app.schemas.commission_evaluation import CommissionMemberEvaluationUpsertPayload


class CommissionEvaluationService:
    GROUP_LOGIC_HYPOTHESIS = "logic_hypothesis"
    GROUP_METHODS = "methods"
    GROUP_SCIENTIFIC_FOUNDATION = "scientific_foundation"
    GROUP_TEXT_PROGRESS = "text_progress"

    EVALUATION_SUBMIT_STATUSES = {
        "submitted": {
            "code": "submitted",
            "name": "Отправлено",
            "description": "Оценки сохранены и учитываются в расчетах. Их можно изменить повторным сохранением.",
        },
    }

    EVALUATION_COMPLETION_STATUSES = {
        "not_started": {
            "code": "not_started",
            "name": "Не начато",
            "description": "Оценки не проставлены",
            "color": "gray",
        },
        "partial": {
            "code": "partial",
            "name": "Частично заполнено",
            "description": "Проставлена часть оценок",
            "color": "yellow",
        },
        "completed": {
            "code": "completed",
            "name": "Заполнено",
            "description": "Проставлены все оценки",
            "color": "green",
        },
    }

    PUBLICATION_PATTERNS = (
        "публикац",
        "аффилиацией",
    )

    PEDAGOGICAL_PRACTICE_PATTERNS = (
        "научно-педагог",
    )

    RESEARCH_PRACTICE_PATTERNS = (
        "научно-исследовательская практика",
        "стажиров",
        "грант",
        "конференц",
        "рид",
        "научный доклад",
        "научные семинары",
        "симпозиум",
    )

    IMPLEMENTATION_ACT_PATTERNS = (
        "акт внедр",
        "акты внедр",
    )

    def __init__(self, session: Session) -> None:
        self.session = session

    def list_submit_statuses(self) -> list[dict]:
        return list(self.EVALUATION_SUBMIT_STATUSES.values())

    def list_completion_statuses(self) -> list[dict]:
        return list(self.EVALUATION_COMPLETION_STATUSES.values())

    def get_completion_info(
        self,
        evaluation: CommissionMemberEvaluation,
    ) -> dict:
        total_count = len(evaluation.criterion_values)
        filled_count = 0

        for item in evaluation.criterion_values:
            if self._is_criterion_value_filled(item):
                filled_count += 1

        if total_count == 0 or filled_count == 0:
            status_code = "not_started"
        elif filled_count == total_count:
            status_code = "completed"
        else:
            status_code = "partial"

        status = self.EVALUATION_COMPLETION_STATUSES[status_code]

        return {
            "completion_status": status["code"],
            "completion_status_name": status["name"],
            "completion_status_color": status["color"],
            "filled_criteria_count": filled_count,
            "total_criteria_count": total_count,
        }

    def get_or_create_my_evaluation(
        self,
        student_attestation_id,
        current_user_id,
    ) -> CommissionMemberEvaluation:
        commission_member = self.resolve_commission_member_for_expert(
            student_attestation_id=student_attestation_id,
            current_user_id=current_user_id,
        )

        return self.get_or_create_evaluation(
            student_attestation_id=student_attestation_id,
            commission_member_id=commission_member.id,
        )

    def upsert_my_evaluation(
        self,
        student_attestation_id,
        current_user_id,
        payload: CommissionMemberEvaluationUpsertPayload,
    ) -> CommissionMemberEvaluation:
        commission_member = self.resolve_commission_member_for_expert(
            student_attestation_id=student_attestation_id,
            current_user_id=current_user_id,
        )

        return self.upsert_evaluation(
            student_attestation_id=student_attestation_id,
            commission_member_id=commission_member.id,
            payload=payload,
        )

    def resolve_commission_member_for_expert(
        self,
        student_attestation_id,
        current_user_id,
    ) -> CommissionMember:
        attestation = self._get_attestation(student_attestation_id)

        if attestation.commission_id is None:
            raise ValueError("Student attestation is not assigned to a commission")

        staff_member = self.session.scalar(
            select(StaffMember).where(StaffMember.user_id == current_user_id)
        )

        if staff_member is None:
            raise ValueError("Expert staff profile not found")

        commission_member = self.session.scalar(
            select(CommissionMember)
            .where(CommissionMember.commission_id == attestation.commission_id)
            .where(CommissionMember.staff_member_id == staff_member.id)
        )

        if commission_member is None:
            raise ValueError("Current expert is not a member of this attestation commission")

        return commission_member

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
                status="submitted",
                submitted_at=datetime.now(timezone.utc),
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
            value_row.normalized_score = self._calculate_normalized_score(value_row)

        evaluation.status = "submitted"
        evaluation.overall_comment = payload.overall_comment
        evaluation.overall_recommendation = payload.overall_recommendation
        evaluation.submitted_at = datetime.now(timezone.utc)

        self._recalculate_integral_scores(evaluation)

        self.session.flush()
        self._sync_student_metrics_from_submitted_evaluations(
            student_attestation_id=student_attestation_id,
        )

        self.session.commit()
        return self.get_evaluation(evaluation.id)

    def _sync_student_metrics_from_submitted_evaluations(
        self,
        student_attestation_id,
    ) -> None:
        stmt = (
            select(StudentAttestation)
            .options(
                selectinload(StudentAttestation.student),
                selectinload(StudentAttestation.member_evaluations)
                .selectinload(CommissionMemberEvaluation.criterion_values)
                .selectinload(CommissionMemberCriterionEvaluation.student_attestation_criterion),
            )
            .where(StudentAttestation.id == student_attestation_id)
        )

        attestation = self.session.scalar(stmt)

        if attestation is None or attestation.student is None:
            return

        submitted_evaluations = [
            item
            for item in attestation.member_evaluations
            if item.status == "submitted"
        ]

        student = attestation.student

        student.publications_count = self._extract_max_count_metric(
            submitted_evaluations,
            patterns=self.PUBLICATION_PATTERNS,
        )
        student.pedagogical_practice = self._extract_any_bool_or_count_metric(
            submitted_evaluations,
            patterns=self.PEDAGOGICAL_PRACTICE_PATTERNS,
        )
        student.research_practice = self._extract_any_bool_or_count_metric(
            submitted_evaluations,
            patterns=self.RESEARCH_PRACTICE_PATTERNS,
        )
        student.implementation_act = self._extract_any_bool_or_count_metric(
            submitted_evaluations,
            patterns=self.IMPLEMENTATION_ACT_PATTERNS,
        )

    def _extract_max_count_metric(
        self,
        submitted_evaluations: list[CommissionMemberEvaluation],
        *,
        patterns: tuple[str, ...],
    ) -> int | None:
        values: list[int] = []

        for evaluation in submitted_evaluations:
            for criterion_value in evaluation.criterion_values:
                criterion_text = self._criterion_search_text(criterion_value)

                if not self._matches_any_pattern(criterion_text, patterns):
                    continue

                if criterion_value.count_value is not None:
                    values.append(int(criterion_value.count_value))

        if not values:
            return None

        return max(values)

    def _extract_any_bool_or_count_metric(
        self,
        submitted_evaluations: list[CommissionMemberEvaluation],
        *,
        patterns: tuple[str, ...],
    ) -> bool | None:
        found_metric = False

        for evaluation in submitted_evaluations:
            for criterion_value in evaluation.criterion_values:
                criterion_text = self._criterion_search_text(criterion_value)

                if not self._matches_any_pattern(criterion_text, patterns):
                    continue

                if criterion_value.boolean_value is not None:
                    found_metric = True
                    if criterion_value.boolean_value:
                        return True

                if criterion_value.count_value is not None:
                    found_metric = True
                    if criterion_value.count_value > 0:
                        return True

                if criterion_value.score_value is not None:
                    found_metric = True
                    if criterion_value.score_value > 0:
                        return True

        if found_metric:
            return False

        return None

    def _criterion_search_text(
        self,
        criterion_value: CommissionMemberCriterionEvaluation,
    ) -> str:
        criterion = criterion_value.student_attestation_criterion

        parts = [
            criterion.code,
            criterion.name,
            criterion.description,
            criterion.group_code,
            criterion.group_name,
            criterion.unit_label,
        ]

        return " ".join(str(part).lower() for part in parts if part)

    def _matches_any_pattern(
        self,
        value: str,
        patterns: tuple[str, ...],
    ) -> bool:
        return any(pattern in value for pattern in patterns)

    def _is_criterion_value_filled(
        self,
        item: CommissionMemberCriterionEvaluation,
    ) -> bool:
        if item.evaluation_type == "score":
            return item.score_value is not None

        if item.evaluation_type == "boolean":
            return item.boolean_value is not None

        if item.evaluation_type == "count":
            return item.count_value is not None

        return False

    def _calculate_normalized_score(
        self,
        value_row: CommissionMemberCriterionEvaluation,
    ) -> Decimal | None:
        criterion = value_row.student_attestation_criterion

        if value_row.evaluation_type == "score":
            if value_row.score_value is None:
                return None

            max_score = criterion.max_score
            if max_score is None or Decimal(max_score) <= 0:
                return None

            raw = Decimal(value_row.score_value) / Decimal(max_score)
            return self._clamp_normalized(raw)

        if value_row.evaluation_type == "boolean":
            if value_row.boolean_value is None:
                return None

            return Decimal("1.0000") if value_row.boolean_value else Decimal("0.0000")

        if value_row.evaluation_type == "count":
            if value_row.count_value is None:
                return None

            count_norm = criterion.count_norm or Decimal("1")
            if Decimal(count_norm) <= 0:
                count_norm = Decimal("1")

            raw = Decimal(value_row.count_value) / Decimal(count_norm)
            return self._clamp_normalized(raw)

        return None

    def _recalculate_integral_scores(
        self,
        evaluation: CommissionMemberEvaluation,
    ) -> None:
        grouped_scores: dict[str, list[Decimal]] = {
            self.GROUP_LOGIC_HYPOTHESIS: [],
            self.GROUP_METHODS: [],
            self.GROUP_SCIENTIFIC_FOUNDATION: [],
            self.GROUP_TEXT_PROGRESS: [],
        }

        for value_row in evaluation.criterion_values:
            if value_row.normalized_score is None:
                continue

            criterion = value_row.student_attestation_criterion
            group_code = self._normalize_group_code(criterion.group_code, criterion.group_name)

            if group_code not in grouped_scores:
                continue

            grouped_scores[group_code].append(Decimal(value_row.normalized_score))

        evaluation.logic_hypothesis_score = self._average_or_none(
            grouped_scores[self.GROUP_LOGIC_HYPOTHESIS]
        )
        evaluation.methods_score = self._average_or_none(
            grouped_scores[self.GROUP_METHODS]
        )
        evaluation.scientific_foundation_score = self._average_or_none(
            grouped_scores[self.GROUP_SCIENTIFIC_FOUNDATION]
        )
        evaluation.text_progress_score = self._average_or_none(
            grouped_scores[self.GROUP_TEXT_PROGRESS]
        )

        existing_group_scores = [
            score
            for score in [
                evaluation.logic_hypothesis_score,
                evaluation.methods_score,
                evaluation.scientific_foundation_score,
                evaluation.text_progress_score,
            ]
            if score is not None
        ]

        evaluation.overall_integral_score = self._average_or_none(existing_group_scores)

    def _normalize_group_code(
        self,
        group_code: str | None,
        group_name: str | None,
    ) -> str | None:
        if group_code:
            return group_code

        if group_name is None:
            return None

        normalized_name = group_name.strip().lower()

        mapping = {
            "логика и гипотеза": self.GROUP_LOGIC_HYPOTHESIS,
            "методы": self.GROUP_METHODS,
            "научный задел": self.GROUP_SCIENTIFIC_FOUNDATION,
            "прогресс текста": self.GROUP_TEXT_PROGRESS,
        }

        return mapping.get(normalized_name)

    def _average_or_none(self, values: list[Decimal]) -> Decimal | None:
        if not values:
            return None

        return self._round_decimal(sum(values) / Decimal(len(values)))

    def _clamp_normalized(self, value: Decimal) -> Decimal:
        if value < 0:
            value = Decimal("0")
        if value > 1:
            value = Decimal("1")

        return self._round_decimal(value)

    def _round_decimal(self, value: Decimal) -> Decimal:
        return Decimal(value).quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP)

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