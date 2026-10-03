from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import UserRole
from app.core.security import create_access_token, hash_password, verify_password
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.services.user_service import UserService

class AuthService:
    @staticmethod
    async def register_user(db: AsyncSession, first_name: str, last_name: str, email: str, phone_number: str, password: str, role: UserRole = UserRole.CUSTOMER) -> User:
        if await UserRepository.get_by_email(db, email):
            raise ValueError("Email is already registered")
        if await UserRepository.get_by_phone(db, phone_number):
            raise ValueError("Phone number is already registered")
        return await UserService.create_user(
            db, first_name, last_name, email, phone_number, hash_password(password), role
        )

    @staticmethod
    async def login_user(db: AsyncSession, email: str, password: str) -> str:
        user = await UserRepository.get_by_email(db, email)
        if not user or not verify_password(password, user.password_hash):
            raise ValueError("Invalid email or password")
        if not user.is_active:
            raise ValueError("User account is inactive")
        return create_access_token(user.id)
