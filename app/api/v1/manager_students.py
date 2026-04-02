from __future__ import annotations

import tempfile
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.api.dependencies import get_db
from app.schemas.student_import import StudentImportRow
from app.services.student_email_docx_parser import parse_student_emails_docx
from app.services.student_email_merge import merge_students_with_emails
from app.services.student_excel_parser import parse_students_excel
from app.services.student_import_service import StudentImportService

router = APIRouter(prefix="/manager/students", tags=["manager-students"])


@router.post("/import")
async def import_students(
    students_file: UploadFile = File(...),
    emails_file: UploadFile = File(...),
    db: Session = Depends(get_db),
) -> dict:
    if not students_file.filename or not students_file.filename.lower().endswith(".xlsx"):
        raise HTTPException(status_code=400, detail="Файл со студентами должен быть в формате .xlsx")

    if not emails_file.filename or not emails_file.filename.lower().endswith(".docx"):
        raise HTTPException(status_code=400, detail="Файл с почтами должен быть в формате .docx")

    students_tmp_path: Path | None = None
    emails_tmp_path: Path | None = None

    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".xlsx") as tmp_students:
            tmp_students.write(await students_file.read())
            students_tmp_path = Path(tmp_students.name)

        with tempfile.NamedTemporaryFile(delete=False, suffix=".docx") as tmp_emails:
            tmp_emails.write(await emails_file.read())
            emails_tmp_path = Path(tmp_emails.name)

        students_data = parse_students_excel(
            file_path=students_tmp_path,
            sheet_name="Весь список",
        )

        emails_data = parse_student_emails_docx(
            file_path=emails_tmp_path,
        )

        merged_data = merge_students_with_emails(
            students=students_data["students"],
            fio_to_emails=emails_data["fio_to_emails"],
        )

        parser_errors = (
            students_data["errors"]
            + emails_data["errors"]
            + merged_data["errors"]
        )

        rows = [StudentImportRow(**row) for row in merged_data["students"]]

        service = StudentImportService(db)
        stats = service.import_rows(rows)

        return {
            "total_rows": stats.total,
            "created_students": stats.created,
            "updated_students": stats.updated,
            "created_users": stats.created_users,
            "parser_errors": parser_errors,
        }

    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    finally:
        if students_tmp_path is not None:
            students_tmp_path.unlink(missing_ok=True)
        if emails_tmp_path is not None:
            emails_tmp_path.unlink(missing_ok=True)