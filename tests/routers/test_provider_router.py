import pytest
from httpx import ASGITransport, AsyncClient
from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

from app.main import app
from app.core.enums import UserRole
from app.models.user import User
from app.models.provider_profile import ProviderProfile
from app.models.provider_service import ProviderService
from app.models.provider_location import ProviderLocation
from app.core.dependencies import get_current_user


def mock_provider_user():
    return User(
        id=uuid4(),
        first_name="Provider",
        last_name="User",
        email="provider@example.com",
        phone_number="0780000000",
        password_hash="hashed",
        role=UserRole.SERVICE_PROVIDER,
        is_active=True,
    )


def mock_customer_user():
    return User(
        id=uuid4(),
        first_name="Test",
        last_name="User",
        email="test@example.com",
        phone_number="0780000001",
        password_hash="hashed",
        role=UserRole.CUSTOMER,
        is_active=True,
    )


def mock_provider():
    return ProviderProfile(
        id=uuid4(),
        user_id=uuid4(),
        business_name="Test Business",
        bio="Test Bio",
        is_available=True,
        approval_status="APPROVED",
        average_rating=None,
    )


class TestProviderRouter:
    @pytest.mark.anyio
    async def test_create_profile(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.provider_router.ProviderService.get_my_profile", new=AsyncMock(side_effect=ValueError("Provider profile not found"))), \
                 patch("app.routers.provider_router.ProviderService.create_profile", new=AsyncMock(return_value=provider)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.post(
                        "/providers/profile",
                        json={
                            "business_name": "Test Business",
                            "bio": "Test Bio",
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 201
        assert response.json()["business_name"] == "Test Business"

    @pytest.mark.anyio
    async def test_create_profile_already_exists(self):
        user = mock_provider_user()
        existing_provider = mock_provider()
        existing_provider.user_id = user.id

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.provider_router.ProviderService.create_profile", new=AsyncMock(side_effect=ValueError("Provider profile already exists"))):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.post(
                        "/providers/profile",
                        json={
                            "business_name": "Test Business",
                            "bio": "Test Bio",
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 400
        assert response.json()["detail"] == "Provider profile already exists"

    @pytest.mark.anyio
    async def test_get_profile(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.provider_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        "/providers/me",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["business_name"] == "Test Business"

    @pytest.mark.anyio
    async def test_get_profile_not_found(self):
        user = mock_provider_user()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.provider_router.ProviderService.get_my_profile", new=AsyncMock(side_effect=ValueError("Provider profile not found"))):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        "/providers/me",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 404
        assert response.json()["detail"] == "Provider profile not found"

    @pytest.mark.anyio
    async def test_update_profile(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id
        updated_provider = ProviderProfile(
            id=provider.id,
            user_id=provider.user_id,
            business_name="Updated Business",
            bio="Updated Bio",
            is_available=False,
            approval_status="APPROVED",
            average_rating=None,
        )

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.provider_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)), \
                 patch("app.routers.provider_router.ProviderService.update_profile", new=AsyncMock(return_value=updated_provider)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        "/providers/me",
                        json={
                            "business_name": "Updated Business",
                            "bio": "Updated Bio",
                            "is_available": False,
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["business_name"] == "Updated Business"
        assert response.json()["is_available"] is False

    @pytest.mark.anyio
    async def test_add_service(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id
        service = ProviderService(
            id=uuid4(),
            provider_id=provider.id,
            service_category_id=uuid4(),
            is_active=True,
        )

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.provider_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)), \
                 patch("app.routers.provider_router.ProviderService.add_service", new=AsyncMock(return_value=service)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.post(
                        "/providers/me/services",
                        json={
                            "service_category_id": str(uuid4()),
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 201
        assert "id" in response.json()

    @pytest.mark.anyio
    async def test_list_services(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id
        services = [ProviderService(
            id=uuid4(),
            provider_id=provider.id,
            service_category_id=uuid4(),
            is_active=True,
        ), ProviderService(
            id=uuid4(),
            provider_id=provider.id,
            service_category_id=uuid4(),
            is_active=True,
        )]

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.provider_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)), \
                 patch("app.routers.provider_router.ProviderService.get_services", new=AsyncMock(return_value=services)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        "/providers/me/services",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert len(response.json()) == 2

    @pytest.mark.anyio
    async def test_remove_service(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.provider_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)), \
                 patch("app.routers.provider_router.ProviderService.remove_service", new=AsyncMock()):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.delete(
                        f"/providers/me/services/{uuid4()}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 204

    @pytest.mark.anyio
    async def test_set_location(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id
        location = ProviderLocation(
            id=uuid4(),
            provider_id=provider.id,
            latitude=-1.9441,
            longitude=30.0619,
            address="Test Address",
        )

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.provider_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)), \
                 patch("app.routers.provider_router.ProviderService.set_location", new=AsyncMock(return_value=location)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.put(
                        "/providers/me/location",
                        json={
                            "latitude": -1.9441,
                            "longitude": 30.0619,
                            "address": "Test Address",
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["latitude"] == -1.9441

    @pytest.mark.anyio
    async def test_match_providers(self):
        provider1 = mock_provider()
        provider1.business_name = "Provider 1"
        provider1.id = uuid4()
        provider1.location = ProviderLocation(
            provider_id=provider1.id,
            latitude=-1.9500,
            longitude=30.0500,
        )

        mock_result = [
            {
                "provider": provider1,
                "distance_km": 1.5,
            }
        ]

        app.dependency_overrides[get_current_user] = lambda: mock_customer_user()
        
        try:
            with patch("app.routers.provider_router.MatchingService.find_nearest_providers", new=AsyncMock(return_value=mock_result)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        f"/providers/match?service_category_id={uuid4()}&latitude=-1.9441&longitude=30.0619",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert len(response.json()) == 1
        assert response.json()[0]["business_name"] == "Provider 1"