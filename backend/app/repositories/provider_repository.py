from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.provider_profile import ProviderProfile
from app.models.provider_service import ProviderService
from app.models.provider_location import ProviderLocation

class ProviderRepository:
    @staticmethod
    async def get_by_id(db, provider_id):
        r = await db.execute(select(ProviderProfile).where(ProviderProfile.id == provider_id))
        return r.scalar_one_or_none()

    @staticmethod
    async def get_by_user_id(db, user_id):
        r = await db.execute(select(ProviderProfile).where(ProviderProfile.user_id == user_id))
        return r.scalar_one_or_none()

    @staticmethod
    async def get_all(db):
        r = await db.execute(select(ProviderProfile).order_by(ProviderProfile.created_at.desc()))
        return list(r.scalars().all())

    @staticmethod
    async def get_available_for_service(db, service_category_id):
        r = await db.execute(
            select(ProviderProfile)
            .join(ProviderService, ProviderService.provider_id == ProviderProfile.id)
            .where(
                ProviderService.service_category_id == service_category_id,
                ProviderService.is_active.is_(True),
                ProviderProfile.is_available.is_(True),
            )
        )
        return list(r.scalars().unique().all())

    @staticmethod
    async def create(db, provider):
        db.add(provider)
        await db.commit()
        await db.refresh(provider)
        return provider

    @staticmethod
    async def create_service(db, provider_service):
        db.add(provider_service)
        await db.commit()
        await db.refresh(provider_service)
        return provider_service

    @staticmethod
    async def get_service(db, provider_id, service_category_id):
        r = await db.execute(select(ProviderService).where(
            ProviderService.provider_id == provider_id,
            ProviderService.service_category_id == service_category_id,
        ))
        return r.scalar_one_or_none()

    @staticmethod
    async def delete_service(db, provider_service):
        await db.delete(provider_service)
        await db.commit()

    @staticmethod
    async def get_location(db, provider_id):
        r = await db.execute(select(ProviderLocation).where(ProviderLocation.provider_id == provider_id))
        return r.scalar_one_or_none()

    @staticmethod
    async def save_location(db, location):
        db.add(location)
        await db.commit()
        await db.refresh(location)
        return location

    @staticmethod
    async def list_services(db, provider_id):
        r = await db.execute(select(ProviderService).where(ProviderService.provider_id == provider_id))
        return list(r.scalars().all())
