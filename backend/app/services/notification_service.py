from app.core.enums import NotificationType
from app.models.notification import Notification
from app.repositories.notification_repository import NotificationRepository

class NotificationService:
    @staticmethod
    async def create(db, user_id, notification_type, title, message, reference_id=None):
        notification = Notification(
            user_id=user_id,
            notification_type=NotificationType(notification_type),
            title=title,
            message=message,
            reference_id=reference_id,
        )
        return await NotificationRepository.create(db, notification)

    @staticmethod
    async def list_user(db, user_id):
        return await NotificationRepository.get_user_notifications(db, user_id)

    @staticmethod
    async def mark_read(db, notification_id, user_id):
        notification = await NotificationRepository.get_by_id(db, notification_id)
        if not notification or notification.user_id != user_id:
            raise ValueError("Notification not found")
        notification.is_read = True
        return await NotificationRepository.update(db, notification)
