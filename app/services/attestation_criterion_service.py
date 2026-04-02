from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db.models import AttestationCriterion, AttestationCriterionTemplate
from app.schemas.attestation_criterion import AttestationCriterionTemplateCreate


class AttestationCriterionService:
    def __init__(self, session: Session) -> None:
        self.session = session

    def list_templates(self) -> list[AttestationCriterionTemplate]:
        stmt = (
            select(AttestationCriterionTemplate)
            .options(selectinload(AttestationCriterionTemplate.criteria))
            .order_by(
                AttestationCriterionTemplate.period_type,
                AttestationCriterionTemplate.program_duration_years,
                AttestationCriterionTemplate.course,
                AttestationCriterionTemplate.season,
            )
        )
        return list(self.session.scalars(stmt).unique().all())

    def get_template(self, template_id) -> AttestationCriterionTemplate | None:
        stmt = (
            select(AttestationCriterionTemplate)
            .options(selectinload(AttestationCriterionTemplate.criteria))
            .where(AttestationCriterionTemplate.id == template_id)
        )
        return self.session.scalar(stmt)

    def create_template(
        self,
        payload: AttestationCriterionTemplateCreate,
    ) -> AttestationCriterionTemplate:
        template = AttestationCriterionTemplate(
            name=payload.name,
            period_type=payload.period_type,
            program_duration_years=payload.program_duration_years,
            course=payload.course,
            season=payload.season,
            is_active=payload.is_active,
        )
        self.session.add(template)
        self.session.flush()

        for criterion_payload in payload.criteria:
            criterion = AttestationCriterion(
                template_id=template.id,
                code=criterion_payload.code,
                name=criterion_payload.name,
                description=criterion_payload.description,
                evaluation_type=criterion_payload.evaluation_type,
                max_score=criterion_payload.max_score,
                unit_label=criterion_payload.unit_label,
                checked_by_student=criterion_payload.checked_by_student,
                checked_by_supervisor=criterion_payload.checked_by_supervisor,
                sort_order=criterion_payload.sort_order,
                is_active=criterion_payload.is_active,
            )
            self.session.add(criterion)

        self.session.commit()
        self.session.refresh(template)

        return self.get_template(template.id)  # type: ignore[return-value]