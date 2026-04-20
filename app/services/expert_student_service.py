from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db.models import (
    CommissionMemberCriterionEvaluation,
    CommissionMemberEvaluation,
    Student,
    StudentAttestation,
)


class ExpertStudentService:
    def __init__(self, session: Session) -> None:
        self.session = session

    def list_students_by_department(self, department_id):
        stmt = (
            select(StudentAttestation)
            .options(
                selectinload(StudentAttestation.student).selectinload(Student.education_program),
                selectinload(StudentAttestation.department),
                selectinload(StudentAttestation.supervisor),
                selectinload(StudentAttestation.criteria),
                selectinload(StudentAttestation.member_evaluations)
                .selectinload(CommissionMemberEvaluation.criterion_values)
                .selectinload(CommissionMemberCriterionEvaluation.student_attestation_criterion),
            )
            .where(StudentAttestation.department_id == department_id)
            .order_by(StudentAttestation.student_id)
        )

        items = list(self.session.scalars(stmt).unique().all())

        rows = []
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

            average_score = self._calculate_average_score(item)

            publications_count = self._extract_int_metric(
                item,
                codes={"publications_count", "scientific_publications", "publications"},
                names={
                    "Научные публикации",
                    "Научные публикации: полное библиографическое описание с указанием списков НИУ ВШЭ",
                },
            )
            pedagogical_practice = self._extract_bool_metric(
                item,
                codes={"pedagogical_practice", "scientific_pedagogical_practice"},
                names={"Научно-педагогическая практика"},
            )
            research_practice = self._extract_bool_metric(
                item,
                codes={"research_practice", "scientific_research_practice"},
                names={
                    "Научно-исследовательская практика",
                    "Научно-исследовательская практика (стажировки, гранты, конференции, РИДы и др.)",
                },
            )
            implementation_act = self._extract_bool_metric(
                item,
                codes={"implementation_act", "acts_of_implementation"},
                names={"Акты внедрения", "Акт внедрения"},
            )

            rows.append(
                {
                    "student_attestation_id": item.id,
                    "student_id": student.id,
                    "admission_year": student.admission_year,
                    "course": student.course,
                    "fio": fio,
                    "funding_type": student.funding_type,
                    "education_program_name": program.name,
                    "duration_years": program.duration_years,
                    "specialty": student.specialty,
                    "academic_status": getattr(student, "academic_status", None),
                    "department_name": item.department.name,
                    "supervisor_name": supervisor_name,
                    "dissertation_topic": getattr(student, "dissertation_topic", None),
                    "is_admitted": item.is_admitted,
                    "debt_note": item.debt_note,
                    "status": item.status,
                    "attestation_result": item.final_decision,
                    "average_score": average_score,
                    "publications_count": publications_count,
                    "pedagogical_practice": pedagogical_practice,
                    "research_practice": research_practice,
                    "implementation_act": implementation_act,
                    "predefense_date": None,
                    "status_change_reason": getattr(student, "status_change_reason", None),
                }
            )

        return rows

    def _calculate_average_score(self, attestation: StudentAttestation) -> float | None:
        score_values: list[float] = []

        for member_evaluation in attestation.member_evaluations:
            if member_evaluation.status != "submitted":
                continue

            for criterion_value in member_evaluation.criterion_values:
                if (
                    criterion_value.evaluation_type == "score"
                    and criterion_value.score_value is not None
                ):
                    score_values.append(float(criterion_value.score_value))

        if not score_values:
            return None

        return round(sum(score_values) / len(score_values), 2)

    def _extract_int_metric(
        self,
        attestation: StudentAttestation,
        *,
        codes: set[str],
        names: set[str],
    ) -> int | None:
        for member_evaluation in attestation.member_evaluations:
            if member_evaluation.status != "submitted":
                continue

            for criterion_value in member_evaluation.criterion_values:
                criterion = criterion_value.student_attestation_criterion
                if criterion.code in codes or criterion.name in names:
                    if criterion_value.count_value is not None:
                        return int(criterion_value.count_value)

        for criterion in attestation.criteria:
            if criterion.code in codes or criterion.name in names:
                return None

        return None

    def _extract_bool_metric(
        self,
        attestation: StudentAttestation,
        *,
        codes: set[str],
        names: set[str],
    ) -> bool | None:
        for member_evaluation in attestation.member_evaluations:
            if member_evaluation.status != "submitted":
                continue

            for criterion_value in member_evaluation.criterion_values:
                criterion = criterion_value.student_attestation_criterion
                if criterion.code in codes or criterion.name in names:
                    if criterion_value.boolean_value is not None:
                        return bool(criterion_value.boolean_value)

        for criterion in attestation.criteria:
            if criterion.code in codes or criterion.name in names:
                return None

        return None