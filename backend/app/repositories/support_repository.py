from datetime import datetime, timedelta, timezone
from hashlib import sha256
from uuid import uuid4

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.support import ContactMessage, PasswordResetToken


def _token_digest(token: str) -> str:
    return sha256(token.encode("utf-8")).hexdigest()


class SupportRepository:
    @staticmethod
    async def create_reset_token(
        db: AsyncSession,
        user_id,
        token: str,
        expires_at: datetime,
    ) -> None:
        db.add(
            PasswordResetToken(
                id=uuid4(),
                user_id=user_id,
                token_hash=_token_digest(token),
                expires_at=expires_at,
            )
        )
        await db.commit()

    @staticmethod
    async def find_valid_token(
        db: AsyncSession,
        token_hash: str,
    ):
        result = await db.execute(
            select(PasswordResetToken).where(
                PasswordResetToken.token_hash == token_hash,
                PasswordResetToken.used_at.is_(None),
                PasswordResetToken.expires_at > datetime.now(
                    timezone.utc
                ),
            )
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def mark_token_used(
        db: AsyncSession,
        token: PasswordResetToken,
    ) -> None:
        token.used_at = datetime.now(timezone.utc)
        await db.commit()

    @staticmethod
    async def purge_user_tokens(
        db: AsyncSession,
        user_id,
    ) -> None:
        await db.execute(
            delete(PasswordResetToken).where(
                PasswordResetToken.user_id == user_id
            )
        )
        await db.commit()

    @staticmethod
    async def count_recent_contact_messages(
        db: AsyncSession,
        ip_address: str | None,
        since: datetime,
    ) -> int:
        result = await db.execute(
            select(ContactMessage.id).where(
                ContactMessage.ip_address == ip_address,
                ContactMessage.created_at > since,
            )
        )
        return len(result.scalars().all())

    @staticmethod
    async def list_contact_messages(
        db: AsyncSession,
    ) -> list[ContactMessage]:
        result = await db.execute(
            select(ContactMessage).order_by(
                ContactMessage.created_at.desc()
            )
        )
        return list(result.scalars().all())

    @staticmethod
    async def create_contact_message(
        db: AsyncSession,
        name: str,
        email: str,
        subject: str,
        message: str,
        ip_address: str | None,
    ) -> ContactMessage:
        record = ContactMessage(
            id=uuid4(),
            name=name,
            email=email,
            subject=subject,
            message=message,
            ip_address=ip_address,
        )
        db.add(record)
        await db.commit()
        await db.refresh(record)
        return record
