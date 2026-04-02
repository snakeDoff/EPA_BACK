from __future__ import annotations

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import StaffMember
from app.schemas.staff_member import StaffMemberCreate, StaffMemberUpdate


class StaffMemberService:
    def __init__(self, session: Session) -> None:
        self.session = session

    def list_staff_members(self) -> list[StaffMember]:
        stmt = select(StaffMember).order_by(
            StaffMember.last_name,
            StaffMember.first_name,
            StaffMember.middle_name,
        )
        return list(self.session.scalars(stmt).all())

    def list_available_for_commissions(self) -> list[StaffMember]:
        stmt = (
            select(StaffMember)
            .where(StaffMember.is_active.is_(True))
            .where(StaffMember.can_be_commission_member.is_(True))
            .order_by(
                StaffMember.last_name,
                StaffMember.first_name,
                StaffMember.middle_name,
            )
        )
        return list(self.session.scalars(stmt).all())

    def get_staff_member(self, staff_member_id: UUID) -> StaffMember | None:
        return self.session.get(StaffMember, staff_member_id)

    def create_staff_member(self, payload: StaffMemberCreate) -> StaffMember:
        item = StaffMember(
            user_id=payload.user_id,
            department_id=payload.department_id,
            last_name=payload.last_name,
            first_name=payload.first_name,
            middle_name=payload.middle_name,
            position_title=payload.position_title,
            academic_degree=payload.academic_degree,
            academic_title=payload.academic_title,
            regalia_text=payload.regalia_text,
            email=str(payload.email) if payload.email else None,
            phone=payload.phone,
            is_active=payload.is_active,
            can_be_commission_member=payload.can_be_commission_member,
        )
        self.session.add(item)
        self.session.commit()
        self.session.refresh(item)
        return item

    def update_staff_member(
        self,
        item: StaffMember,
        payload: StaffMemberUpdate,
    ) -> StaffMember:
        update_data = payload.model_dump(exclude_unset=True)

        if "email" in update_data:
            value = update_data["email"]
            update_data["email"] = str(value) if value else None

        for field, value in update_data.items():
            setattr(item, field, value)

        self.session.commit()
        self.session.refresh(item)
        return item

    def deactivate_staff_member(self, item: StaffMember) -> StaffMember:
        item.is_active = False
        item.can_be_commission_member = False
        self.session.commit()
        self.session.refresh(item)
        return item