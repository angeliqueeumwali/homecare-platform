
from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

import pytest

from app.core.enums import UserRole
from app.models.user import User
from app.services.user_service import UserService


def create_test_user():
    return User(
        id=uuid4(),
        first_name="Angelique",
        last_name="Umwali",
        email="angelique.test@example.com",
        phone_number="0780000000",
        password_hash="hashed_password",
        role=UserRole.CUSTOMER,
        is_active=True,
    )


@pytest.mark.asyncio
async def test_create_user():
    db = Mock()
    user = create_test_user()

    with patch(
        "app.services.user_service.UserRepository.create",
        new=AsyncMock(return_value=user),
    ):
        result = await UserService.create_user(
            db=db,
            first_name="Angelique",
            last_name="Umwali",
            email="angelique.test@example.com",
            phone_number="0780000000",
            password_hash="hashed_password",
            role=UserRole.CUSTOMER,
        )

    assert result == user


@pytest.mark.asyncio
async def test_get_user_by_id():
    db = Mock()
    user = create_test_user()

    with patch(
        "app.services.user_service.UserRepository.get_by_id",
        new=AsyncMock(return_value=user),
    ):
        result = await UserService.get_user_by_id(db, user.id)

    assert result == user


@pytest.mark.asyncio
async def test_get_user_by_email():
    db = Mock()
    user = create_test_user()

    with patch(
        "app.services.user_service.UserRepository.get_by_email",
        new=AsyncMock(return_value=user),
    ):
        result = await UserService.get_user_by_email(
            db,
            "angelique.test@example.com",
        )

    assert result == user


@pytest.mark.asyncio
async def test_get_all_users():
    db = Mock()
    users = [create_test_user(), create_test_user()]

    with patch(
        "app.services.user_service.UserRepository.get_all",
        new=AsyncMock(return_value=users),
    ):
        result = await UserService.get_all_users(db)

    assert result == users


@pytest.mark.asyncio
async def test_update_user_names():
    db = Mock()
    user = create_test_user()

    with patch(
        "app.services.user_service.UserRepository.update",
        new=AsyncMock(return_value=user),
    ):
        result = await UserService.update_user(
            db=db,
            user=user,
            first_name="Updated",
            last_name="Name",
        )

    assert user.first_name == "Updated"
    assert user.last_name == "Name"
    assert result == user


@pytest.mark.asyncio
async def test_update_user_phone():
    db = Mock()
    user = create_test_user()
    new_phone = "0780000001"

    with patch(
        "app.services.user_service.UserRepository.get_by_phone",
        new=AsyncMock(return_value=None),
    ), patch(
        "app.services.user_service.UserRepository.update",
        new=AsyncMock(return_value=user),
    ):
        result = await UserService.update_user(
            db=db,
            user=user,
            phone_number=new_phone,
        )

    assert user.phone_number == new_phone
    assert result == user


@pytest.mark.asyncio
async def test_update_user_duplicate_phone():
    db = Mock()
    user = create_test_user()
    existing_user = create_test_user()
    existing_user.id = uuid4()

    with patch(
        "app.services.user_service.UserRepository.get_by_phone",
        new=AsyncMock(return_value=existing_user),
    ):
        with pytest.raises(
            ValueError,
            match="Phone number is already registered",
        ):
            await UserService.update_user(
                db=db,
                user=user,
                phone_number="0780000001",
            )


@pytest.mark.asyncio
async def test_delete_user():
    db = Mock()
    user = create_test_user()

    with patch(
        "app.services.user_service.UserRepository.delete",
        new=AsyncMock(return_value=None),
    ) as mock_delete:
        result = await UserService.delete_user(db, user)

    mock_delete.assert_awaited_once_with(db, user)
    assert result is None
