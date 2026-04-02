from __future__ import annotations

from sqlalchemy import and_, select
from sqlalchemy.orm import Session, selectinload

from app.db.models import (
    AttestationCriterionTemplate,
    AttestationPeriod,
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
                    "department_name": item.department.name,
                    "supervisor_name": supervisor_name,
                    "is_admitted": item.is_admitted,
                    "debt_note": item.debt_note,
                    "status": item.status,
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

            student_attestation.is_admitted = item.is_admitted
            student_attestation.debt_note = item.debt_note
            student_attestation.admission_comment = item.admission_comment

            if item.is_admitted and student_attestation.status == "draft":
                student_attestation.status = "admitted"
            elif not item.is_admitted and student_attestation.status == "admitted":
                student_attestation.status = "draft"

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