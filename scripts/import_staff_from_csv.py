from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from sqlalchemy import select

from app.db.models import Department, Role, StaffMember, User, UserRole
from app.db.session import SessionLocal


ROLE_SPECS = [
    {"code": "expert", "name": "expert"},
    {"code": "commission_member", "name": "commission_member"},
    {"code": "scientific_supervisor", "name": "scientific_supervisor"},
]


def normalize_text(value: str | None) -> str:
    if not value:
        return ""
    return " ".join(
        value.replace("«", '"').replace("»", '"').replace(":", "").strip().split()
    )


DEPARTMENT_ALIASES = {
    normalize_text("Базовая кафедра «Прикладные информационно-коммуникационные средства и системы» ВЦ РАН"): normalize_text(
        'базовая кафедра "Прикладные информационно-коммуникационные средства и системы" (ПИКСиС) федерального государственного бюджетного учреждения науки Вычи'
    ),
    normalize_text("Базовая кафедра информационно-аналитических систем ЗАО «ЕС-лизинг»"): normalize_text(
        'базовая кафедра информационно-аналитических систем ЗАО "ЕС-лизинг"'
    ),
    normalize_text('Базовая кафедра квантовой оптики и телекоммуникаций ЗАО "Сконтел"'): normalize_text(
        'базовая кафедра квантовой оптики и телекоммуникаций ЗАО"Сконтел"'
    ),
    normalize_text('Базовая кафедра квантовой оптики и телекоммуникаций ЗАО «Сконтел»'): normalize_text(
        'базовая кафедра квантовой оптики и телекоммуникаций ЗАО"Сконтел"'
    ),
    normalize_text("Департамент компьютерной инженерии"): normalize_text(
        "департамент компьютерной инженерии"
    ),
    normalize_text("Департамент прикладной математики"): normalize_text(
        "департамент прикладной математики"
    ),
    normalize_text("Департамент электронной инженерии"): normalize_text(
        "департамент электронной инженерии"
    ),
    normalize_text("Департамент электронной инженерии:"): normalize_text(
        "департамент электронной инженерии"
    ),
    normalize_text("Кафедра информационной безопасности киберфизических систем"): normalize_text(
        "кафедра информационной безопасности киберфизических систем"
    ),
    normalize_text("Кафедра компьютерной безопасности"): normalize_text(
        "кафедра компьютерной безопасности"
    ),
    normalize_text("Международная лаборатория физики элементарных частиц"): normalize_text(
        "международная лаборатория физики элементарных частиц"
    ),
    normalize_text("Научно-учебная лаборатория телекоммуникационных систем"): normalize_text(
        "научно-учебная лаборатория телекоммуникационных систем"
    ),
}


def normalize_department_name(value: str | None) -> str:
    normalized = normalize_text(value)
    return DEPARTMENT_ALIASES.get(normalized, normalized)


def get_or_create_role(session, role_code: str, role_name: str) -> Role:
    role = session.scalar(select(Role).where(Role.code == role_code))
    if role is None:
        role = session.scalar(select(Role).where(Role.name == role_name))

    if role is None:
        role = Role(
            code=role_code,
            name=role_name,
            description=None,
            is_active=True,
        )
        session.add(role)
        session.flush()

    return role


def ensure_user_role(session, user_id, role_id) -> None:
    existing = session.scalar(
        select(UserRole).where(
            UserRole.user_id == user_id,
            UserRole.role_id == role_id,
        )
    )
    if existing is None:
        session.add(UserRole(user_id=user_id, role_id=role_id))


def build_department_map(session) -> dict[str, Department]:
    departments = session.scalars(select(Department)).all()
    result: dict[str, Department] = {}
    for department in departments:
        result[normalize_department_name(department.name)] = department
    return result


def make_placeholder_password_hash() -> str:
    return "TEMP_IMPORTED_NO_LOGIN"


