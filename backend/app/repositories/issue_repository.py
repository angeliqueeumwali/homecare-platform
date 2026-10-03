from sqlalchemy import select
from app.models.issue import Issue

class IssueRepository:
    @staticmethod
    async def create(db, issue):
        db.add(issue)
        await db.commit()
        await db.refresh(issue)
        return issue

    @staticmethod
    async def get_by_id(db, issue_id):
        r = await db.execute(select(Issue).where(Issue.id == issue_id))
        return r.scalar_one_or_none()

    @staticmethod
    async def get_user_issues(db, user_id):
        r = await db.execute(select(Issue).where(Issue.reported_by_id == user_id).order_by(Issue.created_at.desc()))
        return list(r.scalars().all())

    @staticmethod
    async def get_all(db):
        r = await db.execute(select(Issue).order_by(Issue.created_at.desc()))
        return list(r.scalars().all())

    @staticmethod
    async def update(db, issue):
        await db.commit()
        await db.refresh(issue)
        return issue
