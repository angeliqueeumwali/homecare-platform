from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, require_roles
from app.core.enums import UserRole
from app.database.connection import get_db
from app.models.user import User
from app.repositories.provider_repository import ProviderRepository
from app.schemas.admin_schema import (
    ProviderDetailResponse,
    StatsResponse,
    issue_page,
    notification_page,
    payment_page,
    provider_detail_response,
    provider_page,
    request_page,
    quote_page,
    review_page,
    user_page,
)
from app.schemas.provider_schema import (
    ProviderApprovalRequest,
    ProviderProfileResponse,
)
from app.schemas.user_schema import UserResponse
from app.services.admin_service import AdminService
from app.services.provider_service import ProviderService

router = APIRouter(prefix="/admin", tags=["Admin"])
admin = require_roles(UserRole.ADMIN)


@router.get("/users", response_model=list[UserResponse])
async def users(
    db: AsyncSession = Depends(get_db),
    _: object = Depends(admin),
):
    from app.repositories.user_repository import UserRepository

    return await UserRepository.get_all(db)


@router.get("/providers", response_model=list[ProviderProfileResponse])
async def providers(
    db: AsyncSession = Depends(get_db),
    _: object = Depends(admin),
):
    return await ProviderRepository.get_all(db)


@router.patch(
    "/providers/{provider_id}/approval",
    response_model=ProviderProfileResponse,
)
async def approve_provider(
    provider_id,
    data: ProviderApprovalRequest,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(admin),
):
    provider = await ProviderRepository.get_by_id(db, provider_id)
    if not provider:
        raise HTTPException(404, "Provider not found")
    return await ProviderService.approve(db, provider, data.approved)


@router.get("/stats", response_model=StatsResponse)
async def stats(
    db: AsyncSession = Depends(get_db),
    _: object = Depends(admin),
):
    return await AdminService.get_stats(db)


@router.get("/users/list")
async def user_list(
    search: Optional[str] = Query(default=None, max_length=255),
    role: Optional[str] = Query(default=None),
    is_active: Optional[bool] = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _: object = Depends(admin),
):
    result = await AdminService.list_users(
        db,
        search=search,
        role=role,
        is_active=is_active,
        page=page,
        page_size=page_size,
    )
    return user_page(
        result["items"],
        result["total"],
        result["page"],
        result["page_size"],
        result["total_pages"],
    )


@router.get("/users/{user_id}")
async def user_detail(
    user_id,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(admin),
):
    from app.repositories.user_repository import UserRepository

    user = await UserRepository.get_by_id(db, user_id)
    if not user:
        raise HTTPException(404, "User not found")
    return UserResponse.model_validate(user)


@router.patch("/users/{user_id}/status", response_model=UserResponse)
async def set_user_status(
    user_id,
    is_active: bool,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(admin),
):
    from app.repositories.user_repository import UserRepository

    if str(user_id) == str(current_user.id):
        raise HTTPException(
            400, "You cannot change your own account status"
        )

    user = await UserRepository.get_by_id(db, user_id)
    if not user:
        raise HTTPException(404, "User not found")

    return await AdminService.set_user_active(
        db, user, is_active
    )


@router.get("/providers/list")
async def provider_list(
    search: Optional[str] = Query(default=None, max_length=255),
    approval_status: Optional[str] = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _: object = Depends(admin),
):
    result = await AdminService.list_providers(
        db,
        search=search,
        approval_status=approval_status,
        page=page,
        page_size=page_size,
    )
    return provider_page(
        result["items"],
        result["total"],
        result["page"],
        result["page_size"],
        result["total_pages"],
    )


@router.get("/providers/{provider_id}", response_model=ProviderDetailResponse)
async def provider_detail(
    provider_id,
    db: AsyncSession = Depends(get_db),
    _: object = Depends(admin),
):
    details = await AdminService.get_provider_details(
        db, provider_id
    )
    if not details:
        raise HTTPException(404, "Provider not found")
    return provider_detail_response(details)


@router.get("/service-requests")
async def service_request_list(
    search: Optional[str] = Query(default=None, max_length=255),
    status: Optional[str] = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _: object = Depends(admin),
):
    result = await AdminService.list_service_requests(
        db,
        search=search,
        status=status,
        page=page,
        page_size=page_size,
    )
    return request_page(
        result["items"],
        result["total"],
        result["page"],
        result["page_size"],
        result["total_pages"],
    )


@router.get("/quotes")
async def quote_list(
    status: Optional[str] = Query(default=None),
    request_id: Optional[str] = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _: object = Depends(admin),
):
    result = await AdminService.list_quotes(
        db,
        status=status,
        request_id=request_id,
        page=page,
        page_size=page_size,
    )
    return quote_page(
        result["items"],
        result["total"],
        result["page"],
        result["page_size"],
        result["total_pages"],
    )


@router.get("/payments")
async def payment_list(
    status: Optional[str] = Query(default=None),
    method: Optional[str] = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _: object = Depends(admin),
):
    result = await AdminService.list_payments(
        db,
        status=status,
        method=method,
        page=page,
        page_size=page_size,
    )
    return payment_page(
        result["items"],
        result["total"],
        result["page"],
        result["page_size"],
        result["total_pages"],
    )


@router.get("/reviews")
async def review_list(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _: object = Depends(admin),
):
    result = await AdminService.list_reviews(
        db,
        page=page,
        page_size=page_size,
    )
    return review_page(
        result["items"],
        result["total"],
        result["page"],
        result["page_size"],
        result["total_pages"],
    )


@router.get("/issues")
async def issue_list(
    status: Optional[str] = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _: object = Depends(admin),
):
    result = await AdminService.list_issues(
        db,
        status=status,
        page=page,
        page_size=page_size,
    )
    return issue_page(
        result["items"],
        result["total"],
        result["page"],
        result["page_size"],
        result["total_pages"],
    )


@router.get("/notifications")
async def notification_list(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _: object = Depends(admin),
):
    result = await AdminService.list_notifications(
        db,
        page=page,
        page_size=page_size,
    )
    return notification_page(
        result["items"],
        result["total"],
        result["page"],
        result["page_size"],
        result["total_pages"],
    )
