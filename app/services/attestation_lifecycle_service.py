from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.constants.attestation_stages import ATTESTATION_STAGES
from app.db.models import AttestationPeriod, StudentAttestation


class AttestationLifecycleService:
    def __init__(self, session: Session) -> None:
        self.session = session

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

    @staticmethod
    def list_stages() -> list[dict]:
        return ATTESTATION_STAGES

    def get_history(self) -> list[dict]:
        stmt = (
            select(AttestationPeriod)
            .where(AttestationPeriod.type == "attestation")
            .where(AttestationPeriod.is_completed.is_(True))
            .order_by(AttestationPeriod.year.desc(), AttestationPeriod.season.desc())
        )
        periods = list(self.session.scalars(stmt).all())

        result_by_year: dict[int, dict] = {}

        for period in periods:
            passed_count_stmt = (
                select(func.count(StudentAttestation.id))
                .where(StudentAttestation.attestation_period_id == period.id)
                .where(StudentAttestation.final_decision.is_not(None))
            )
            total_count_stmt = (
                select(func.count(StudentAttestation.id))
                .where(StudentAttestation.attestation_period_id == period.id)
            )

            passed_count = self.session.scalar(passed_count_stmt) or 0
            total_count = self.session.scalar(total_count_stmt) or 0

            season_data = {
                "id": period.id,
                "start_date": period.start_date,
                "end_date": period.end_date,
                "passed_students_count": passed_count,
                "total_students_count": total_count,
            }

            if period.year not in result_by_year:
                result_by_year[period.year] = {
                    "year": period.year,
                    "spring": None,
                    "autumn": None,
                }

            result_by_year[period.year][period.season] = season_data

        return list(result_by_year.values())

    def update_stage(self, period_id, current_stage_number: int) -> dict:
        period = self.session.get(AttestationPeriod, period_id)
        if period is None:
            raise ValueError("Attestation period not found")

        if period.type != "attestation":
            raise ValueError("Stage lifecycle is available only for attestation periods")

        period.current_stage_number = current_stage_number
        period.is_active = True
        period.is_completed = False
        period.status = "active"

        self.session.commit()
        self.session.refresh(period)

        return {
            "id": period.id,
            "current_attestation": period.season,
            "start_date": period.start_date,
            "end_date": period.end_date,
            "current_stage_number": period.current_stage_number,
        }