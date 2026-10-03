import pytest
from httpx import ASGITransport, AsyncClient
from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

from app.main import app
from app.core.enums import UserRole, ServiceRequestStatus
from app.models.user import User
from app.models.service_request import ServiceRequest
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


def mock_admin_user():
    return User(
        id=uuid4(),
        first_name="Admin",
        last_name="User",
        email="admin@example.com",
        phone_number="0780000001",
        password_hash="hashed",
        role=UserRole.ADMIN,
        is_active=True,
    )


def mock_request():
    return ServiceRequest(
        id=uuid4(),
        customer_id=uuid4(),
        address="Test Address",
        latitude=1.0,
        longitude=2.0,
        preferred_date="2024-01-01",
        notes="Test notes",
        status=ServiceRequestStatus.PENDING,
    )


class TestServiceRequestRouter:
    @pytest.mark.anyio
    async def test_create_request(self):
        user = mock_user()
        request = mock_request()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.service_request_router.ServiceRequestService.create", new=AsyncMock(return_value=request)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.post(
                        "/service-requests",
                        json={
                            "address": "Test Address",
                            "latitude": 1.0,
                            "longitude": 2.0,
                            "preferred_date": "2024-01-01",
                            "notes": "Test notes",
                            "items": [
                                {"service_category_id": str(uuid4()), "notes": "Item 1"}
                            ],
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 201
        assert response.json()["address"] == "Test Address"

    @pytest.mark.anyio
    async def test_create_request_invalid(self):
        user = mock_user()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.service_request_router.ServiceRequestService.create", new=AsyncMock(side_effect=ValueError("Service category not found"))):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.post(
                        "/service-requests",
                        json={
                            "address": "Test Address",
                            "latitude": 1.0,
                            "longitude": 2.0,
                            "preferred_date": "2024-01-01",
                            "notes": "Test notes",
                            "items": [
                                {"service_category_id": str(uuid4()), "notes": "Item 1"}
                            ],
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 400
        assert response.json()["detail"] == "Service category not found"

    @pytest.mark.anyio
    async def test_my_requests(self):
        user = mock_user()
        requests = [mock_request(), mock_request()]

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.service_request_router.ServiceRequestService.customer_list", new=AsyncMock(return_value=requests)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        "/service-requests/me",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert len(response.json()) == 2

    @pytest.mark.anyio
    async def test_get_request_owner(self):
        user = mock_user()
        request = mock_request()
        request.customer_id = user.id

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.service_request_router.ServiceRequestService.get", new=AsyncMock(return_value=request)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        f"/service-requests/{request.id}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["id"] == str(request.id)

    @pytest.mark.anyio
    async def test_get_request_not_owner_forbidden(self):
        user = mock_user()
        request = mock_request()
        request.customer_id = uuid4()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.service_request_router.ServiceRequestService.get", new=AsyncMock(return_value=request)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        f"/service-requests/{request.id}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 403

    @pytest.mark.anyio
    async def test_get_request_admin_access(self):
        user = mock_admin_user()
        request = mock_request()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.service_request_router.ServiceRequestService.get", new=AsyncMock(return_value=request)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        f"/service-requests/{request.id}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200

    @pytest.mark.anyio
    async def test_get_request_not_found(self):
        user = mock_user()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.service_request_router.ServiceRequestService.get", new=AsyncMock(side_effect=ValueError("Service request not found"))):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        f"/service-requests/{uuid4()}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 404

    @pytest.mark.anyio
    async def test_update_status(self):
        user = mock_user()
        request = mock_request()
        request.customer_id = user.id

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.service_request_router.ServiceRequestService.get", new=AsyncMock(return_value=request)), \
                 patch("app.routers.service_request_router.ServiceRequestService.update_status", new=AsyncMock(return_value=request)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        f"/service-requests/{request.id}/status",
                        json={"status": "IN_PROGRESS"},
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200

    @pytest.mark.anyio
    async def test_all_requests_admin(self):
        user = mock_admin_user()
        requests = [mock_request(), mock_request()]

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.service_request_router.ServiceRequestService.all", new=AsyncMock(return_value=requests)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        "/service-requests",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert len(response.json()) == 2

    @pytest.mark.anyio
    async def test_all_requests_customer_forbidden(self):
        user = mock_user()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.get(
                    "/service-requests",
                    headers={"Authorization": "Bearer token"},
                )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 403

def mock_provider_user():
    return User(
        id=uuid4(),
        first_name="Provider",
        last_name="User",
        email="provider@example.com",
        phone_number="0780000002",
        password_hash="hashed",
        role=UserRole.SERVICE_PROVIDER,
        is_active=True,
    )


class TestServiceRequestProviderAccess:
    @pytest.mark.anyio
    async def test_provider_can_view_assigned_request(self):
        user = mock_provider_user()
        provider = Mock()
        provider.id = uuid4()
        request = mock_request()
        assignment = Mock()
        assignment.service_request_id = request.id

        app.dependency_overrides[get_current_user] = lambda: user

        try:
            with patch(
                "app.routers.service_request_router.ProviderService.get_my_profile",
                new=AsyncMock(return_value=provider),
            ), patch(
                "app.services.service_request_service.ServiceRequestRepository.get_by_id",
                new=AsyncMock(return_value=request),
            ), patch(
                "app.services.service_request_service.AssignmentRepository.get_provider_assignments",
                new=AsyncMock(return_value=[assignment]),
            ):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        f"/service-requests/{request.id}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["id"] == str(request.id)

    @pytest.mark.anyio
    async def test_provider_cannot_view_unassigned_request(self):
        user = mock_provider_user()
        provider = Mock()
        provider.id = uuid4()
        request = mock_request()
        request.customer_id = uuid4()
        assignment = Mock()
        assignment.service_request_id = uuid4()

        app.dependency_overrides[get_current_user] = lambda: user

        try:
            with patch(
                "app.routers.service_request_router.ProviderService.get_my_profile",
                new=AsyncMock(return_value=provider),
            ), patch(
                "app.services.service_request_service.ServiceRequestRepository.get_by_id",
                new=AsyncMock(return_value=request),
            ), patch(
                "app.services.service_request_service.AssignmentRepository.get_provider_assignments",
                new=AsyncMock(return_value=[assignment]),
            ):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        f"/service-requests/{request.id}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 403
        assert response.json()["detail"] == (
            "You can only view requests assigned to you"
        )

    @pytest.mark.anyio
    async def test_provider_without_profile_cannot_view(self):
        user = mock_provider_user()
        request = mock_request()

        app.dependency_overrides[get_current_user] = lambda: user

        try:
            with patch(
                "app.services.service_request_service.ServiceRequestRepository.get_by_id",
                new=AsyncMock(return_value=request),
            ), patch(
                "app.routers.service_request_router.ProviderService.get_my_profile",
                new=AsyncMock(side_effect=ValueError("Provider profile not found")),
            ):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        f"/service-requests/{request.id}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 403
        assert response.json()["detail"] == (
            "Provider profile not found"
        )
