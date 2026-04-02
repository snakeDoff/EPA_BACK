from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.schemas.staff_member import (
    StaffMemberCreate,
    StaffMemberRead,
    StaffMemberUpdate,
)
from app.services.staff_member_service import StaffMemberService

router = APIRouter(
    prefix="/expert/staff-members",
    tags=["expert-staff-members"],
)


@router.get("", response_model=list[StaffMemberRead])
def list_staff_members(
    only_available_for_commissions: bool = Query(default=False),
    db: Session = Depends(get_db),
) -> list[StaffMemberRead]:
    service = StaffMemberService(db)

    if only_available_for_commissions:
        items = service.list_available_for_commissions()
    else:
        items = service.list_staff_members()

    return [StaffMemberRead.model_validate(item) for item in items]


@router.get("/{staff_member_id}", response_model=StaffMemberRead)
def get_staff_member(
    staff_member_id: UUID,
    db: Session = Depends(get_db),
) -> StaffMemberRead:
    service = StaffMemberService(db)
    item = service.get_staff_member(staff_member_id)

    if item is None:
        raise HTTPException(status_code=404, detail="Staff member not found")

    return StaffMemberRead.model_validate(item)


@router.post("", response_model=StaffMemberRead, status_code=201)
def create_staff_member(
    payload: StaffMemberCreate,
    db: Session = Depends(get_db),
) -> StaffMemberRead:
    service = StaffMemberService(db)
    item = service.create_staff_member(payload)
    return StaffMemberRead.model_validate(item)


@router.patch("/{staff_member_id}", response_model=StaffMemberRead)
def update_staff_member(
    staff_member_id: UUID,
    payload: StaffMemberUpdate,
    db: Session = Depends(get_db),
) -> StaffMemberRead:
    service = StaffMemberService(db)
    item = service.get_staff_member(staff_member_id)

    if item is None:
        raise HTTPException(status_code=404, detail="Staff member not found")

    updated = service.update_staff_member(item=item, payload=payload)
    return StaffMemberRead.model_validate(updated)


@router.delete("/{staff_member_id}", response_model=StaffMemberRead)
def delete_staff_member(
    staff_member_id: UUID,
    db: Session = Depends(get_db),
) -> StaffMemberRead:
    service = StaffMemberService(db)
    item = service.get_staff_member(staff_member_id)

    if item is None:
        raise HTTPException(status_code=404, detail="Staff member not found")

    updated = service.deactivate_staff_member(item)
    return StaffMemberRead.model_validate(updated)