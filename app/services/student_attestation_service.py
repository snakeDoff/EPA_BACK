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
                        AttestationCriterionTemplate.program_duration_years
                        == student.education_program.duration_years,
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
                    group_code=template_criterion.group_code,
                    group_name=template_criterion.group_name,
                    group_sort_order=template_criterion.group_sort_order,
                    count_norm=template_criterion.count_norm,
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

    def _get_value(self, obj, field: str, default=None):
        if obj is None:
            return default

        if isinstance(obj, dict):
            return obj.get(field, default)

        return getattr(obj, field, default)

    def _first_not_none(self, *values):
        for value in values:
            if value is not None:
                return value
        return None

    def _normalize_metric_key(self, value) -> str:
        if value is None:
            return ""

        return (
            str(value)
            .strip()
            .lower()
            .replace("ё", "е")
            .replace("-", "_")
            .replace(" ", "_")
        )

    def _add_search_values(self, target: list, value) -> None:
        if value is None:
            return

        if isinstance(value, (str, int, float, bool)):
            target.append(value)
            return

        if isinstance(value, dict):
            for item in value.values():
                self._add_search_values(target, item)
            return

        try:
            for item in value:
                self._add_search_values(target, item)
        except TypeError:
            target.append(value)

    def _collect_search_values(
        self,
        aliases=None,
        codes=None,
        names=None,
        ids=None,
        filters: dict | None = None,
    ) -> list:
        search_values = []

        self._add_search_values(search_values, aliases)
        self._add_search_values(search_values, codes)
        self._add_search_values(search_values, names)
        self._add_search_values(search_values, ids)

        if filters:
            for value in filters.values():
                self._add_search_values(search_values, value)

        return search_values

    def _get_metric_items(self, source):
        if source is None:
            return []

        if isinstance(source, dict):
            if "criteria" in source:
                return list(source.get("criteria") or [])

            if "criterion_values" in source:
                return list(source.get("criterion_values") or [])

            return [source]

        criteria = getattr(source, "criteria", None)
        if criteria is not None:
            return list(criteria or [])

        criterion_values = getattr(source, "criterion_values", None)
        if criterion_values is not None:
            return list(criterion_values or [])

        if isinstance(source, (str, bytes)):
            return []

        try:
            return list(source)
        except TypeError:
            return [source]

    def _get_direct_metric_value(self, source, search_values):
        if source is None:
            return None

        targets = [source]

        student = self._get_value(source, "student")
        if student is not None:
            targets.append(student)

        normalized_search_values = {
            self._normalize_metric_key(value)
            for value in search_values
            if value is not None
        }

        if not normalized_search_values:
            return None

        for target in targets:
            if target is None:
                continue

            if isinstance(target, dict):
                for key, value in target.items():
                    if self._normalize_metric_key(key) in normalized_search_values:
                        if value is not None:
                            return value
                continue

            for raw_key in search_values:
                if raw_key is None:
                    continue

                possible_attr_names = {
                    str(raw_key),
                    self._normalize_metric_key(raw_key),
                }

                for attr_name in possible_attr_names:
                    if not attr_name:
                        continue

                    if hasattr(target, attr_name):
                        value = getattr(target, attr_name)
                        if value is not None:
                            return value

        return None

    def _criterion_matches(
        self,
        criterion_value,
        aliases=None,
        codes=None,
        names=None,
        ids=None,
        **filters,
    ) -> bool:
        search_values = self._collect_search_values(
            aliases=aliases,
            codes=codes,
            names=names,
            ids=ids,
            filters=filters,
        )

        normalized_search_values = {
            self._normalize_metric_key(value)
            for value in search_values
            if value is not None
        }

        if not normalized_search_values:
            return False

        criterion = (
            self._get_value(criterion_value, "criterion")
            or self._get_value(criterion_value, "attestation_criterion")
            or self._get_value(criterion_value, "student_attestation_criterion")
        )

        possible_keys = [
            self._get_value(criterion_value, "id"),
            self._get_value(criterion_value, "code"),
            self._get_value(criterion_value, "name"),
            self._get_value(criterion_value, "title"),
            self._get_value(criterion_value, "label"),
            self._get_value(criterion_value, "student_attestation_criterion_id"),
            self._get_value(criterion, "id"),
            self._get_value(criterion, "code"),
            self._get_value(criterion, "name"),
            self._get_value(criterion, "title"),
            self._get_value(criterion, "label"),
        ]

        normalized_keys = {
            self._normalize_metric_key(key)
            for key in possible_keys
            if key is not None
        }

        return bool(normalized_search_values & normalized_keys)

    def _extract_int_metric(
        self,
        criteria_values=None,
        aliases=None,
        codes=None,
        names=None,
        ids=None,
        default: int = 0,
        **filters,
    ) -> int:
        filters = dict(filters)

        if criteria_values is None:
            criteria_values = (
                filters.pop("criteria", None)
                or filters.pop("criterion_values", None)
                or filters.pop("attestation", None)
                or filters.pop("student_attestation", None)
            )

        search_values = self._collect_search_values(
            aliases=aliases,
            codes=codes,
            names=names,
            ids=ids,
            filters=filters,
        )

        for criterion_value in self._get_metric_items(criteria_values):
            if not self._criterion_matches(
                criterion_value,
                aliases=aliases,
                codes=codes,
                names=names,
                ids=ids,
                **filters,
            ):
                continue

            value = self._first_not_none(
                self._get_value(criterion_value, "count_value"),
                self._get_value(criterion_value, "score_value"),
                self._get_value(criterion_value, "value"),
            )

            if value is None:
                continue

            try:
                return int(value)
            except (TypeError, ValueError):
                return default

        direct_value = self._get_direct_metric_value(criteria_values, search_values)

        if direct_value is not None:
            try:
                return int(direct_value)
            except (TypeError, ValueError):
                return default

        return default

    def _extract_float_metric(
        self,
        criteria_values=None,
        aliases=None,
        codes=None,
        names=None,
        ids=None,
        default: float = 0.0,
        **filters,
    ) -> float:
        filters = dict(filters)

        if criteria_values is None:
            criteria_values = (
                filters.pop("criteria", None)
                or filters.pop("criterion_values", None)
                or filters.pop("attestation", None)
                or filters.pop("student_attestation", None)
            )

        search_values = self._collect_search_values(
            aliases=aliases,
            codes=codes,
            names=names,
            ids=ids,
            filters=filters,
        )

        for criterion_value in self._get_metric_items(criteria_values):
            if not self._criterion_matches(
                criterion_value,
                aliases=aliases,
                codes=codes,
                names=names,
                ids=ids,
                **filters,
            ):
                continue

            value = self._first_not_none(
                self._get_value(criterion_value, "score_value"),
                self._get_value(criterion_value, "count_value"),
                self._get_value(criterion_value, "value"),
            )

            if value is None:
                continue

            try:
                return float(value)
            except (TypeError, ValueError):
                return default

        direct_value = self._get_direct_metric_value(criteria_values, search_values)

        if direct_value is not None:
            try:
                return float(direct_value)
            except (TypeError, ValueError):
                return default

        return default

    def _to_bool(self, value, default: bool = False) -> bool:
        if value is None:
            return default

        if isinstance(value, bool):
            return value

        if isinstance(value, str):
            return value.strip().lower() in {"true", "1", "yes", "да", "y"}

        return bool(value)

    def _extract_bool_metric(
        self,
        criteria_values=None,
        aliases=None,
        codes=None,
        names=None,
        ids=None,
        default: bool = False,
        **filters,
    ) -> bool:
        filters = dict(filters)

        if criteria_values is None:
            criteria_values = (
                filters.pop("criteria", None)
                or filters.pop("criterion_values", None)
                or filters.pop("attestation", None)
                or filters.pop("student_attestation", None)
            )

        search_values = self._collect_search_values(
            aliases=aliases,
            codes=codes,
            names=names,
            ids=ids,
            filters=filters,
        )

        for criterion_value in self._get_metric_items(criteria_values):
            if not self._criterion_matches(
                criterion_value,
                aliases=aliases,
                codes=codes,
                names=names,
                ids=ids,
                **filters,
            ):
                continue

            value = self._first_not_none(
                self._get_value(criterion_value, "boolean_value"),
                self._get_value(criterion_value, "value"),
                self._get_value(criterion_value, "score_value"),
                self._get_value(criterion_value, "count_value"),
            )

            if value is None:
                continue

            return self._to_bool(value, default=default)

        direct_value = self._get_direct_metric_value(criteria_values, search_values)

        if direct_value is not None:
            return self._to_bool(direct_value, default=default)

        return default

    def _calculate_average_score(self, attestation: StudentAttestation) -> float | None:
        values: list[float] = []

        for member_evaluation in attestation.member_evaluations:
            if member_evaluation.status != "submitted":
                continue

            if member_evaluation.overall_integral_score is not None:
                values.append(float(member_evaluation.overall_integral_score))

        if not values:
            return None

        return round(sum(values) / len(values), 4)

    def _parse_optional_date(self, value: str | date | None) -> date | None:
        if value is None:
            return None

        if isinstance(value, date):
            return value

        value = value.strip()
        if not value:
            return None

        return date.fromisoformat(value)