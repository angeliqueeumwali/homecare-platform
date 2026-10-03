from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.service_request_image import ServiceRequestImage


class ServiceRequestImageRepository:
    @staticmethod
    async def create(db, image):
        db.add(image)
        await db.commit()
        await db.refresh(image)
        return image

    @staticmethod
    async def get_by_id(db, image_id):
        r = await db.execute(
            select(ServiceRequestImage).where(ServiceRequestImage.id == image_id)
        )
        return r.scalar_one_or_none()

    @staticmethod
    async def get_for_request(db, request_id):
        r = await db.execute(
            select(ServiceRequestImage)
            .where(ServiceRequestImage.service_request_id == request_id)
            .order_by(ServiceRequestImage.created_at.asc())
        )
        return list(r.scalars().all())

    @staticmethod
    async def count_for_request(db, request_id):
        r = await db.execute(
            select(ServiceRequestImage).where(
                ServiceRequestImage.service_request_id == request_id
            )
        )
        return len(r.scalars().all())

    @staticmethod
    async def delete(db, image):
        await db.delete(image)
        await db.commit()