import pytest
from httpx import ASGITransport, AsyncClient
from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

from app.main import app
from app.core.enums import UserRole
from app.models.user import User
from app.schemas.user_schema import UserUpdateRequest
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


class TestUserRouter:
    @pytest.mark.anyio
    async def test_get_profile(self):
        user = mock_user()
        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.get("/users/me", headers={"Authorization": "Bearer token"})
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["email"] == "test@example.com"

    @pytest.mark.anyio
    async def test_update_profile_names(self):
        user = mock_user()
        updated_user = User(
            id=user.id,
            first_name="Updated",
            last_name="Name",
            email=user.email,
            phone_number=user.phone_number,
            password_hash=user.password_hash,
            role=user.role,
            is_active=user.is_active,
        )

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.user_router.UserService.update_user", new=AsyncMock(return_value=updated_user)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        "/users/me",
                        json={
                            "first_name": "Updated",
                            "last_name": "Name",
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["first_name"] == "Updated"
        assert response.json()["last_name"] == "Name"

    @pytest.mark.anyio
    async def test_update_profile_phone(self):
        user = mock_user()
        updated_user = User(
            id=user.id,
            first_name=user.first_name,
            last_name=user.last_name,
            email=user.email,
            phone_number="0780000001",
            password_hash=user.password_hash,
            role=user.role,
            is_active=user.is_active,
        )

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.user_router.UserService.update_user", new=AsyncMock(return_value=updated_user)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        "/users/me",
                        json={
                            "phone_number": "0780000001",
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["phone_number"] == "0780000001"

    @pytest.mark.anyio
    async def test_update_profile_duplicate_phone(self):
        user = mock_user()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.user_router.UserService.update_user", new=AsyncMock(side_effect=ValueError("Phone number is already registered"))):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        "/users/me",
                        json={
                            "phone_number": "0780000001",
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 400
        assert response.json()["detail"] == "Phone number is already registered"

    @pytest.mark.anyio
    async def test_update_profile_no_auth(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.patch(
                "/users/me",
                json={
                    "first_name": "Updated",
                },
            )

        assert response.status_code == 401