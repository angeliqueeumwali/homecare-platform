import pytest
from httpx import ASGITransport, AsyncClient
from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

from app.main import app
from app.core.enums import UserRole, AssignmentStatus
from app.models.user import User
from app.models.assignment import Assignment
from app.models.provider_profile import ProviderProfile
from app.models.service_request import ServiceRequest
from app.core.dependencies import get_current_user


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
        first_name="Customer",
        last_name="User",
        email="customer@example.com",
        phone_number="0780000002",
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
    )


def mock_assignment():
    assignment = Assignment(
        id=uuid4(),
        service_request_id=uuid4(),
        service_request_item_id=uuid4(),
        provider_id=uuid4(),
        status=AssignmentStatus.PENDING,
    )
    assignment.service_request = ServiceRequest(
        id=assignment.service_request_id,
        customer_id=uuid4(),
    )
    return assignment


class TestAssignmentRouter:
    @pytest.mark.anyio
    async def test_create_assignment_admin(self):
        assignment = mock_assignment()

        app.dependency_overrides[get_current_user] = lambda: mock_admin_user()
        
        try:
            with patch("app.routers.assignment_router.AssignmentService.create", new=AsyncMock(return_value=assignment)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.post(
                        "/assignments",
                        json={
                            "service_request_id": str(uuid4()),
                            "service_request_item_id": str(uuid4()),
                            "provider_id": str(uuid4()),
                        },
                        headers={"Authorization": "Bearer admin_token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 201
        assert "id" in response.json()

    @pytest.mark.anyio
    async def test_create_assignment_invalid(self):
        app.dependency_overrides[get_current_user] = lambda: mock_admin_user()
        
        try:
            with patch("app.routers.assignment_router.AssignmentService.create", new=AsyncMock(side_effect=ValueError("Service request or item not found"))):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.post(
                        "/assignments",
                        json={
                            "service_request_id": str(uuid4()),
                            "service_request_item_id": str(uuid4()),
                            "provider_id": str(uuid4()),
                        },
                        headers={"Authorization": "Bearer admin_token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 400
        assert response.json()["detail"] == "Service request or item not found"

    @pytest.mark.anyio
    async def test_my_assignments_provider(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id
        assignments = [mock_assignment(), mock_assignment()]

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.assignment_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)), \
                 patch("app.routers.assignment_router.AssignmentService.provider_list", new=AsyncMock(return_value=assignments)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        "/assignments/me",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert len(response.json()) == 2

    @pytest.mark.anyio
    async def test_get_assignment_admin(self):
        user = mock_admin_user()
        assignment = mock_assignment()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.assignment_router.AssignmentService.get", new=AsyncMock(return_value=assignment)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        f"/assignments/{assignment.id}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["id"] == str(assignment.id)

    @pytest.mark.anyio
    async def test_get_assignment_provider_owner(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id
        assignment = mock_assignment()
        assignment.provider_id = provider.id

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.assignment_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)), \
                 patch("app.routers.assignment_router.AssignmentService.get", new=AsyncMock(return_value=assignment)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        f"/assignments/{assignment.id}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200

    @pytest.mark.anyio
    async def test_get_assignment_provider_forbidden(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id
        assignment = mock_assignment()
        assignment.provider_id = uuid4()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.assignment_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)), \
                 patch("app.routers.assignment_router.AssignmentService.get", new=AsyncMock(return_value=assignment)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        f"/assignments/{assignment.id}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 403

    @pytest.mark.anyio
    async def test_get_assignment_customer_owner(self):
        user = mock_customer_user()
        assignment = mock_assignment()
        assignment.service_request.customer_id = user.id

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.assignment_router.AssignmentService.get", new=AsyncMock(return_value=assignment)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        f"/assignments/{assignment.id}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200

    @pytest.mark.anyio
    async def test_get_assignment_customer_forbidden(self):
        user = mock_customer_user()
        assignment = mock_assignment()
        assignment.service_request.customer_id = uuid4()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.assignment_router.AssignmentService.get", new=AsyncMock(return_value=assignment)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        f"/assignments/{assignment.id}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 403

    @pytest.mark.anyio
    async def test_get_assignment_not_found(self):
        user = mock_admin_user()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.assignment_router.AssignmentService.get", new=AsyncMock(side_effect=ValueError("Assignment not found"))):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        f"/assignments/{uuid4()}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 404

    @pytest.mark.anyio
    async def test_update_assignment_provider(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id
        assignment = mock_assignment()
        assignment.provider_id = provider.id
        updated_assignment = mock_assignment()
        updated_assignment.status = AssignmentStatus.ACCEPTED

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.assignment_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)), \
                 patch("app.routers.assignment_router.AssignmentService.get", new=AsyncMock(return_value=assignment)), \
                 patch("app.routers.assignment_router.AssignmentService.update_status", new=AsyncMock(return_value=updated_assignment)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        f"/assignments/{assignment.id}/status",
                        json={"status": "ACCEPTED"},
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["status"] == "ACCEPTED"

    @pytest.mark.anyio
    async def test_update_assignment_invalid_status(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id
        assignment = mock_assignment()
        assignment.provider_id = provider.id

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.assignment_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)), \
                 patch("app.routers.assignment_router.AssignmentService.get", new=AsyncMock(return_value=assignment)), \
                 patch("app.routers.assignment_router.AssignmentService.update_status", new=AsyncMock(side_effect=ValueError("Invalid assignment status"))):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        f"/assignments/{assignment.id}/status",
                        json={"status": "INVALID"},
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 400
        assert response.json()["detail"] == "Invalid assignment status"