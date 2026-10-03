from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.service_request import ServiceRequest
from app.models.service_request_item import ServiceRequestItem

class ServiceRequestRepository:
    @staticmethod
    async def create(db, request, items):
        db.add(request)
        for item in items:
            db.add(item)
        await db.commit()
        # Refresh the relationships explicitly. A plain refresh() only reloads
        # column attributes, so `items` would be left unloaded and the response
        # serializer would attempt a lazy load, which raises MissingGreenlet
        # under the async session.
        await db.refresh(request, attribute_names=["items"])
        return request

    @staticmethod
    async def get_by_id(db, request_id):
        r = await db.execute(select(ServiceRequest).options(selectinload(ServiceRequest.items)).where(ServiceRequest.id == request_id))
        return r.scalar_one_or_none()

    @staticmethod
    async def get_customer_requests(db, customer_id):
        r = await db.execute(select(ServiceRequest).options(selectinload(ServiceRequest.items)).where(ServiceRequest.customer_id == customer_id).order_by(ServiceRequest.created_at.desc()))
        return list(r.scalars().all())

    @staticmethod
    async def get_items(db, request_id):
        r = await db.execute(select(ServiceRequestItem).where(ServiceRequestItem.service_request_id == request_id))
        return list(r.scalars().all())

    @staticmethod
    async def get_item(db, item_id):
        r = await db.execute(select(ServiceRequestItem).where(ServiceRequestItem.id == item_id))
        return r.scalar_one_or_none()

    @staticmethod
    async def update(db, request):
        await db.commit()
        await db.refresh(request)
        return request

    @staticmethod
    async def update_item(db, item):
        await db.commit()
        await db.refresh(item)
        return item

    @staticmethod
    async def get_all(db):
        r = await db.execute(select(ServiceRequest).options(selectinload(ServiceRequest.items)).order_by(ServiceRequest.created_at.desc()))
        return list(r.scalars().all())
