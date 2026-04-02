from __future__ import annotations

from copy import deepcopy
from typing import Any

from app.utils.fio import normalize_fio


def build_student_fio(row: dict[str, Any]) -> str:
    parts = [
        row.get("last_name"),
        row.get("first_name"),
        row.get("middle_name"),
    ]
    fio = " ".join(part for part in parts if part)
    return normalize_fio(fio)


def merge_students_with_emails(
    students: list[dict[str, Any]],
    fio_to_emails: dict[str, list[str]],
) -> dict[str, Any]:
    merged_students: list[dict[str, Any]] = []
    errors: list[dict[str, Any]] = []

    for row in students:
        row_copy = deepcopy(row)
        fio = build_student_fio(row_copy)

        emails = fio_to_emails.get(fio, [])

        if len(emails) == 1:
            row_copy["email"] = emails[0]
        elif len(emails) > 1:
            row_copy["email"] = None
            errors.append(
                {
                    "fio": fio,
                    "error": "Для одного ФИО найдено несколько email",
                    "emails": emails,
                }
            )
        else:
            row_copy["email"] = None

        merged_students.append(row_copy)

    return {
        "students": merged_students,
        "errors": errors,
    }