from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_current_user, require_roles
from app.core.enums import UserRole
from app.database.connection import get_db
from app.models.user import User
from app.schemas.assignment_schema import AssignmentCreate, AssignmentResponse, AssignmentStatusUpdate
from app.services.assignment_service import AssignmentService
from app.services.provider_service import ProviderService

router = APIRouter(prefix="/assignments", tags=["Assignments"])

@router.post("", response_model=AssignmentResponse, status_code=201)
async def create_assignment(data: AssignmentCreate, db=Depends(get_db), _: object=Depends(require_roles(UserRole.ADMIN))):
    try:
        return await AssignmentService.create(db, data.service_request_id, data.service_request_item_id, data.provider_id)
    except ValueError as e:
        raise HTTPException(400, str(e))

@router.get("/me", response_model=list[AssignmentResponse])
async def my_assignments(db=Depends(get_db), current_user: User=Depends(require_roles(UserRole.SERVICE_PROVIDER))):
    provider = await ProviderService.get_my_profile(db, current_user)
    return await AssignmentService.provider_list(db, provider.id)

@router.get("/{assignment_id}", response_model=AssignmentResponse)
async def get_assignment(assignment_id, db=Depends(get_db), current_user: User=Depends(get_current_user)):
    try:
        a = await AssignmentService.get(db, assignment_id)
        if current_user.role == UserRole.ADMIN:
            return a
        if current_user.role == UserRole.SERVICE_PROVIDER:
            provider = await ProviderService.get_my_profile(db, current_user)
            if a.provider_id != provider.id:
                raise HTTPException(403, "Access denied")
        elif a.service_request.customer_id != current_user.id:
            raise HTTPException(403, "Access denied")
        return a
    except ValueError as e:
        raise HTTPException(404, str(e))

@router.patch("/{assignment_id}/status", response_model=AssignmentResponse)
async def update_assignment(assignment_id, data: AssignmentStatusUpdate, db=Depends(get_db), current_user: User=Depends(require_roles(UserRole.SERVICE_PROVIDER))):
    try:
        a = await AssignmentService.get(db, assignment_id)
        provider = await ProviderService.get_my_profile(db, current_user)
        if a.provider_id != provider.id:
            raise HTTPException(403, "Access denied")
        return await AssignmentService.update_status(db, a, data.status)
    except ValueError as e:
        raise HTTPException(400, str(e))
