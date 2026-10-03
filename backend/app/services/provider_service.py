from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import ProviderApprovalStatus
from app.models.provider_profile import ProviderProfile
from app.models.provider_service import (
    ProviderService as ProviderServiceModel,
)
from app.models.provider_location import ProviderLocation
from app.repositories.provider_repository import ProviderRepository

class ProviderService:
    @staticmethod
    async def create_profile(db, user, business_name=None, bio=None):
        existing = await ProviderRepository.get_by_user_id(db, user.id)
        if existing:
            raise ValueError("Provider profile already exists")
        provider = ProviderProfile(user_id=user.id, business_name=business_name, bio=bio)
        return await ProviderRepository.create(db, provider)

    @staticmethod
    async def get_my_profile(db, user):
        provider = await ProviderRepository.get_by_user_id(db, user.id)
        if not provider:
            raise ValueError("Provider profile not found")
        return provider

    @staticmethod
    async def update_profile(db, provider, business_name=None, bio=None, is_available=None):
        if business_name is not None:
            provider.business_name = business_name
        if bio is not None:
            provider.bio = bio
        if is_available is not None:
            if provider.approval_status != ProviderApprovalStatus.APPROVED and is_available:
                raise ValueError("Provider must be approved before becoming available")
            provider.is_available = is_available
        return await ProviderRepository.create(db, provider)

    @staticmethod
    async def add_service(db, provider, service_category_id):
        existing = await ProviderRepository.get_service(db, provider.id, service_category_id)
        if existing:
            existing.is_active = True
            await db.commit()
            await db.refresh(existing)
            return existing
        return await ProviderRepository.create_service(
            db,
            ProviderServiceModel(
                provider_id=provider.id,
                service_category_id=service_category_id,
            ),
        )

    @staticmethod
    async def remove_service(db, provider, service_category_id):
        service = await ProviderRepository.get_service(db, provider.id, service_category_id)
        if not service:
            raise ValueError("Provider service not found")
        await ProviderRepository.delete_service(db, service)

    @staticmethod
    async def set_location(db, provider, latitude, longitude, address=None):
        location = await ProviderRepository.get_location(db, provider.id)
        if location:
            location.latitude = latitude
            location.longitude = longitude
            location.address = address
            await db.commit()
            await db.refresh(location)
            return location
        return await ProviderRepository.save_location(db, ProviderLocation(
            provider_id=provider.id,
            latitude=latitude,
            longitude=longitude,
            address=address,
        ))

    @staticmethod
    async def get_services(db, provider):
        return await ProviderRepository.list_services(db, provider.id)

    @staticmethod
    async def approve(db, provider, approved):
        provider.approval_status = (
            ProviderApprovalStatus.APPROVED if approved else ProviderApprovalStatus.REJECTED
        )
        if not approved:
            provider.is_available = False
        return await ProviderRepository.create(db, provider)
