from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr, field_validator


class StaffMemberBase(BaseModel):
    user_id: UUID | None = None
    department_id: UUID | None = None

    last_name: str
    first_name: str
    middle_name: str | None = None

    position_title: str | None = None
    academic_degree: str | None = None
    academic_title: str | None = None
    regalia_text: str | None = None

    email: EmailStr | None = None
    phone: str | None = None

    is_active: bool = True
    can_be_commission_member: bool = True

    @field_validator(
        "last_name",
        "first_name",
        "middle_name",
        "position_title",
        "academic_degree",
        "academic_title",
        "regalia_text",
        "phone",
        mode="before",
    )
    @classmethod
    def strip_strings(cls, value: object) -> object:
        if value is None:
            return None
        if isinstance(value, str):
            value = value.strip()
            return value or None
        return value


class StaffMemberCreate(StaffMemberBase):
    pass


class StaffMemberUpdate(BaseModel):
    user_id: UUID | None = None
    department_id: UUID | None = None

    last_name: str | None = None
    first_name: str | None = None
    middle_name: str | None = None

    position_title: str | None = None
    academic_degree: str | None = None
    academic_title: str | None = None
    regalia_text: str | None = None

    email: EmailStr | None = None
    phone: str | None = None

    is_active: bool | None = None
    can_be_commission_member: bool | None = None

    @field_validator(
        "last_name",
        "first_name",
        "middle_name",
        "position_title",
        "academic_degree",
        "academic_title",
        "regalia_text",
        "phone",
        mode="before",
    )
    @classmethod
    def strip_strings(cls, value: object) -> object:
        if value is None:
            return None
        if isinstance(value, str):
            value = value.strip()
            return value or None
        return value


class StaffMemberRead(BaseModel):
    id: UUID
    user_id: UUID | None
    department_id: UUID | None

    last_name: str
    first_name: str
    middle_name: str | None

    position_title: str | None
    academic_degree: str | None
    academic_title: str | None
    regalia_text: str | None

    email: EmailStr | None
    phone: str | None

    is_active: bool
    can_be_commission_member: bool

    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}