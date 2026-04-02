from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db.models import (
    AttestationCommission,
    CommissionMember,
    StaffMember,
    StudentAttestation,
)
from app.schemas.commission import (
    AssignStudentAttestationsToCommissionPayload,
    AttestationCommissionCreate,
)


class CommissionService:
    def __init__(self, session: Session) -> None:
        self.session = session

    def list_commissions(self, period_id):
        stmt = (
            select(AttestationCommission)
            .options(
                selectinload(AttestationCommission.members).selectinload(CommissionMember.staff_member)
            )
            .where(AttestationCommission.attestation_period_id == period_id)
            .order_by(AttestationCommission.created_at.desc())
        )
        return list(self.session.scalars(stmt).unique().all())

    def get_commission(self, commission_id):
        stmt = (
            select(AttestationCommission)
            .options(
                selectinload(AttestationCommission.members).selectinload(CommissionMember.staff_member)
            )
            .where(AttestationCommission.id == commission_id)
        )
        return self.session.scalar(stmt)

    def create_commission(self, period_id, payload: AttestationCommissionCreate, created_by=None):
        commission = AttestationCommission(
            attestation_period_id=period_id,
            department_id=payload.department_id,
            name=payload.name,
            status=payload.status,
            notes=payload.notes,
            created_by=created_by,
        )
        self.session.add(commission)
        self.session.flush()

        for item in payload.members:
            staff_member = self.session.get(StaffMember, item.staff_member_id)
            if staff_member is None:
                raise ValueError(f"Staff member not found: {item.staff_member_id}")
            if not staff_member.is_active or not staff_member.can_be_commission_member:
                raise ValueError(f"Staff member cannot be included in commission: {item.staff_member_id}")

            self.session.add(
                CommissionMember(
                    commission_id=commission.id,
                    staff_member_id=item.staff_member_id,
                    role_in_commission=item.role_in_commission,
                    membership_type=item.membership_type,
                    is_voting_member=item.is_voting_member,
                    sort_order=item.sort_order,
                )
            )

        self.session.commit()
        return self.get_commission(commission.id)

    def assign_student_attestations_to_commission(
        self,
        commission_id,
        payload: AssignStudentAttestationsToCommissionPayload,
    ) -> dict:
        commission = self.session.get(AttestationCommission, commission_id)
        if commission is None:
            raise ValueError("Commission not found")

        updated_count = 0

        for attestation_id in payload.student_attestation_ids:
            item = self.session.get(StudentAttestation, attestation_id)
            if item is None:
                continue

            if item.attestation_period_id != commission.attestation_period_id:
                continue

            item.commission_id = commission.id
            if item.is_admitted:
                item.status = "ready_for_commission"
            updated_count += 1

        self.session.commit()
        return {"updated_count": updated_count}