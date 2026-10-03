from datetime import datetime, timedelta, timezone
from hashlib import sha256
from secrets import token_urlsafe
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import hash_password
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.repositories.support_repository import SupportRepository


def _token_digest(token: str) -> str:
    return sha256(token.encode("utf-8")).hexdigest()


class PasswordResetService:
    @staticmethod
    async def request_reset(
        db: AsyncSession,
        email: str,
        base_url: str | None = None,
    ) -> dict:
        user = await UserRepository.get_by_email(db, email)

        if user is not None:
            token = token_urlsafe(32)
            expires_at = datetime.now(timezone.utc) + timedelta(
                minutes=settings.PASSWORD_RESET_TOKEN_EXPIRE_MINUTES
            )
            await SupportRepository.create_reset_token(
                db, user.id, token, expires_at
            )
            reset_url = (
                f"{base_url}/reset-password?token={token}"
                if base_url
                else None
            )
        else:
            token = None
            reset_url = None

        result = {
            "requested": True,
            "expires_in_minutes": (
                settings.PASSWORD_RESET_TOKEN_EXPIRE_MINUTES
            ),
            "email_delivery_configured": False,
        }

        if settings.PASSWORD_RESET_DEV_RETURN_TOKEN:
            result["reset_url"] = reset_url
            result["dev_token"] = token

        return result

    @staticmethod
    async def confirm_reset(
        db: AsyncSession,
        token: str,
        new_password: str,
    ) -> User:
        if not token:
            raise ValueError("Invalid or expired reset token")

        record = await SupportRepository.find_valid_token(
            db, _token_digest(token)
        )
        if record is None:
            raise ValueError("Invalid or expired reset token")

        user = await UserRepository.get_by_id(db, record.user_id)
        if user is None or not user.is_active:
            raise ValueError("Invalid or expired reset token")

        user.password_hash = hash_password(new_password)
        await SupportRepository.mark_token_used(db, record)
        await SupportRepository.purge_user_tokens(db, user.id)
        await db.commit()
        await db.refresh(user)
        return user
