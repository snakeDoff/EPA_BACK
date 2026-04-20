from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db.models import Student
from app.schemas.manager_student import ManagerStudentUpdatePayload


class ManagerStudentService:
    def __init__(self, session: Session) -> None:
        self.session = session

    def list_students(self):
        stmt = (
            select(Student)
            .options(
                selectinload(Student.education_program),
                selectinload(Student.department),
                selectinload(Student.supervisor),
                selectinload(Student.user),
            )
            .order_by(Student.last_name, Student.first_name, Student.middle_name)
        )
        return list(self.session.scalars(stmt).all())

    def get_student(self, student_id):
        stmt = (
            select(Student)
            .options(
                selectinload(Student.education_program),
                selectinload(Student.department),
                selectinload(Student.supervisor),
                selectinload(Student.user),
            )
            .where(Student.id == student_id)
        )
        return self.session.scalar(stmt)

    def update_student(self, student: Student, payload: ManagerStudentUpdatePayload):
        update_data = payload.model_dump(exclude_unset=True)

        for field, value in update_data.items():
            setattr(student, field, value)

        self.session.commit()
        self.session.refresh(student)
        return self.get_student(student.id)

    @staticmethod
    def to_row(student: Student) -> dict:
        fio_parts = [student.last_name, student.first_name, student.middle_name]
        fio = " ".join(part for part in fio_parts if part)

        supervisor_name = None
        if student.supervisor is not None:
            supervisor_parts = [
                student.supervisor.last_name,
                student.supervisor.first_name,
                student.supervisor.middle_name,
            ]
            supervisor_name = " ".join(part for part in supervisor_parts if part)
        elif student.supervisor_name_raw:
            supervisor_name = student.supervisor_name_raw

        return {
            "student_id": student.id,
            "user_id": student.user_id,
            "admission_year": student.admission_year,
            "course": student.course,
            "fio": fio,
            "email": student.email,
            "funding_type": student.funding_type,
            "education_program_id": student.education_program_id,
            "education_program_name": student.education_program.name if student.education_program else None,
            "specialty": student.specialty,
            "academic_status": getattr(student, "academic_status", None),
            "department_id": student.department_id,
            "department_name": student.department.name if student.department else None,
            "supervisor_user_id": student.supervisor_user_id,
            "supervisor_name": supervisor_name,
            "supervisor_name_raw": student.supervisor_name_raw,
            "dissertation_topic": getattr(student, "dissertation_topic", None),
            "status_change_reason": getattr(student, "status_change_reason", None),
            "is_active": student.is_active,
            "created_at": student.created_at,
            "updated_at": student.updated_at,
        }