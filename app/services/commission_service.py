from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db.models import (
    AttestationCommission,
    CommissionMember,
    StaffMember,
    Student,
    StudentAttestation,
)
from app.schemas.commission import (
    AssignStudentAttestationsToCommissionPayload,
    AttestationCommissionCreate,
    AttestationCommissionUpdate,
    CommissionMemberCreate,
    CommissionMemberUpdate,
)


class CommissionService:
    def __init__(self, session: Session) -> None:
        self.session = session

    def list_commissions(self, period_id, created_by):
        stmt = (
            select(AttestationCommission)
            .options(
                selectinload(AttestationCommission.members).selectinload(CommissionMember.staff_member)
            )
            .where(AttestationCommission.attestation_period_id == period_id)
            .where(AttestationCommission.created_by == created_by)
            .order_by(AttestationCommission.created_at.desc())
        )
        return list(self.session.scalars(stmt).unique().all())

    def get_commission(self, commission_id, created_by=None):
        stmt = (
            select(AttestationCommission)
            .options(
                selectinload(AttestationCommission.members).selectinload(CommissionMember.staff_member)
            )
            .where(AttestationCommission.id == commission_id)
        )

        if created_by is not None:
            stmt = stmt.where(AttestationCommission.created_by == created_by)

        return self.session.scalar(stmt)

    def create_commission(
        self,
        period_id,
        department_id,
        payload: AttestationCommissionCreate,
        created_by=None,
    ):
        commission = AttestationCommission(
            attestation_period_id=period_id,
            department_id=department_id,
            name=payload.name,
            status=payload.status,
            notes=payload.notes,
            meeting_date=payload.meeting_date,
            start_time=payload.start_time,
            end_time=payload.end_time,
            meeting_location=payload.meeting_location,
            created_by=created_by,
        )
        self.session.add(commission)
        self.session.flush()

        for item in payload.members:
            self._validate_staff_member(item.staff_member_id)

            self.session.add(
                CommissionMember(
                    commission_id=commission.id,
                    staff_member_id=item.staff_member_id,
                    role_in_commission=item.role_in_commission,
                    membership_type=item.membership_type,
                    participation_note=item.participation_note,
                    is_voting_member=item.is_voting_member,
                    sort_order=item.sort_order,
                )
            )

        self.session.commit()
        return self.get_commission(commission.id, created_by=created_by)

    def update_commission(self, commission_id, payload: AttestationCommissionUpdate, created_by):
        commission = self.get_commission(commission_id, created_by=created_by)
        if commission is None:
            raise ValueError("Commission not found")

        if commission.status == "confirmed":
            raise ValueError("Confirmed commission cannot be edited")

        update_data = payload.model_dump(exclude_unset=True)

        # department_id из payload игнорируем: он должен идти от эксперта
        update_data.pop("department_id", None)

        for field, value in update_data.items():
            setattr(commission, field, value)

        self.session.commit()
        return self.get_commission(commission.id, created_by=created_by)

    def confirm_commission(self, commission_id, created_by):
        commission = self.get_commission(commission_id, created_by=created_by)
        if commission is None:
            raise ValueError("Commission not found")

        if not commission.members:
            raise ValueError("Commission must contain at least one member")

        chair_count = sum(1 for member in commission.members if member.role_in_commission == "chair")
        if chair_count == 0:
            raise ValueError("Commission must have a chair")

        if commission.meeting_date is None:
            raise ValueError("Commission meeting_date is required before confirmation")

        if commission.start_time is None or commission.end_time is None:
            raise ValueError("Commission start_time and end_time are required before confirmation")

        if commission.meeting_location is None:
            raise ValueError("Commission meeting_location is required before confirmation")

        commission.status = "confirmed"
        self.session.commit()
        self.session.refresh(commission)
        return commission

    def assign_student_attestations_to_commission(
        self,
        commission_id,
        payload: AssignStudentAttestationsToCommissionPayload,
        created_by,
    ) -> dict:
        commission = self.get_commission(commission_id, created_by=created_by)
        if commission is None:
            raise ValueError("Commission not found")

        if commission.status == "confirmed":
            raise ValueError("Confirmed commission cannot be changed")

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

    def list_commission_student_attestations(self, commission_id, created_by):
        commission = self.get_commission(commission_id, created_by=created_by)
        if commission is None:
            raise ValueError("Commission not found")

        stmt = (
            select(StudentAttestation)
            .options(
                selectinload(StudentAttestation.student).selectinload(Student.education_program),
                selectinload(StudentAttestation.department),
                selectinload(StudentAttestation.supervisor),
                selectinload(StudentAttestation.criteria),
                selectinload(StudentAttestation.member_evaluations),
            )
            .where(StudentAttestation.commission_id == commission_id)
            .order_by(StudentAttestation.student_id)
        )
        return list(self.session.scalars(stmt).unique().all())

    def add_commission_member(self, commission_id, payload: CommissionMemberCreate, created_by):
        commission = self.get_commission(commission_id, created_by=created_by)
        if commission is None:
            raise ValueError("Commission not found")

        if commission.status == "confirmed":
            raise ValueError("Confirmed commission cannot be edited")

        self._validate_staff_member(payload.staff_member_id)

        existing = self.session.scalar(
            select(CommissionMember).where(
                CommissionMember.commission_id == commission_id,
                CommissionMember.staff_member_id == payload.staff_member_id,
            )
        )
        if existing is not None:
            raise ValueError("Staff member is already included in commission")

        member = CommissionMember(
            commission_id=commission_id,
            staff_member_id=payload.staff_member_id,
            role_in_commission=payload.role_in_commission,
            membership_type=payload.membership_type,
            participation_note=payload.participation_note,
            is_voting_member=payload.is_voting_member,
            sort_order=payload.sort_order,
        )
        self.session.add(member)
        self.session.commit()
        self.session.refresh(member)
        return member

    def update_commission_member(self, member_id, payload: CommissionMemberUpdate, created_by):
        member = self.session.get(CommissionMember, member_id)
        if member is None:
            raise ValueError("Commission member not found")

        commission = self.get_commission(member.commission_id, created_by=created_by)
        if commission is None:
            raise ValueError("Commission not found")

        if commission.status == "confirmed":
            raise ValueError("Confirmed commission cannot be edited")

        update_data = payload.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(member, field, value)

        self.session.commit()
        self.session.refresh(member)
        return member

    def delete_commission_member(self, member_id, created_by):
        member = self.session.get(CommissionMember, member_id)
        if member is None:
            raise ValueError("Commission member not found")

        commission = self.get_commission(member.commission_id, created_by=created_by)
        if commission is None:
            raise ValueError("Commission not found")

        if commission.status == "confirmed":
            raise ValueError("Confirmed commission cannot be edited")

        self.session.delete(member)
        self.session.commit()

    def _validate_staff_member(self, staff_member_id):
        staff_member = self.session.get(StaffMember, staff_member_id)
        if staff_member is None:
            raise ValueError(f"Staff member not found: {staff_member_id}")
        if not staff_member.is_active or not staff_member.can_be_commission_member:
            raise ValueError(f"Staff member cannot be included in commission: {staff_member_id}")
        
    def list_all_commissions_for_director(self, period_id):
        stmt = (
            select(AttestationCommission)
            .options(
                selectinload(AttestationCommission.members).selectinload(CommissionMember.staff_member)
            )
            .where(AttestationCommission.attestation_period_id == period_id)
            .order_by(
                AttestationCommission.meeting_date.asc().nulls_last(),
                AttestationCommission.start_time.asc().nulls_last(),
                AttestationCommission.created_at.desc(),
            )
        )
        return list(self.session.scalars(stmt).unique().all())