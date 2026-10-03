from fastapi import APIRouter, Depends, HTTPException
from app.core.dependencies import get_current_user, require_roles
from app.core.enums import UserRole
from app.database.connection import get_db
from app.models.user import User
from app.schemas.review_schema import ReviewCreate, ReviewResponse
from app.services.review_service import ReviewService
from app.services.provider_service import ProviderService

router = APIRouter(prefix="/reviews", tags=["Reviews"])

@router.post("", response_model=ReviewResponse, status_code=201)
async def create_review(data: ReviewCreate, db=Depends(get_db), current_user: User=Depends(require_roles(UserRole.CUSTOMER))):
    try:
        return await ReviewService.create(db, current_user.id, data)
    except ValueError as e:
        raise HTTPException(400, str(e))

@router.get("/provider/{provider_id}", response_model=list[ReviewResponse])
async def provider_reviews(provider_id, db=Depends(get_db)):
    return await ReviewService.provider_reviews(db, provider_id)

@router.get("/me/provider", response_model=list[ReviewResponse])
async def my_provider_reviews(db=Depends(get_db), current_user: User=Depends(require_roles(UserRole.SERVICE_PROVIDER))):
    provider = await ProviderService.get_my_profile(db, current_user)
    return await ReviewService.provider_reviews(db, provider.id)
