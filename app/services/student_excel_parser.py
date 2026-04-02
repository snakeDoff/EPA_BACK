from __future__ import annotations

from pathlib import Path
from typing import Any

import pandas as pd


REQUIRED_COLUMNS = {
    "Фамилия": "last_name",
    "Имя": "first_name",
    "Отчество": "middle_name",
    "Набор": "admission_year",
    "Курс": "course",
    "Вид места": "funding_type",
    "Образовательная программа": "education_program_raw",
    "Научная специальность": "specialty",
    "Академический статус": "academic_status",
    "Подразделение": "department_name",
    "Научный руководитель": "supervisor_name_raw",
    "Тема диссертации": "dissertation_topic",
    "Причина изменения состояния": "status_change_reason",
}


def _clean_str(value: Any) -> str | None:
    if pd.isna(value):
        return None
    value = str(value).strip()
    return value or None


def _clean_int(value: Any) -> int | None:
    if pd.isna(value):
        return None
    try:
        if isinstance(value, str):
            value = value.strip().replace(",", ".")
        return int(float(value))
    except (TypeError, ValueError):
        return None


def _clean_course(value: Any) -> int | None:
    if pd.isna(value):
        return None

    if isinstance(value, (int, float)):
        return int(value)

    value_str = str(value).strip().lower()

    # "Курс 1" -> 1
    if "курс" in value_str:
        digits = "".join(ch for ch in value_str if ch.isdigit())
        if digits:
            return int(digits)

    return _clean_int(value)


def _is_effectively_empty(mapped: dict[str, Any]) -> bool:
    return not any(
        mapped.get(key)
        for key in (
            "last_name",
            "first_name",
            "middle_name",
            "admission_year",
            "course",
            "education_program_raw",
            "department_name",
        )
    )


def parse_students_excel(file_path: str | Path, sheet_name: str) -> dict[str, list[dict[str, Any]]]:
    # В этом файле заголовки находятся на 6-й строке Excel
    df = pd.read_excel(file_path, sheet_name=sheet_name, header=5)
    df.columns = [str(col).strip() for col in df.columns]

    missing = [column for column in REQUIRED_COLUMNS if column not in df.columns]
    if missing:
        raise ValueError(f"Отсутствуют обязательные колонки: {missing}")

    students: list[dict[str, Any]] = []
    errors: list[dict[str, Any]] = []

    for index, row in df.iterrows():
        try:
            mapped: dict[str, Any] = {}

            for source_column, target_field in REQUIRED_COLUMNS.items():
                raw_value = row.get(source_column)

                if target_field == "admission_year":
                    mapped[target_field] = _clean_int(raw_value)
                elif target_field == "course":
                    mapped[target_field] = _clean_course(raw_value)
                else:
                    mapped[target_field] = _clean_str(raw_value)

            # пропускаем пустые строки после заголовка
            if _is_effectively_empty(mapped):
                continue

            if not mapped["last_name"]:
                raise ValueError("Не указана фамилия")
            if not mapped["first_name"]:
                raise ValueError("Не указано имя")
            if not mapped["course"]:
                raise ValueError("Не указан курс")
            if not mapped["education_program_raw"]:
                raise ValueError("Не указана образовательная программа")
            if not mapped["academic_status"]:
                raise ValueError("Не указан академический статус")
            if not mapped["department_name"]:
                raise ValueError("Не указано подразделение")

            mapped["email"] = None

            students.append(mapped)

        except Exception as exc:
            errors.append(
                {
                    "row_index": int(index),
                    "error": str(exc),
                }
            )

    return {
        "students": students,
        "errors": errors,
    }