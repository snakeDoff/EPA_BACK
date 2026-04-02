from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, ForeignKey, Index, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPKMixin

if TYPE_CHECKING:
    from app.db.models.attestation_commission import CommissionMember
    from app.db.models.department import Department
    from app.db.models.user import User


class StaffMember(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "staff_members"
    __table_args__ = (
        Index("ix_staff_members_user_id", "user_id"),
        Index("ix_staff_members_department_id", "department_id"),
        Index("ix_staff_members_is_active", "is_active"),
        Index("ix_staff_members_can_be_commission_member", "can_be_commission_member"),
    )

    user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        unique=True,
    )

    department_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("departments.id", ondelete="SET NULL"),
        nullable=True,
    )

    last_name: Mapped[str] = mapped_column(String(100), nullable=False)
    first_name: Mapped[str] = mapped_column(String(100), nullable=False)
    middle_name: Mapped[str | None] = mapped_column(String(100), nullable=True)

    position_title: Mapped[str | None] = mapped_column(String(255), nullable=True)
    academic_degree: Mapped[str | None] = mapped_column(String(255), nullable=True)
    academic_title: Mapped[str | None] = mapped_column(String(255), nullable=True)
    regalia_text: Mapped[str | None] = mapped_column(Text, nullable=True)

    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(50), nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    can_be_commission_member: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
    )

    user: Mapped["User | None"] = relationship()
    department: Mapped["Department | None"] = relationship()
    commission_memberships: Mapped[list["CommissionMember"]] = relationship(
        back_populates="staff_member"
    )