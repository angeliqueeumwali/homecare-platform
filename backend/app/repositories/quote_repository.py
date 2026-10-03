from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.models.quote import Quote

class QuoteRepository:
    @staticmethod
    async def create(db, quote):
        db.add(quote)
        await db.commit()
        await db.refresh(quote)
        return quote

    @staticmethod
    async def get_by_id(db, quote_id):
        r = await db.execute(select(Quote).options(selectinload(Quote.service_request)).where(Quote.id == quote_id))
        return r.scalar_one_or_none()

    @staticmethod
    async def get_request_quotes(db, request_id):
        r = await db.execute(select(Quote).where(Quote.service_request_id == request_id))
        return list(r.scalars().all())

    @staticmethod
    async def update(db, quote):
        await db.commit()
        await db.refresh(quote)
        return quote
