import pytest
from httpx import ASGITransport, AsyncClient
from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

from app.main import app
from app.core.enums import UserRole
from app.models.user import User
from app.schemas.auth_schema import RegisterRequest, LoginRequest
from app.core.dependencies import get_current_user


def mock_user():
    return User(
        id=uuid4(),
        first_name="Test",
        last_name="User",
        email="test@example.com",
        phone_number="0780000000",
        password_hash="hashed",
        role=UserRole.CUSTOMER,
        is_active=True,
    )


class TestAuthRouter:
    @pytest.mark.anyio
    async def test_register_success(self):
        user = mock_user()

        with patch("app.routers.auth_router.AuthService.register_user", new=AsyncMock(return_value=user)):
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/register",
                    json={
                        "first_name": "Test",
                        "last_name": "User",
                        "email": "test@example.com",
                        "phone_number": "0780000000",
                        "password": "StrongPassword123!",
                    },
                )

        assert response.status_code == 201
        assert response.json()["email"] == "test@example.com"

    @pytest.mark.anyio
    async def test_register_duplicate_email(self):
        with patch("app.routers.auth_router.AuthService.register_user", new=AsyncMock(side_effect=ValueError("Email is already registered"))):
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/register",
                    json={
                        "first_name": "Test",
                        "last_name": "User",
                        "email": "existing@example.com",
                        "phone_number": "0780000001",
                        "password": "StrongPassword123!",
                    },
                )

        assert response.status_code == 400
        assert response.json()["detail"] == "Email is already registered"

    @pytest.mark.anyio
    async def test_register_duplicate_phone(self):
        with patch("app.routers.auth_router.AuthService.register_user", new=AsyncMock(side_effect=ValueError("Phone number is already registered"))):
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/register",
                    json={
                        "first_name": "Test",
                        "last_name": "User",
                        "email": "new@example.com",
                        "phone_number": "0780000002",
                        "password": "StrongPassword123!",
                    },
                )

        assert response.status_code == 400
        assert response.json()["detail"] == "Phone number is already registered"

    @pytest.mark.anyio
    async def test_login_success(self):
        user = mock_user()
        token = "access_token"

        with patch("app.routers.auth_router.AuthService.login_user", new=AsyncMock(return_value=token)):
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/login",
                    json={
                        "email": "test@example.com",
                        "password": "StrongPassword123!",
                    },
                )

        assert response.status_code == 200
        assert response.json()["access_token"] == token
        assert response.json()["token_type"] == "bearer"

    @pytest.mark.anyio
    async def test_login_invalid_credentials(self):
        with patch("app.routers.auth_router.AuthService.login_user", new=AsyncMock(side_effect=ValueError("Invalid email or password"))):
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.post(
                    "/auth/login",
                    json={
                        "email": "test@example.com",
                        "password": "WrongPassword123!",
                    },
                )

        assert response.status_code == 401
        assert response.json()["detail"] == "Invalid email or password"

    @pytest.mark.anyio
    async def test_me_endpoint(self):
        user = mock_user()
        
        # Override the dependency
        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.get("/auth/me", headers={"Authorization": "Bearer token"})
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["email"] == "test@example.com"