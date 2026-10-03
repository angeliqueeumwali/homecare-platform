import pytest
from datetime import datetime, timedelta, timezone
from httpx import ASGITransport, AsyncClient
from unittest.mock import AsyncMock, patch
from uuid import uuid4

from app.main import app
from app.core.enums import UserRole
from app.models.user import User
from app.core.dependencies import get_current_user


def mock_user(role=UserRole.CUSTOMER):
    return User(
        id=uuid4(),
        first_name="Test",
        last_name="User",
        email="test@example.com",
        phone_number="0780000000",
        password_hash="hashed",
        role=role,
        is_active=True,
    )


class TestPasswordResetRouter:
    @pytest.mark.anyio
    async def test_request_reset_known_email(self):
        user = mock_user()
        token = "dev-reset-token-value"
        with patch(
            "app.routers.auth_router.PasswordResetService"
            ".request_reset",
            new=AsyncMock(
                return_value={
                    "requested": True,
                    "expires_in_minutes": 30,
                    "email_delivery_configured": False,
                    "reset_url": None,
                    "dev_token": token,
                }
            ),
        ) as mock_reset:
            transport = ASGITransport(app=app)
            async with AsyncClient(
                transport=transport, base_url="http://test"
            ) as client:
                response = await client.post(
                    "/auth/password-reset/request",
                    json={"email": "test@example.com"},
                )

        assert response.status_code == 200
        data = response.json()
        assert data["requested"] is True
        assert data["expires_in_minutes"] == 30
        assert mock_reset.await_args.args[1] == (
            "test@example.com"
        )

    @pytest.mark.anyio
    async def test_request_reset_unknown_email_same_response(self):
        with patch(
            "app.routers.auth_router.PasswordResetService"
            ".request_reset",
            new=AsyncMock(
                return_value={
                    "requested": True,
                    "expires_in_minutes": 30,
                    "email_delivery_configured": False,
                }
            ),
        ):
            transport = ASGITransport(app=app)
            async with AsyncClient(
                transport=transport, base_url="http://test"
            ) as client:
                response = await client.post(
                    "/auth/password-reset/request",
                    json={"email": "nobody@example.com"},
                )

        assert response.status_code == 200
        assert response.json()["requested"] is True
        assert response.json()["dev_token"] is None
        assert response.json()["reset_url"] is None

    @pytest.mark.anyio
    async def test_request_reset_invalid_email(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(
            transport=transport, base_url="http://test"
        ) as client:
            response = await client.post(
                "/auth/password-reset/request",
                json={"email": "not-an-email"},
            )
        assert response.status_code == 422

    @pytest.mark.anyio
    async def test_confirm_reset_success(self):
        user = mock_user()
        with patch(
            "app.routers.auth_router.PasswordResetService"
            ".confirm_reset",
            new=AsyncMock(return_value=user),
        ) as mock_confirm:
            transport = ASGITransport(app=app)
            async with AsyncClient(
                transport=transport, base_url="http://test"
            ) as client:
                response = await client.post(
                    "/auth/password-reset/confirm",
                    json={
                        "token": "a" * 43,
                        "new_password": "new-strong-password",
                    },
                )

        assert response.status_code == 200
        assert response.json()["success"] is True
        assert response.json()["user_id"] == str(user.id)
        assert mock_confirm.await_args.args[2] == (
            "new-strong-password"
        )

    @pytest.mark.anyio
    async def test_confirm_reset_invalid_token(self):
        with patch(
            "app.routers.auth_router.PasswordResetService"
            ".confirm_reset",
            new=AsyncMock(
                side_effect=ValueError("Invalid or expired reset token")
            ),
        ):
            transport = ASGITransport(app=app)
            async with AsyncClient(
                transport=transport, base_url="http://test"
            ) as client:
                response = await client.post(
                    "/auth/password-reset/confirm",
                    json={
                        "token": "expired-token-value-12345",
                        "new_password": "new-strong-password",
                    },
                )

        assert response.status_code == 400
        assert response.json()["detail"] == (
            "Invalid or expired reset token"
        )

    @pytest.mark.anyio
    async def test_confirm_reset_weak_password(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(
            transport=transport, base_url="http://test"
        ) as client:
            response = await client.post(
                "/auth/password-reset/confirm",
                json={"token": "a" * 43, "new_password": "short"},
            )
        assert response.status_code == 422

    @pytest.mark.anyio
    async def test_confirm_reset_missing_token(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(
            transport=transport, base_url="http://test"
        ) as client:
            response = await client.post(
                "/auth/password-reset/confirm",
                json={"new_password": "new-strong-password"},
            )
        assert response.status_code == 422
