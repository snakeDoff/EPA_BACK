from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db.models import Department, EducationProgram, Role, Student, User, UserRole
from app.schemas.student_import import StudentImportRow


@dataclass
class StudentImportStats:
    total: int = 0
    created: int = 0
    updated: int = 0
    created_users: int = 0


class StudentImportService:
    def __init__(self, session: Session) -> None:
        self.session = session

    def import_rows(self, rows: Iterable[StudentImportRow]) -> StudentImportStats:
        stats = StudentImportStats()
        student_role = self._get_student_role()

        for row in rows:
            stats.total += 1

            department = self._get_or_create_department(row.department_name)
            education_program = self._get_education_program(row.education_program_raw)

            student = self._find_existing_student(
                row=row,
                department_id=department.id,
            )

            if student is None:
                student = self._create_student(
                    row=row,
                    department_id=department.id,
                    education_program_id=education_program.id,
                )
                stats.created += 1
            else:
                self._update_student(
                    student=student,
                    row=row,
                    department_id=department.id,
                    education_program_id=education_program.id,
                )
                stats.updated += 1

            if row.email:
                created_user = self._ensure_user_for_student(
                    student=student,
                    row=row,
                    student_role=student_role,
                )
                if created_user:
                    stats.created_users += 1

        self.session.commit()
        return stats

    def _get_student_role(self) -> Role:
        stmt = select(Role).where(Role.code == "student")
        role = self.session.scalar(stmt)
        if role is None:
            raise ValueError("Role 'student' not found")
        return role

    def _get_or_create_department(self, name: str) -> Department:
        normalized = name.strip()
        stmt = select(Department).where(func.lower(Department.name) == normalized.lower())
        department = self.session.scalar(stmt)

        if department is None:
            department = Department(
                name=normalized,
                short_name=None,
                is_active=True,
            )
            self.session.add(department)
            self.session.flush()

        return department

    def _get_education_program(self, raw_name: str) -> EducationProgram:
        normalized = raw_name.strip()
        stmt = select(EducationProgram).where(
            func.lower(EducationProgram.name) == normalized.lower()
        )
        program = self.session.scalar(stmt)

        if program is None:
            raise ValueError(f"Education program not found: {raw_name}")

        return program

    def _find_existing_student(
        self,
        row: StudentImportRow,
        department_id,
    ) -> Student | None:
        if row.email:
            stmt = select(Student).where(func.lower(Student.email) == row.email.lower())
            student = self.session.scalar(stmt)
            if student:
                return student

        stmt = (
            select(Student)
            .where(Student.last_name == row.last_name)
            .where(Student.first_name == row.first_name)
            .where(Student.middle_name == row.middle_name)
            .where(Student.admission_year == row.admission_year)
            .where(Student.department_id == department_id)
        )
        return self.session.scalar(stmt)

    def _create_student(
        self,
        row: StudentImportRow,
        department_id,
        education_program_id,
    ) -> Student:
        student = Student(
            last_name=row.last_name,
            first_name=row.first_name,
            middle_name=row.middle_name,
            email=str(row.email) if row.email else None,
            admission_year=row.admission_year,
            course=row.course,
            funding_type=row.funding_type,
            education_program_id=education_program_id,
            education_program_raw=row.education_program_raw,
            specialty=row.specialty,
            academic_status=row.academic_status,
            department_id=department_id,
            supervisor_name_raw=row.supervisor_name_raw,
            dissertation_topic=row.dissertation_topic,
            status_change_reason=row.status_change_reason,
            is_active=True,
        )
        self.session.add(student)
        self.session.flush()
        return student

    def _update_student(
        self,
        student: Student,
        row: StudentImportRow,
        department_id,
        education_program_id,
    ) -> None:
        student.last_name = row.last_name
        student.first_name = row.first_name
        student.middle_name = row.middle_name
        student.email = str(row.email) if row.email else None
        student.admission_year = row.admission_year
        student.course = row.course
        student.funding_type = row.funding_type
        student.education_program_id = education_program_id
        student.education_program_raw = row.education_program_raw
        student.specialty = row.specialty
        student.academic_status = row.academic_status
        student.department_id = department_id
        student.supervisor_name_raw = row.supervisor_name_raw
        student.dissertation_topic = row.dissertation_topic
        student.status_change_reason = row.status_change_reason
        student.is_active = True

    def _ensure_user_for_student(
        self,
        student: Student,
        row: StudentImportRow,
        student_role: Role,
    ) -> bool:
        email = str(row.email)
        created = False

        if student.user_id is None:
            stmt = select(User).where(func.lower(User.email) == email.lower())
            user = self.session.scalar(stmt)

            if user is None:
                user = User(
                    email=email,
                    password_hash=None,
                    last_name=row.last_name,
                    first_name=row.first_name,
                    middle_name=row.middle_name,
                    is_active=True,
                    is_deleted=False,
                )
                self.session.add(user)
                self.session.flush()
                created = True
            else:
                user.last_name = row.last_name
                user.first_name = row.first_name
                user.middle_name = row.middle_name
                user.is_active = True
                user.is_deleted = False

            student.user_id = user.id

            stmt = (
                select(UserRole)
                .where(UserRole.user_id == user.id)
                .where(UserRole.role_id == student_role.id)
                .where(UserRole.department_id.is_(None))
            )
            existing_role = self.session.scalar(stmt)

            if existing_role is None:
                self.session.add(
                    UserRole(
                        user_id=user.id,
                        role_id=student_role.id,
                        department_id=None,
                        is_active=True,
                    )
                )
        else:
            user = self.session.get(User, student.user_id)
            if user is not None:
                user.email = email
                user.last_name = row.last_name
                user.first_name = row.first_name
                user.middle_name = row.middle_name
                user.is_active = True
                user.is_deleted = False

        return created