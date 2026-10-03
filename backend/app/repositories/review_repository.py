from sqlalchemy import select
from app.models.review import Review

class ReviewRepository:
    @staticmethod
    async def create(db, review):
        db.add(review)
        await db.commit()
        await db.refresh(review)
        return review

    @staticmethod
    async def get_by_assignment(db, assignment_id):
        r = await db.execute(select(Review).where(Review.assignment_id == assignment_id))
        return r.scalar_one_or_none()

    @staticmethod
    async def get_provider_reviews(db, provider_id):
        r = await db.execute(select(Review).where(Review.provider_id == provider_id).order_by(Review.created_at.desc()))
        return list(r.scalars().all())
