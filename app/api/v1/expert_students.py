from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.db.models import StaffMember
from app.schemas.student_attestation import ManagerStudentAttestationTableRow
from app.services.expert_student_service import ExpertStudentService

router = APIRouter(
    prefix="/expert/students",
    tags=["expert-students"],
)


def get_current_expert_department_id(
    db: Session = Depends(get_db),
    x_user_id: str | None = Header(default=None),
) -> UUID:
    if x_user_id is None:
        raise HTTPException(
            status_code=400,
            detail="X-User-Id header is required until expert auth is implemented",
        )

    try:
        user_id = UUID(x_user_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid X-User-Id header") from exc

    stmt = (
        select(StaffMember)
        .where(StaffMember.user_id == user_id)
        .where(StaffMember.is_active.is_(True))
    )
    staff_member = db.scalar(stmt)

    if staff_member is None:
        raise HTTPException(
            status_code=404,
            detail="Active staff member for current expert was not found",
        )

    if staff_member.department_id is None:
        raise HTTPException(
            status_code=400,
            detail="Expert staff member does not have a department assigned",
        )

    return staff_member.department_id


@router.get("", response_model=list[ManagerStudentAttestationTableRow])
def list_expert_students(
    department_id: UUID = Depends(get_current_expert_department_id),
    db: Session = Depends(get_db),
) -> list[ManagerStudentAttestationTableRow]:
    service = ExpertStudentService(db)
    rows = service.list_students_by_department(department_id)
    return [ManagerStudentAttestationTableRow(**row) for row in rows]