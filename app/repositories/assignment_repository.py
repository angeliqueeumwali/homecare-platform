from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.models.assignment import Assignment

class AssignmentRepository:
    @staticmethod
    async def create(db, assignment):
        db.add(assignment)
        await db.commit()
        await db.refresh(assignment)
        return assignment

    @staticmethod
    async def get_by_id(db, assignment_id):
        r = await db.execute(
            select(Assignment).options(
                selectinload(Assignment.service_request),
                selectinload(Assignment.service_request_item),
            ).where(Assignment.id == assignment_id)
        )
        return r.scalar_one_or_none()

    @staticmethod
    async def get_provider_assignments(db, provider_id):
        r = await db.execute(select(Assignment).where(Assignment.provider_id == provider_id).order_by(Assignment.assigned_at.desc()))
        return list(r.scalars().all())

    @staticmethod
    async def get_request_assignments(db, request_id):
        r = await db.execute(select(Assignment).where(Assignment.service_request_id == request_id))
        return list(r.scalars().all())

    @staticmethod
    async def update(db, assignment):
        await db.commit()
        await db.refresh(assignment)
        return assignment
