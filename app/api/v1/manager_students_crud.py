from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.schemas.manager_student import (
    ManagerStudentRead,
    ManagerStudentRow,
    ManagerStudentUpdatePayload,
)
from app.services.manager_student_service import ManagerStudentService

router = APIRouter(
    prefix="/manager/students",
    tags=["manager-students-crud"],
)


@router.get("", response_model=list[ManagerStudentRow])
def list_students(
    db: Session = Depends(get_db),
) -> list[ManagerStudentRow]:
    service = ManagerStudentService(db)
    items = service.list_students()
    return [ManagerStudentRow(**service.to_row(item)) for item in items]


@router.get("/{student_id}", response_model=ManagerStudentRead)
def get_student(
    student_id: UUID,
    db: Session = Depends(get_db),
) -> ManagerStudentRead:
    service = ManagerStudentService(db)
    item = service.get_student(student_id)

    if item is None:
        raise HTTPException(status_code=404, detail="Student not found")

    return ManagerStudentRead(**service.to_row(item))


@router.patch("/{student_id}", response_model=ManagerStudentRead)
def update_student(
    student_id: UUID,
    payload: ManagerStudentUpdatePayload,
    db: Session = Depends(get_db),
) -> ManagerStudentRead:
    service = ManagerStudentService(db)
    item = service.get_student(student_id)

    if item is None:
        raise HTTPException(status_code=404, detail="Student not found")

    updated = service.update_student(item, payload)
    return ManagerStudentRead(**service.to_row(updated))