from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4
import pytest

from app.core.enums import UserRole
from app.core.security import (
    create_access_token,
    decode_access_token,
    hash_password,
    verify_password,
)
from app.models.user import User
from app.services.auth_service import AuthService


def test_password_hash_and_verify():
    password = "StrongPassword123!"
    hashed_password = hash_password(password)

    assert hashed_password != password
    assert verify_password(password, hashed_password)
    assert not verify_password("WrongPassword123!", hashed_password)


def test_access_token_creation_and_decoding():
    user_id = uuid4()

    token = create_access_token(user_id)
    decoded_user_id = decode_access_token(token)

    assert isinstance(token, str)
    assert decoded_user_id == user_id


@pytest.mark.asyncio
async def test_register_user_success():
    db = Mock()
    created_user = User(
        id=uuid4(),
        first_name="Angelique",
        last_name="Umwali",
        email="angelique.test@example.com",
        phone_number="0780000000",
        password_hash="hashed_password",
        role=UserRole.CUSTOMER,
    )

    with patch(
        "app.services.auth_service.UserRepository.get_by_email",
        new=AsyncMock(return_value=None),
    ), patch(
        "app.services.auth_service.UserRepository.get_by_phone",
        new=AsyncMock(return_value=None),
    ), patch(
        "app.services.auth_service.UserService.create_user",
        new=AsyncMock(return_value=created_user),
    ):
        result = await AuthService.register_user(
            db=db,
            first_name="Angelique",
            last_name="Umwali",
            email="angelique.test@example.com",
            phone_number="0780000000",
            password="StrongPassword123!",
        )

    assert result == created_user


@pytest.mark.asyncio
async def test_register_user_duplicate_email():
    db = Mock()
    existing_user = Mock()

    with patch(
        "app.services.auth_service.UserRepository.get_by_email",
        new=AsyncMock(return_value=existing_user),
    ):
        with pytest.raises(ValueError, match="Email is already registered"):
            await AuthService.register_user(
                db=db,
                first_name="Angelique",
                last_name="Umwali",
                email="existing@example.com",
                phone_number="0780000001",
                password="StrongPassword123!",
            )


@pytest.mark.asyncio
async def test_register_user_duplicate_phone():
    db = Mock()
    existing_user = Mock()

    with patch(
        "app.services.auth_service.UserRepository.get_by_email",
        new=AsyncMock(return_value=None),
    ), patch(
        "app.services.auth_service.UserRepository.get_by_phone",
        new=AsyncMock(return_value=existing_user),
    ):
        with pytest.raises(ValueError, match="Phone number is already registered"):
            await AuthService.register_user(
                db=db,
                first_name="Angelique",
                last_name="Umwali",
                email="new@example.com",
                phone_number="0780000002",
                password="StrongPassword123!",
            )


@pytest.mark.asyncio
async def test_login_user_success():
    db = Mock()
    password = "StrongPassword123!"
    user_id = uuid4()

    user = Mock()
    user.id = user_id
    user.password_hash = hash_password(password)
    user.is_active = True

    with patch(
        "app.services.auth_service.UserRepository.get_by_email",
        new=AsyncMock(return_value=user),
    ):
        token = await AuthService.login_user(
            db=db,
            email="angelique.test@example.com",
            password=password,
        )

    assert isinstance(token, str)
    assert decode_access_token(token) == user_id


@pytest.mark.asyncio
async def test_login_user_invalid_password():
    db = Mock()
    user = Mock()
    user.password_hash = hash_password("CorrectPassword123!")
    user.is_active = True

    with patch(
        "app.services.auth_service.UserRepository.get_by_email",
        new=AsyncMock(return_value=user),
    ):
        with pytest.raises(ValueError, match="Invalid email or password"):
            await AuthService.login_user(
                db=db,
                email="angelique.test@example.com",
                password="WrongPassword123!",
            )


@pytest.mark.asyncio
async def test_login_user_email_not_found():
    db = Mock()

    with patch(
        "app.services.auth_service.UserRepository.get_by_email",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError, match="Invalid email or password"):
            await AuthService.login_user(
                db=db,
                email="missing@example.com",
                password="StrongPassword123!",
            )


@pytest.mark.asyncio
async def test_login_user_inactive_account():
    db = Mock()
    user = Mock()
    user.password_hash = hash_password("StrongPassword123!")
    user.is_active = False

    with patch(
        "app.services.auth_service.UserRepository.get_by_email",
        new=AsyncMock(return_value=user),
    ):
        with pytest.raises(ValueError, match="User account is inactive"):
            await AuthService.login_user(
                db=db,
                email="inactive@example.com",
                password="StrongPassword123!",
            )
