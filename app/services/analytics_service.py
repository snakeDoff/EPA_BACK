from __future__ import annotations

import re
from collections import defaultdict
from decimal import Decimal, ROUND_HALF_UP
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db.models import (
    CommissionMemberCriterionEvaluation,
    CommissionMemberEvaluation,
    Department,
    Student,
    StudentAttestation,
)


class AnalyticsService:
    GROUP_LOGIC_HYPOTHESIS = "logic_hypothesis"
    GROUP_METHODS = "methods"
    GROUP_SCIENTIFIC_FOUNDATION = "scientific_foundation"
    GROUP_TEXT_PROGRESS = "text_progress"

    GROUPS = [
        {
            "code": GROUP_SCIENTIFIC_FOUNDATION,
            "name": "Научный задел",
            "weight": Decimal("0.1"),
            "field": "scientific_foundation_score",
            "sort_order": 1,
        },
        {
            "code": GROUP_LOGIC_HYPOTHESIS,
            "name": "Логика и гипотеза",
            "weight": Decimal("0.2"),
            "field": "logic_hypothesis_score",
            "sort_order": 2,
        },
        {
            "code": GROUP_METHODS,
            "name": "Методы",
            "weight": Decimal("0.3"),
            "field": "methods_score",
            "sort_order": 3,
        },
        {
            "code": GROUP_TEXT_PROGRESS,
            "name": "Прогресс текста",
            "weight": Decimal("0.5"),
            "field": "text_progress_score",
            "sort_order": 4,
        },
    ]

    def __init__(self, session: Session) -> None:
        self.session = session
        
    def list_departments(self, only_active: bool = True) -> list[dict]:
        stmt = select(Department).order_by(Department.name.asc())

        if only_active:
            stmt = stmt.where(Department.is_active.is_(True))

        items = list(self.session.scalars(stmt).all())

        return [
            {
                "id": str(item.id),
                "name": item.name,
                "short_name": item.short_name,
                "is_active": item.is_active,
            }
            for item in items
        ]
    def get_departments_score(self, period_id: UUID) -> list[dict]:
        items = self._get_attestations(period_id)

        grouped: dict[UUID, dict] = {}

        for item in items:
            score = self._calculate_attestation_weighted_score(item)
            if score is None:
                continue

            department = item.department
            if department is None:
                continue

            if department.id not in grouped:
                grouped[department.id] = {
                    "department_id": str(department.id),
                    "department_name": department.name,
                    "department_short_name": department.short_name,
                    "scores": [],
                    "students_count": 0,
                }

            grouped[department.id]["scores"].append(score)
            grouped[department.id]["students_count"] += 1

        result = []
        for row in grouped.values():
            average_score = self._average_decimal(row.pop("scores"))

            result.append(
                {
                    **row,
                    "average_score": self._to_float(average_score),
                    "average_percent": self._to_percent(average_score),
                }
            )

        return sorted(
            result,
            key=lambda row: row["average_score"] if row["average_score"] is not None else -1,
            reverse=True,
        )

    def get_departments_risk(self, period_id: UUID) -> list[dict]:
        items = self._get_attestations(period_id)

        grouped: dict[UUID, dict] = {}

        for item in items:
            score = self._calculate_attestation_weighted_score(item)
            if score is None:
                continue

            department = item.department
            if department is None:
                continue

            if department.id not in grouped:
                grouped[department.id] = {
                    "department_id": str(department.id),
                    "department_name": department.name,
                    "department_short_name": department.short_name,
                    "green_count": 0,
                    "yellow_count": 0,
                    "red_count": 0,
                    "total_count": 0,
                }

            risk = self._get_risk_status(score)
            grouped[department.id][f"{risk}_count"] += 1
            grouped[department.id]["total_count"] += 1

        result = []
        for row in grouped.values():
            total_count = row["total_count"]

            result.append(
                {
                    **row,
                    "green_percent": self._percent_from_count(row["green_count"], total_count),
                    "yellow_percent": self._percent_from_count(row["yellow_count"], total_count),
                    "red_percent": self._percent_from_count(row["red_count"], total_count),
                }
            )

        return sorted(result, key=lambda row: row["department_name"])

    def get_department_criteria(
        self,
        period_id: UUID,
        department_id: UUID,
    ) -> list[dict]:
        items = [
            item
            for item in self._get_attestations(period_id)
            if item.department_id == department_id
        ]

        return self._calculate_group_averages(items)

    def get_readiness_dynamics(self, period_id: UUID) -> list[dict]:
        current_items = self._get_attestations(period_id)

        if not current_items:
            return []

        student_ids = {item.student_id for item in current_items}

        stmt = (
            select(StudentAttestation)
            .options(
                selectinload(StudentAttestation.period),
                selectinload(StudentAttestation.criteria),
                selectinload(StudentAttestation.member_evaluations)
                .selectinload(CommissionMemberEvaluation.criterion_values)
                .selectinload(CommissionMemberCriterionEvaluation.student_attestation_criterion),
            )
            .where(StudentAttestation.student_id.in_(student_ids))
        )

        items = list(self.session.scalars(stmt).unique().all())

        grouped: dict[UUID, dict] = {}

        for item in items:
            period = item.period
            if period is None:
                continue

            actual_percent = self._calculate_attestation_readiness_percent(item)
            normative_percent = self._calculate_attestation_normative_readiness_percent(item)

            if actual_percent is None and normative_percent is None:
                continue

            if period.id not in grouped:
                grouped[period.id] = {
                    "period_id": str(period.id),
                    "period_title": period.title,
                    "year": period.year,
                    "season": period.season,
                    "actual_values": [],
                    "normative_values": [],
                }

            if actual_percent is not None:
                grouped[period.id]["actual_values"].append(actual_percent)

            if normative_percent is not None:
                grouped[period.id]["normative_values"].append(normative_percent)

        result = []
        for row in grouped.values():
            actual_percent = self._average_decimal(row.pop("actual_values"))
            normative_percent = self._average_decimal(row.pop("normative_values"))

            result.append(
                {
                    **row,
                    "actual_percent": self._to_float(actual_percent),
                    "normative_percent": self._to_float(normative_percent),
                }
            )

        return sorted(
            result,
            key=lambda row: (
                row["year"] if row["year"] is not None else 0,
                self._season_sort_value(row["season"]),
            ),
        )

    def get_education_programs_score(self, period_id: UUID) -> list[dict]:
        items = self._get_attestations(period_id)

        grouped: dict[UUID, dict] = {}

        for item in items:
            score = self._calculate_attestation_weighted_score(item)
            if score is None:
                continue

            student = item.student
            if student is None or student.education_program is None:
                continue

            program = student.education_program

            if program.id not in grouped:
                grouped[program.id] = {
                    "education_program_id": str(program.id),
                    "education_program_name": program.name,
                    "education_program_short_name": program.short_name,
                    "duration_years": program.duration_years,
                    "scores": [],
                    "students_count": 0,
                }

            grouped[program.id]["scores"].append(score)
            grouped[program.id]["students_count"] += 1

        result = []
        for row in grouped.values():
            average_score = self._average_decimal(row.pop("scores"))

            result.append(
                {
                    **row,
                    "average_score": self._to_float(average_score),
                    "average_percent": self._to_percent(average_score),
                }
            )

        return sorted(
            result,
            key=lambda row: row["average_score"] if row["average_score"] is not None else -1,
            reverse=True,
        )

    def get_specialties_rating(self, period_id: UUID) -> dict:
        items = self._get_attestations(period_id)

        grouped: dict[str, dict] = {}

        for item in items:
            score = self._calculate_attestation_weighted_score(item)
            if score is None:
                continue

            student = item.student
            if student is None:
                continue

            specialty = student.specialty or "Не указано"

            if specialty not in grouped:
                grouped[specialty] = {
                    "specialty": specialty,
                    "scores": [],
                    "students_count": 0,
                }

            grouped[specialty]["scores"].append(score)
            grouped[specialty]["students_count"] += 1

        rows = []
        for row in grouped.values():
            average_score = self._average_decimal(row.pop("scores"))

            rows.append(
                {
                    **row,
                    "average_score": self._to_float(average_score),
                    "average_percent": self._to_percent(average_score),
                }
            )

        rows = sorted(
            rows,
            key=lambda row: row["average_score"] if row["average_score"] is not None else -1,
            reverse=True,
        )

        return {
            "top": rows[:5],
            "bottom": list(reversed(rows[-5:])) if rows else [],
        }

    def get_supervisors_rating(self, period_id: UUID) -> list[dict]:
        items = self._get_attestations(period_id)

        grouped: dict[str, dict] = {}

        for item in items:
            score = self._calculate_attestation_weighted_score(item)
            if score is None:
                continue

            student = item.student
            if student is None:
                continue

            supervisor_key = self._get_supervisor_key(student)
            supervisor_name = self._get_supervisor_name(student)

            if supervisor_key not in grouped:
                grouped[supervisor_key] = {
                    "supervisor_user_id": (
                        str(student.supervisor_user_id)
                        if student.supervisor_user_id is not None
                        else None
                    ),
                    "supervisor_name": supervisor_name,
                    "scores": [],
                    "students_count": 0,
                    "graduates_count": 0,
                }

            grouped[supervisor_key]["scores"].append(score)
            grouped[supervisor_key]["students_count"] += 1

            if self._is_graduate(item):
                grouped[supervisor_key]["graduates_count"] += 1

        result = []
        for row in grouped.values():
            average_score = self._average_decimal(row.pop("scores"))
            students_count = row["students_count"]

            result.append(
                {
                    **row,
                    "average_score": self._to_float(average_score),
                    "average_percent": self._to_percent(average_score),
                    "graduates_percent": self._percent_from_count(
                        row["graduates_count"],
                        students_count,
                    ),
                    "point_size": students_count,
                }
            )

        return sorted(
            result,
            key=lambda row: row["average_score"] if row["average_score"] is not None else -1,
            reverse=True,
        )

    def get_supervisor_criteria(
        self,
        period_id: UUID,
        supervisor_user_id: UUID,
    ) -> list[dict]:
        items = [
            item
            for item in self._get_attestations(period_id)
            if item.student is not None and item.student.supervisor_user_id == supervisor_user_id
        ]

        return self._calculate_group_averages(items)

    def _get_attestations(self, period_id: UUID) -> list[StudentAttestation]:
        stmt = (
            select(StudentAttestation)
            .options(
                selectinload(StudentAttestation.period),
                selectinload(StudentAttestation.student).selectinload(Student.education_program),
                selectinload(StudentAttestation.student).selectinload(Student.supervisor),
                selectinload(StudentAttestation.department),
                selectinload(StudentAttestation.criteria),
                selectinload(StudentAttestation.member_evaluations)
                .selectinload(CommissionMemberEvaluation.criterion_values)
                .selectinload(CommissionMemberCriterionEvaluation.student_attestation_criterion),
            )
            .where(StudentAttestation.attestation_period_id == period_id)
        )

        return list(self.session.scalars(stmt).unique().all())

    def _calculate_attestation_weighted_score(
        self,
        attestation: StudentAttestation,
    ) -> Decimal | None:
        submitted_evaluations = self._get_submitted_evaluations(attestation)

        scores = [
            self._calculate_evaluation_weighted_score(evaluation)
            for evaluation in submitted_evaluations
        ]
        scores = [score for score in scores if score is not None]

        return self._average_decimal(scores)

    def _calculate_evaluation_weighted_score(
        self,
        evaluation: CommissionMemberEvaluation,
    ) -> Decimal | None:
        weighted_sum = Decimal("0")
        used_weight_sum = Decimal("0")

        for group in self.GROUPS:
            value = getattr(evaluation, group["field"], None)

            if value is None:
                continue

            weight = group["weight"]
            weighted_sum += Decimal(value) * weight
            used_weight_sum += weight

        if used_weight_sum <= 0:
            return None

        return self._round_decimal(weighted_sum / used_weight_sum)

    def _calculate_group_averages(
        self,
        attestations: list[StudentAttestation],
    ) -> list[dict]:
        result = []

        for group in self.GROUPS:
            values = []

            for item in attestations:
                for evaluation in self._get_submitted_evaluations(item):
                    value = getattr(evaluation, group["field"], None)

                    if value is not None:
                        values.append(Decimal(value))

            average_score = self._average_decimal(values)

            result.append(
                {
                    "group_code": group["code"],
                    "group_name": group["name"],
                    "sort_order": group["sort_order"],
                    "average_score": self._to_float(average_score),
                    "average_percent": self._to_percent(average_score),
                }
            )

        return result

    def _get_submitted_evaluations(
        self,
        attestation: StudentAttestation,
    ) -> list[CommissionMemberEvaluation]:
        return [
            evaluation
            for evaluation in attestation.member_evaluations
            if evaluation.status == "submitted"
        ]

    def _get_risk_status(self, score: Decimal) -> str:
        if score >= Decimal("0.9999"):
            return "green"

        if score >= Decimal("0.7000"):
            return "yellow"

        return "red"

    def _calculate_attestation_readiness_percent(
        self,
        attestation: StudentAttestation,
    ) -> Decimal | None:
        values = []

        for evaluation in self._get_submitted_evaluations(attestation):
            for criterion_value in evaluation.criterion_values:
                criterion = criterion_value.student_attestation_criterion

                if criterion is None:
                    continue

                if not self._is_readiness_criterion(criterion.name):
                    continue

                criterion_percent = self._extract_percent_from_text(criterion.name)

                if criterion_percent is None:
                    continue

                if criterion_value.boolean_value is not None:
                    values.append(criterion_percent if criterion_value.boolean_value else Decimal("0"))
                    continue

                if criterion_value.normalized_score is not None:
                    values.append(criterion_percent * Decimal(criterion_value.normalized_score))
                    continue

                if criterion_value.score_value is not None and criterion.max_score is not None:
                    max_score = Decimal(criterion.max_score)
                    if max_score > 0:
                        values.append(
                            criterion_percent
                            * self._clamp_decimal(Decimal(criterion_value.score_value) / max_score)
                        )

        return self._average_decimal(values)

    def _calculate_attestation_normative_readiness_percent(
        self,
        attestation: StudentAttestation,
    ) -> Decimal | None:
        values = []

        for criterion in attestation.criteria:
            if not self._is_readiness_criterion(criterion.name):
                continue

            criterion_percent = self._extract_percent_from_text(criterion.name)

            if criterion_percent is not None:
                values.append(criterion_percent)

        return self._average_decimal(values)

    def _is_readiness_criterion(self, name: str | None) -> bool:
        if not name:
            return False

        value = name.strip().lower()

        return "готовность текста диссертации" in value

    def _extract_percent_from_text(self, value: str | None) -> Decimal | None:
        if not value:
            return None

        match = re.search(r"(\d+)\s*%", value)

        if not match:
            return None

        return Decimal(match.group(1))

    def _get_supervisor_key(self, student: Student) -> str:
        if student.supervisor_user_id is not None:
            return str(student.supervisor_user_id)

        if student.supervisor_name_raw:
            return student.supervisor_name_raw.strip().lower()

        return "unknown"

    def _get_supervisor_name(self, student: Student) -> str:
        if student.supervisor is not None:
            parts = [
                student.supervisor.last_name,
                student.supervisor.first_name,
                student.supervisor.middle_name,
            ]
            return " ".join(part for part in parts if part)

        if student.supervisor_name_raw:
            return student.supervisor_name_raw

        return "Не указан"

    def _is_graduate(self, attestation: StudentAttestation) -> bool:
        student = attestation.student

        if attestation.final_decision == "passed":
            return True

        if student is not None and student.academic_status:
            normalized_status = student.academic_status.strip().lower()
            return "выпуск" in normalized_status or "окончил" in normalized_status

        return False

    def _average_decimal(self, values: list[Decimal]) -> Decimal | None:
        if not values:
            return None

        return self._round_decimal(sum(values) / Decimal(len(values)))

    def _percent_from_count(
        self,
        value: int,
        total: int,
    ) -> float:
        if total <= 0:
            return 0.0

        return round(value / total * 100, 2)

    def _to_float(self, value: Decimal | None) -> float | None:
        if value is None:
            return None

        return float(value)

    def _to_percent(self, value: Decimal | None) -> float | None:
        if value is None:
            return None

        return round(float(value) * 100, 2)

    def _round_decimal(self, value: Decimal) -> Decimal:
        return Decimal(value).quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP)

    def _clamp_decimal(self, value: Decimal) -> Decimal:
        if value < 0:
            return Decimal("0")

        if value > 1:
            return Decimal("1")

        return value

    def _season_sort_value(self, season: str | None) -> int:
        if season == "spring":
            return 1

        if season == "autumn":
            return 2

        return 0