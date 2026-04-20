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
        payload_data = payload.model_dump(exclude_unset=True)

        allowed_fields = {column.key for column in AttestationPeriod.__table__.columns}
        filtered_data = {
            key: value
            for key, value in payload_data.items()
            if key in allowed_fields
        }

        period = AttestationPeriod(**filtered_data)

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

        allowed_fields = {column.key for column in AttestationPeriod.__table__.columns}

        for field, value in update_data.items():
            if field in allowed_fields:
                setattr(period, field, value)

        self.session.commit()
        self.session.refresh(period)
        return period

    def get_current_attestation(self) -> dict | None:
        stmt = (
            select(AttestationPeriod)
            .where(AttestationPeriod.type == "attestation")
            .where(AttestationPeriod.is_active.is_(True))
            .where(AttestationPeriod.is_completed.is_(False))
            .order_by(AttestationPeriod.year.desc(), AttestationPeriod.created_at.desc())
        )
        item = self.session.scalar(stmt)

        if item is None:
            return None

        return {
            "id": item.id,
            "current_attestation": item.season,
            "start_date": item.start_date,
            "end_date": item.end_date,
            "current_stage_number": item.current_stage_number,
        }