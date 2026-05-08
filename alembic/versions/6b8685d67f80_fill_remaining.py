"""fill remaining criterion groups

Revision ID: 0016_fill_remaining_criterion_groups
Revises: 0015_fill_criterion_groups
Create Date: 2026-05-04
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


revision: str = "0016_fill_remaining"
down_revision: Union[str, None] = "0015_fill_criterion_groups"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


LOGIC_CODE = "logic_hypothesis"
LOGIC_NAME = "Логика и гипотеза"
LOGIC_ORDER = 1

METHODS_CODE = "methods"
METHODS_NAME = "Методы"
METHODS_ORDER = 2

SCIENTIFIC_CODE = "scientific_foundation"
SCIENTIFIC_NAME = "Научный задел"
SCIENTIFIC_ORDER = 3

TEXT_CODE = "text_progress"
TEXT_NAME = "Прогресс текста"
TEXT_ORDER = 4


def _fill_table(table_name: str) -> None:
    op.execute(
        sa.text(
            f"""
            UPDATE {table_name}
            SET
                group_code = :methods_code,
                group_name = :methods_name,
                group_sort_order = :methods_order
            WHERE
                group_code IS NULL
                AND (
                    lower(trim(name)) LIKE '%методология и методы%'
                    OR lower(trim(name)) LIKE '%методы исследования%'
                );
            """
        ).bindparams(
            methods_code=METHODS_CODE,
            methods_name=METHODS_NAME,
            methods_order=METHODS_ORDER,
        )
    )

    op.execute(
        sa.text(
            f"""
            UPDATE {table_name}
            SET
                group_code = :logic_code,
                group_name = :logic_name,
                group_sort_order = :logic_order
            WHERE
                group_code IS NULL
                AND (
                    lower(trim(name)) LIKE '%введение в диссертационное исследование%'
                    OR lower(trim(name)) LIKE '%структура исследования%'
                    OR lower(trim(name)) LIKE '%research proposal%'
                    OR lower(trim(name)) LIKE '%актуальность исследования%'
                    OR lower(trim(name)) LIKE '%научная гипотеза%'
                    OR lower(trim(name)) LIKE '%степень разработанности%'
                    OR lower(trim(name)) LIKE '%постановка научной задачи%'
                    OR lower(trim(name)) LIKE '%цель исследования%'
                    OR lower(trim(name)) LIKE '%задачи исследования%'
                    OR lower(trim(name)) LIKE '%объект исследования%'
                    OR lower(trim(name)) LIKE '%предмет исследования%'
                    OR lower(trim(name)) LIKE '%соответствие паспорту%'
                    OR lower(trim(name)) LIKE '%положения, выносимые на защиту%'
                );
            """
        ).bindparams(
            logic_code=LOGIC_CODE,
            logic_name=LOGIC_NAME,
            logic_order=LOGIC_ORDER,
        )
    )

    op.execute(
        sa.text(
            f"""
            UPDATE {table_name}
            SET
                group_code = :scientific_code,
                group_name = :scientific_name,
                group_sort_order = :scientific_order
            WHERE
                group_code IS NULL
                AND (
                    lower(trim(name)) LIKE '%планируемая научная ценность%'
                    OR lower(trim(name)) LIKE '%планируемая научная новизна%'
                    OR lower(trim(name)) LIKE '%основные полученные научные результаты%'
                    OR lower(trim(name)) LIKE '%прогресс по результатам диссертации%'
                    OR lower(trim(name)) LIKE '%научная новизна%'
                    OR lower(trim(name)) LIKE '%практическая ценность%'
                    OR lower(trim(name)) LIKE '%практическая и теоретическая значимости%'
                    OR lower(trim(name)) LIKE '%научно-педагогическая практика%'
                    OR lower(trim(name)) LIKE '%научно-педагогичексая практика%'
                    OR lower(trim(name)) LIKE '%научно-исследовательская практика%'
                    OR lower(trim(name)) LIKE '%научные публикации%'
                    OR lower(trim(name)) LIKE '%публикация с аффилиацией%'
                    OR lower(trim(name)) LIKE '%научный доклад%'
                    OR lower(trim(name)) LIKE '%научные семинары%'
                    OR lower(trim(name)) LIKE '%конференции%'
                    OR lower(trim(name)) LIKE '%симпозиумы%'
                    OR lower(trim(name)) LIKE '%акты внедрения%'
                    OR lower(trim(name)) LIKE '%акт внедрения%'
                );
            """
        ).bindparams(
            scientific_code=SCIENTIFIC_CODE,
            scientific_name=SCIENTIFIC_NAME,
            scientific_order=SCIENTIFIC_ORDER,
        )
    )

    op.execute(
        sa.text(
            f"""
            UPDATE {table_name}
            SET
                group_code = :text_code,
                group_name = :text_name,
                group_sort_order = :text_order
            WHERE
                group_code IS NULL
                AND (
                    lower(trim(name)) LIKE '%готовность текста диссертации%'
                    OR lower(trim(name)) LIKE '%дата предзащиты%'
                    OR lower(trim(name)) LIKE '%даты предзащиты%'
                    OR lower(trim(name)) LIKE '%содержание автореферата%'
                    OR lower(trim(name)) LIKE '%заключение организации%'
                );
            """
        ).bindparams(
            text_code=TEXT_CODE,
            text_name=TEXT_NAME,
            text_order=TEXT_ORDER,
        )
    )

    op.execute(
        sa.text(
            f"""
            UPDATE {table_name}
            SET count_norm = 1
            WHERE evaluation_type = 'count'
              AND count_norm IS NULL;
            """
        )
    )


def upgrade() -> None:
    _fill_table("attestation_criteria")
    _fill_table("student_attestation_criteria")


def downgrade() -> None:
    op.execute(
        """
        UPDATE attestation_criteria
        SET
            group_code = NULL,
            group_name = NULL,
            group_sort_order = NULL,
            count_norm = NULL
        WHERE group_code IN (
            'logic_hypothesis',
            'methods',
            'scientific_foundation',
            'text_progress'
        );
        """
    )

    op.execute(
        """
        UPDATE student_attestation_criteria
        SET
            group_code = NULL,
            group_name = NULL,
            group_sort_order = NULL,
            count_norm = NULL
        WHERE group_code IN (
            'logic_hypothesis',
            'methods',
            'scientific_foundation',
            'text_progress'
        );
        """
    )