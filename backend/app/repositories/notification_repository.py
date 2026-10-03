from sqlalchemy import select
from app.models.notification import Notification

class NotificationRepository:
    @staticmethod
    async def create(db, notification):
        db.add(notification)
        await db.commit()
        await db.refresh(notification)
        return notification

    @staticmethod
    async def get_user_notifications(db, user_id):
        r = await db.execute(select(Notification).where(Notification.user_id == user_id).order_by(Notification.created_at.desc()))
        return list(r.scalars().all())

    @staticmethod
    async def get_by_id(db, notification_id):
        r = await db.execute(select(Notification).where(Notification.id == notification_id))
        return r.scalar_one_or_none()

    @staticmethod
    async def update(db, notification):
        await db.commit()
        await db.refresh(notification)
        return notification
