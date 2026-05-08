from __future__ import annotations

from datetime import date

from sqlalchemy import and_, select
from sqlalchemy.orm import Session, selectinload

from app.db.models import (
    AttestationCriterionTemplate,
    AttestationPeriod,
    CommissionMemberCriterionEvaluation,
    CommissionMemberEvaluation,
    Student,
    StudentAttestation,
    StudentAttestationCriterion,
)
from app.schemas.student_attestation import StudentAttestationBulkAdmissionUpdatePayload


class StudentAttestationService:
    def __init__(self, session: Session) -> None:
        self.session = session

    def list_by_period(self, period_id):
        stmt = (
            select(StudentAttestation)
            .options(selectinload(StudentAttestation.criteria))
            .where(StudentAttestation.attestation_period_id == period_id)
            .order_by(StudentAttestation.created_at.desc())
        )
        return list(self.session.scalars(stmt).unique().all())

    def get_by_id(self, attestation_id):
        stmt = (
            select(StudentAttestation)
            .options(selectinload(StudentAttestation.criteria))
            .where(StudentAttestation.id == attestation_id)
        )
        return self.session.scalar(stmt)

    def list_table_rows(self, period_id):
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
            .where(StudentAttestation.attestation_period_id == period_id)
            .order_by(StudentAttestation.department_id, StudentAttestation.student_id)
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
                    "publications_count": student.publications_count,
                    "pedagogical_practice": student.pedagogical_practice,
                    "research_practice": student.research_practice,
                    "implementation_act": student.implementation_act,
                    "predefense_date": (
                        student.predefense_date.isoformat()
                        if student.predefense_date is not None
                        else None
                    ),
                    "status_change_reason": getattr(student, "status_change_reason", None),
                }
            )

        return rows

    def bulk_update_admission(
        self,
        period_id,
        payload: StudentAttestationBulkAdmissionUpdatePayload,
    ) -> dict:
        updated_count = 0

        for item in payload.items:
            student_attestation = self.session.get(StudentAttestation, item.student_attestation_id)

            if student_attestation is None:
                continue

            if student_attestation.attestation_period_id != period_id:
                continue

            fields_set = item.model_fields_set

            if "is_admitted" in fields_set:
                student_attestation.is_admitted = item.is_admitted

            if "debt_note" in fields_set:
                student_attestation.debt_note = item.debt_note

            if "admission_comment" in fields_set:
                student_attestation.admission_comment = item.admission_comment

            if "status" in fields_set and item.status is not None:
                student_attestation.status = item.status
            elif "is_admitted" in fields_set:
                if item.is_admitted and student_attestation.status == "draft":
                    student_attestation.status = "admitted"
                elif not item.is_admitted and student_attestation.status == "admitted":
                    student_attestation.status = "draft"

            if "attestation_result" in fields_set:
                student_attestation.final_decision = item.attestation_result

            student = student_attestation.student

            if student is not None:
                if "publications_count" in fields_set:
                    student.publications_count = item.publications_count

                if "pedagogical_practice" in fields_set:
                    student.pedagogical_practice = item.pedagogical_practice

                if "research_practice" in fields_set:
                    student.research_practice = item.research_practice

                if "implementation_act" in fields_set:
                    student.implementation_act = item.implementation_act

                if "predefense_date" in fields_set:
                    student.predefense_date = self._parse_optional_date(item.predefense_date)

            updated_count += 1

        self.session.commit()
        return {"updated_count": updated_count}

    def generate_for_period(
        self,
        period_id,
        department_id=None,
        only_active_students: bool = True,
    ) -> dict:
        period = self.session.get(AttestationPeriod, period_id)
        if period is None:
            raise ValueError("Attestation period not found")

        stmt = select(Student).options(selectinload(Student.education_program))

        if department_id is not None:
            stmt = stmt.where(Student.department_id == department_id)

        if only_active_students:
            stmt = stmt.where(Student.is_active.is_(True))

        students = list(self.session.scalars(stmt).all())

        created_count = 0
        skipped_students: list[dict] = []

        for student in students:
            existing_stmt = select(StudentAttestation).where(
                and_(
                    StudentAttestation.attestation_period_id == period_id,
                    StudentAttestation.student_id == student.id,
                )
            )
            existing = self.session.scalar(existing_stmt)
            if existing is not None:
                skipped_students.append(
                    {
                        "student_id": str(student.id),
                        "reason": "already_exists",
                    }
                )
                continue

            template_stmt = (
                select(AttestationCriterionTemplate)
                .options(selectinload(AttestationCriterionTemplate.criteria))
                .where(
                    and_(
                        AttestationCriterionTemplate.period_type == period.type,
                        AttestationCriterionTemplate.program_duration_years == student.education_program.duration_years,
                        AttestationCriterionTemplate.course == student.course,
                        AttestationCriterionTemplate.season == period.season,
                        AttestationCriterionTemplate.is_active.is_(True),
                    )
                )
            )
            template = self.session.scalar(template_stmt)

            if template is None:
                skipped_students.append(
                    {
                        "student_id": str(student.id),
                        "reason": "template_not_found",
                    }
                )
                continue

            student_attestation = StudentAttestation(
                attestation_period_id=period_id,
                student_id=student.id,
                department_id=student.department_id,
                supervisor_user_id=student.supervisor_user_id,
                criterion_template_id=template.id,
                status="draft",
                is_admitted=False,
                debt_note=None,
            )
            self.session.add(student_attestation)
            self.session.flush()

            for template_criterion in template.criteria:
                snapshot = StudentAttestationCriterion(
                    student_attestation_id=student_attestation.id,
                    template_criterion_id=template_criterion.id,
                    code=template_criterion.code,
                    name=template_criterion.name,
                    description=template_criterion.description,
                    evaluation_type=template_criterion.evaluation_type,
                    max_score=template_criterion.max_score,
                    unit_label=template_criterion.unit_label,
                    checked_by_student=template_criterion.checked_by_student,
                    checked_by_supervisor=template_criterion.checked_by_supervisor,
                    sort_order=template_criterion.sort_order,
                )
                self.session.add(snapshot)

            created_count += 1

        self.session.commit()

        return {
            "created_count": created_count,
            "skipped_count": len(skipped_students),
            "skipped_students": skipped_students,
        }

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

    def _parse_optional_date(self, value: str | date | None) -> date | None:
        if value is None:
            return None

        if isinstance(value, date):
            return value

        value = value.strip()
        if not value:
            return None

        return date.fromisoformat(value)