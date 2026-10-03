from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.service_category import ServiceCategory

class ServiceCategoryRepository:
    @staticmethod
    async def create(db, category):
        db.add(category)
        await db.commit()
        await db.refresh(category)
        return category

    @staticmethod
    async def get_by_id(db, category_id):
        r = await db.execute(select(ServiceCategory).where(ServiceCategory.id == category_id))
        return r.scalar_one_or_none()

    @staticmethod
    async def get_by_name(db, name):
        r = await db.execute(select(ServiceCategory).where(ServiceCategory.name.ilike(name)))
        return r.scalar_one_or_none()

    @staticmethod
    async def get_all(db):
        r = await db.execute(select(ServiceCategory).order_by(ServiceCategory.name))
        return list(r.scalars().all())

    @staticmethod
    async def update(db, category):
        await db.commit()
        await db.refresh(category)
        return category

    @staticmethod
    async def delete(db, category):
        await db.delete(category)
        await db.commit()
