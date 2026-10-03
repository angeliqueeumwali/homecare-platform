from datetime import datetime, timedelta, timezone
from unittest.mock import ANY, AsyncMock, Mock, patch
from uuid import uuid4

import pytest

from app.models.user import User
from app.services.password_reset_service import (
    PasswordResetService,
    _token_digest,
)


def mock_user():
    return User(
        id=uuid4(),
        first_name="Test",
        last_name="User",
        email="test@example.com",
        phone_number="0780000000",
        password_hash="hashed",
        role="CUSTOMER",
        is_active=True,
    )


@pytest.mark.asyncio
async def test_request_reset_creates_token_for_known_user():
    db = Mock()
    user = mock_user()
    token = "generated-reset-token"

    with patch(
        "app.services.password_reset_service"
        ".UserRepository.get_by_email",
        new=AsyncMock(return_value=user),
    ), patch(
        "app.services.password_reset_service"
        ".SupportRepository.create_reset_token",
        new=AsyncMock(),
    ) as mock_create, patch(
        "app.services.password_reset_service"
        ".token_urlsafe",
        return_value=token,
    ), patch(
        "app.services.password_reset_service"
        ".settings.PASSWORD_RESET_DEV_RETURN_TOKEN",
        True,
    ):
        result = await PasswordResetService.request_reset(
            db, "test@example.com", "http://app"
        )

    assert result["requested"] is True
    assert result["expires_in_minutes"] == 30
    assert result["email_delivery_configured"] is False
    assert (
        result["reset_url"] == f"http://app/reset-password"
        f"?token={token}"
    )
    mock_create.assert_awaited_once_with(
        db, user.id, token, ANY
    )


@pytest.mark.asyncio
async def test_request_reset_unknown_user_no_token():
    db = Mock()

    with patch(
        "app.services.password_reset_service"
        ".UserRepository.get_by_email",
        new=AsyncMock(return_value=None),
    ), patch(
        "app.services.password_reset_service"
        ".SupportRepository.create_reset_token",
        new=AsyncMock(),
    ) as mock_create:
        result = await PasswordResetService.request_reset(
            db, "nobody@example.com"
        )

    assert result["requested"] is True
    assert "reset_url" not in result
    assert "dev_token" not in result
    mock_create.assert_not_awaited()


@pytest.mark.asyncio
async def test_request_reset_hides_token_by_default():
    db = Mock()
    user = mock_user()

    with patch(
        "app.services.password_reset_service"
        ".UserRepository.get_by_email",
        new=AsyncMock(return_value=user),
    ), patch(
        "app.services.password_reset_service"
        ".SupportRepository.create_reset_token",
        new=AsyncMock(),
    ), patch(
        "app.services.password_reset_service"
        ".settings.PASSWORD_RESET_DEV_RETURN_TOKEN",
        False,
    ):
        result = await PasswordResetService.request_reset(
            db, "test@example.com"
        )

    assert "dev_token" not in result
    assert "reset_url" not in result


@pytest.mark.asyncio
async def test_request_reset_returns_token_in_dev_mode():
    db = Mock()
    user = mock_user()
    token = "dev-token-value"

    with patch(
        "app.services.password_reset_service"
        ".UserRepository.get_by_email",
        new=AsyncMock(return_value=user),
    ), patch(
        "app.services.password_reset_service"
        ".SupportRepository.create_reset_token",
        new=AsyncMock(),
    ), patch(
        "app.services.password_reset_service"
        ".token_urlsafe",
        return_value=token,
    ), patch(
        "app.services.password_reset_service"
        ".settings.PASSWORD_RESET_DEV_RETURN_TOKEN",
        True,
    ):
        result = await PasswordResetService.request_reset(
            db, "test@example.com"
        )

    assert result["dev_token"] == token


@pytest.mark.asyncio
async def test_confirm_reset_success():
    db = AsyncMock()
    user = mock_user()
    token = "valid-reset-token"
    record = Mock()
    record.user_id = user.id

    with patch(
        "app.services.password_reset_service"
        ".SupportRepository.find_valid_token",
        new=AsyncMock(return_value=record),
    ), patch(
        "app.services.password_reset_service"
        ".UserRepository.get_by_id",
        new=AsyncMock(return_value=user),
    ), patch(
        "app.services.password_reset_service"
        ".SupportRepository.mark_token_used",
        new=AsyncMock(),
    ) as mock_mark, patch(
        "app.services.password_reset_service"
        ".SupportRepository.purge_user_tokens",
        new=AsyncMock(),
    ) as mock_purge, patch(
        "app.services.password_reset_service.hash_password",
        return_value="new-hash",
    ):
        result = await PasswordResetService.confirm_reset(
            db, token, "new-strong-password"
        )

    assert result is user
    assert user.password_hash == "new-hash"
    mock_mark.assert_awaited_once_with(db, record)
    mock_purge.assert_awaited_once_with(db, user.id)


@pytest.mark.asyncio
async def test_confirm_reset_rejects_unknown_token():
    db = Mock()

    with patch(
        "app.services.password_reset_service"
        ".SupportRepository.find_valid_token",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError):
            await PasswordResetService.confirm_reset(
                db, "unknown-token-value", "new-password-1"
            )


@pytest.mark.asyncio
async def test_confirm_reset_rejects_inactive_user():
    db = Mock()
    user = mock_user()
    user.is_active = False
    record = Mock()
    record.user_id = user.id

    with patch(
        "app.services.password_reset_service"
        ".SupportRepository.find_valid_token",
        new=AsyncMock(return_value=record),
    ), patch(
        "app.services.password_reset_service"
        ".UserRepository.get_by_id",
        new=AsyncMock(return_value=user),
    ), patch(
        "app.services.password_reset_service"
        ".SupportRepository.mark_token_used",
        new=AsyncMock(),
    ) as mock_mark:
        with pytest.raises(ValueError):
            await PasswordResetService.confirm_reset(
                db, "some-token-value", "new-password-1"
            )

    mock_mark.assert_not_awaited()
    assert user.password_hash == "hashed"


@pytest.mark.asyncio
async def test_confirm_reset_rejects_missing_user():
    db = Mock()
    record = Mock()
    record.user_id = uuid4()

    with patch(
        "app.services.password_reset_service"
        ".SupportRepository.find_valid_token",
        new=AsyncMock(return_value=record),
    ), patch(
        "app.services.password_reset_service"
        ".UserRepository.get_by_id",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError):
            await PasswordResetService.confirm_reset(
                db, "some-token-value", "new-password-1"
            )


@pytest.mark.asyncio
async def test_confirm_reset_rejects_empty_token():
    db = Mock()

    with pytest.raises(ValueError):
        await PasswordResetService.confirm_reset(
            db, "", "new-password-1"
        )


def test_token_digest_is_deterministic():
    assert _token_digest("abc") == _token_digest("abc")
    assert _token_digest("abc") != _token_digest("xyz")
    assert len(_token_digest("abc")) == 64
