from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_current_user, require_roles
from app.core.enums import UserRole
from app.database.connection import get_db
from app.models.user import User
from app.schemas.provider_schema import (
    ProviderProfileCreate, ProviderProfileUpdate, ProviderProfileResponse,
    ProviderServiceCreate, ProviderServiceResponse,
    ProviderLocationCreate, ProviderLocationResponse,
)
from app.services.provider_service import ProviderService
from app.services.matching_service import MatchingService

router = APIRouter(prefix="/providers", tags=["Providers"])

provider_role = require_roles(UserRole.SERVICE_PROVIDER)

@router.post("/profile", response_model=ProviderProfileResponse, status_code=201)
async def create_profile(data: ProviderProfileCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(provider_role)):
    try:
        return await ProviderService.create_profile(db, current_user, data.business_name, data.bio)
    except ValueError as e:
        raise HTTPException(400, str(e))

@router.get("/me", response_model=ProviderProfileResponse)
async def get_profile(db=Depends(get_db), current_user: User = Depends(provider_role)):
    try:
        return await ProviderService.get_my_profile(db, current_user)
    except ValueError as e:
        raise HTTPException(404, str(e))

@router.patch("/me", response_model=ProviderProfileResponse)
async def update_profile(data: ProviderProfileUpdate, db=Depends(get_db), current_user: User = Depends(provider_role)):
    try:
        provider = await ProviderService.get_my_profile(db, current_user)
        return await ProviderService.update_profile(db, provider, data.business_name, data.bio, data.is_available)
    except ValueError as e:
        raise HTTPException(400, str(e))

@router.post("/me/services", response_model=ProviderServiceResponse, status_code=201)
async def add_service(data: ProviderServiceCreate, db=Depends(get_db), current_user: User = Depends(provider_role)):
    try:
        provider = await ProviderService.get_my_profile(db, current_user)
        return await ProviderService.add_service(db, provider, data.service_category_id)
    except ValueError as e:
        raise HTTPException(400, str(e))

@router.get("/me/services", response_model=list[ProviderServiceResponse])
async def list_services(db=Depends(get_db), current_user: User = Depends(provider_role)):
    provider = await ProviderService.get_my_profile(db, current_user)
    return await ProviderService.get_services(db, provider)

@router.delete("/me/services/{service_category_id}", status_code=204)
async def remove_service(service_category_id, db=Depends(get_db), current_user: User = Depends(provider_role)):
    try:
        provider = await ProviderService.get_my_profile(db, current_user)
        await ProviderService.remove_service(db, provider, service_category_id)
    except ValueError as e:
        raise HTTPException(404, str(e))

@router.put("/me/location", response_model=ProviderLocationResponse)
async def set_location(data: ProviderLocationCreate, db=Depends(get_db), current_user: User = Depends(provider_role)):
    provider = await ProviderService.get_my_profile(db, current_user)
    return await ProviderService.set_location(db, provider, data.latitude, data.longitude, data.address)


@router.get("/match")
async def match_providers(
    service_category_id,
    latitude: float,
    longitude: float,
    db=Depends(get_db),
    _: User = Depends(get_current_user),
):
    return [
        {
            "provider_id": str(item["provider"].id),
            "distance_km": item["distance_km"],
            "business_name": item["provider"].business_name,
            "average_rating": item["provider"].average_rating,
        }
        for item in await MatchingService.find_nearest_providers(
            db, service_category_id, latitude, longitude
        )
    ]
