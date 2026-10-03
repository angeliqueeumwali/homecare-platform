from datetime import datetime, timedelta, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.repositories.support_repository import SupportRepository


class ContactService:
    @staticmethod
    async def submit(
        db: AsyncSession,
        name: str,
        email: str,
        subject: str,
        message: str,
        ip_address: str | None = None,
        honeypot: str | None = None,
    ) -> dict:
        if honeypot:
            raise ValueError("Submission rejected")

        if len(message.strip()) < settings.CONTACT_MIN_MESSAGE_LENGTH:
            raise ValueError(
                "Message must be at least "
                f"{settings.CONTACT_MIN_MESSAGE_LENGTH} characters"
            )

        since = datetime.now(timezone.utc) - timedelta(hours=1)
        recent = await SupportRepository.count_recent_contact_messages(
            db, ip_address, since
        )
        if recent >= settings.CONTACT_RATE_LIMIT_PER_HOUR:
            raise ValueError(
                "Too many messages. Please try again later."
            )

        record = await SupportRepository.create_contact_message(
            db,
            name=name.strip(),
            email=email.strip().lower(),
            subject=subject.strip(),
            message=message.strip(),
            ip_address=ip_address,
        )

        return {
            "id": record.id,
            "received": True,
            "email_delivery_configured": False,
        }