def import_staff(csv_path: Path, dry_run: bool = False) -> None:
    session = SessionLocal()
    try:
        department_map = build_department_map(session)
        roles = {
            item["code"]: get_or_create_role(session, item["code"], item["name"])
            for item in ROLE_SPECS
        }

        created_users = 0
        updated_users = 0
        created_staff = 0
        updated_staff = 0
        skipped_no_email = 0
        skipped_empty = 0
        unknown_departments: set[str] = set()

        with csv_path.open("r", encoding="utf-8", newline="") as f:
            reader = csv.DictReader(f)

            for row in reader:
                last_name = (row.get("Фамилия") or "").strip()
                first_name = (row.get("Имя") or "").strip()
                middle_name = (row.get("Отчество") or "").strip() or None
                email = (row.get("email") or "").strip().lower() or None
                phone = (row.get("телефон") or "").strip() or None
                department_raw = (row.get("департамент") or "").strip() or None
                academic_degree = (row.get("уч.степень") or "").strip() or None
                academic_title = (row.get("уч.звание") or "").strip() or None
                position_title = (row.get("должность") or "").strip() or None

                if not last_name and not first_name and not email:
                    skipped_empty += 1
                    continue

                if not email:
                    skipped_no_email += 1
                    print(
                        f"SKIP no email: {last_name} {first_name} {middle_name or ''}".strip()
                    )
                    continue

                department = None
                if department_raw:
                    department = department_map.get(
                        normalize_department_name(department_raw)
                    )
                    if department is None:
                        unknown_departments.add(department_raw)

                user = session.scalar(select(User).where(User.email == email))
                if user is None:
                    user = User(
                        email=email,
                        password_hash=make_placeholder_password_hash(),
                        last_name=last_name,
                        first_name=first_name,
                        middle_name=middle_name,
                        is_active=True,
                        is_deleted=False,
                    )
                    session.add(user)
                    session.flush()
                    created_users += 1
                else:
                    user.last_name = last_name
                    user.first_name = first_name
                    user.middle_name = middle_name
                    if getattr(user, "is_deleted", False):
                        user.is_deleted = False
                    if not getattr(user, "is_active", True):
                        user.is_active = True
                    updated_users += 1

                for role in roles.values():
                    ensure_user_role(session, user.id, role.id)

                staff = session.scalar(select(StaffMember).where(StaffMember.user_id == user.id))
                if staff is None:
                    staff = StaffMember(
                        user_id=user.id,
                        department_id=department.id if department else None,
                        last_name=last_name,
                        first_name=first_name,
                        middle_name=middle_name,
                        position_title=position_title,
                        academic_degree=academic_degree,
                        academic_title=academic_title,
                        regalia_text=", ".join(
                            part
                            for part in [academic_degree, academic_title, position_title]
                            if part
                        )
                        or None,
                        email=email,
                        phone=phone,
                        is_active=True,
                        can_be_commission_member=True,
                    )
                    session.add(staff)
                    created_staff += 1
                else:
                    staff.department_id = department.id if department else staff.department_id
                    staff.last_name = last_name
                    staff.first_name = first_name
                    staff.middle_name = middle_name
                    staff.position_title = position_title
                    staff.academic_degree = academic_degree
                    staff.academic_title = academic_title
                    staff.regalia_text = (
                        ", ".join(
                            part
                            for part in [academic_degree, academic_title, position_title]
                            if part
                        )
                        or None
                    )
                    staff.email = email
                    staff.phone = phone
                    staff.is_active = True
                    staff.can_be_commission_member = True
                    updated_staff += 1

        if dry_run:
            session.rollback()
            print("DRY RUN completed, changes rolled back.")
        else:
            session.commit()
            print("Import completed.")

        print(f"created_users={created_users}")
        print(f"updated_users={updated_users}")
        print(f"created_staff={created_staff}")
        print(f"updated_staff={updated_staff}")
        print(f"skipped_no_email={skipped_no_email}")
        print(f"skipped_empty={skipped_empty}")

        if unknown_departments:
            print("Unknown departments:")
            for item in sorted(unknown_departments):
                print(f" - {item}")

    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("csv_path", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    import_staff(args.csv_path, dry_run=args.dry_run)


if __name__ == "__main__":
    main()