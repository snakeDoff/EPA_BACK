from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import AttestationPeriod
from app.schemas.attestation_period import AttestationPeriodCreate, AttestationPeriodUpdate


class AttestationPeriodService:
    def __init__(self, session: Session) -> None:
        self.session = session

    def list_periods(self) -> list[AttestationPeriod]:
        stmt = select(AttestationPeriod).order_by(
            AttestationPeriod.year.desc(),
            AttestationPeriod.season.desc(),
            AttestationPeriod.created_at.desc(),
        )
        return list(self.session.scalars(stmt).all())

    def get_period(self, period_id) -> AttestationPeriod | None:
        return self.session.get(AttestationPeriod, period_id)

    def create_period(
        self,
        payload: AttestationPeriodCreate,
        created_by=None,
    ) -> AttestationPeriod:
        period = AttestationPeriod(
            title=payload.title,
            type=payload.type,
            year=payload.year,
            season=payload.season,
            start_date=payload.start_date,
            end_date=payload.end_date,
            status=payload.status,
            description=payload.description,
            is_active=payload.is_active,
            is_completed=payload.is_completed,
            current_stage_number=payload.current_stage_number,
        )
        self.session.add(period)
        self.session.commit()
        self.session.refresh(period)
        return period

    def update_period(
        self,
        period: AttestationPeriod,
        payload: AttestationPeriodUpdate,
    ) -> AttestationPeriod:
        update_data = payload.model_dump(exclude_unset=True)

        for field, value in update_data.items():
            setattr(period, field, value)

        self.session.commit()
        self.session.refresh(period)
        return period