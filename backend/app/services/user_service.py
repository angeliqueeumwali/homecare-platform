from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User
from app.repositories.user_repository import UserRepository

class UserService:
    @staticmethod
    async def create_user(db, first_name, last_name, email, phone_number, password_hash, role):
        user = User(first_name=first_name, last_name=last_name, email=email, phone_number=phone_number, password_hash=password_hash, role=role)
        return await UserRepository.create(db, user)

    @staticmethod
    async def get_user_by_id(db, user_id):
        return await UserRepository.get_by_id(db, user_id)

    @staticmethod
    async def get_user_by_email(db, email):
        return await UserRepository.get_by_email(db, email)

    @staticmethod
    async def get_all_users(db):
        return await UserRepository.get_all(db)

    @staticmethod
    async def update_user(db, user, first_name=None, last_name=None, phone_number=None):
        if first_name is not None:
            user.first_name = first_name
        if last_name is not None:
            user.last_name = last_name
        if phone_number is not None:
            existing = await UserRepository.get_by_phone(db, phone_number)
            if existing and existing.id != user.id:
                raise ValueError("Phone number is already registered")
            user.phone_number = phone_number
        return await UserRepository.update(db, user)

    @staticmethod
    async def delete_user(db, user):
        await UserRepository.delete(db, user)
