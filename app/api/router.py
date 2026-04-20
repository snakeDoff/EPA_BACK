from __future__ import annotations

from fastapi import APIRouter

from app.api.v1.academic_director_attestation_criteria import (
    router as academic_director_attestation_criteria_router,
)
from app.api.v1.academic_director_attestation_lifecycle import (
    router as academic_director_attestation_lifecycle_router,
)
from app.api.v1.academic_director_attestation_periods import (
    router as academic_director_attestation_periods_router,
)
from app.api.v1.commission_member_evaluations import (
    router as commission_member_evaluations_router,
)
from app.api.v1.expert_commissions import router as expert_commissions_router
from app.api.v1.expert_staff_members import router as expert_staff_members_router
from app.api.v1.expert_students import router as expert_students_router
from app.api.v1.health import router as health_router
from app.api.v1.manager_student_attestations import (
    router as manager_student_attestations_router,
)
from app.api.v1.manager_students import router as manager_students_router
from app.api.v1.manager_students_crud import router as manager_students_crud_router

api_router = APIRouter()

api_router.include_router(health_router)
api_router.include_router(manager_students_router)
api_router.include_router(manager_students_crud_router)

api_router.include_router(academic_director_attestation_lifecycle_router)
api_router.include_router(academic_director_attestation_periods_router)
api_router.include_router(academic_director_attestation_criteria_router)

api_router.include_router(manager_student_attestations_router)
api_router.include_router(expert_staff_members_router)
api_router.include_router(expert_students_router)
api_router.include_router(expert_commissions_router)
api_router.include_router(commission_member_evaluations_router)