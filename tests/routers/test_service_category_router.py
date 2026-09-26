import pytest
from httpx import ASGITransport, AsyncClient
from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

from app.main import app
from app.core.enums import UserRole
from app.models.user import User
from app.models.service_category import ServiceCategory
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


def mock_customer_user():
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


def mock_category():
    return ServiceCategory(
        id=uuid4(),
        name="Cleaning",
        description="Cleaning services",
        is_active=True,
    )


class TestServiceCategoryRouter:
    @pytest.mark.anyio
    async def test_list_categories(self):
        categories = [mock_category(), mock_category()]

        with patch("app.routers.service_category_router.ServiceCategoryService.list", new=AsyncMock(return_value=categories)):
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.get("/service-categories")

        assert response.status_code == 200
        assert len(response.json()) == 2

    @pytest.mark.anyio
    async def test_get_category(self):
        category = mock_category()

        with patch("app.routers.service_category_router.ServiceCategoryService.get", new=AsyncMock(return_value=category)):
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.get(f"/service-categories/{category.id}")

        assert response.status_code == 200
        assert response.json()["name"] == "Cleaning"

    @pytest.mark.anyio
    async def test_get_category_not_found(self):
        with patch("app.routers.service_category_router.ServiceCategoryService.get", new=AsyncMock(side_effect=ValueError("Service category not found"))):
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                response = await client.get(f"/service-categories/{uuid4()}")

        assert response.status_code == 404
        assert response.json()["detail"] == "Service category not found"

    @pytest.mark.anyio
    async def test_create_category_admin(self):
        category = mock_category()

        app.dependency_overrides[get_current_user] = lambda: mock_admin_user()
        
        try:
            with patch("app.routers.service_category_router.ServiceCategoryService.create", new=AsyncMock(return_value=category)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.post(
                        "/service-categories",
                        json={
                            "name": "Cleaning",
                            "description": "Cleaning services",
                        },
                        headers={"Authorization": "Bearer admin_token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 201
        assert response.json()["name"] == "Cleaning"

    @pytest.mark.anyio
    async def test_create_category_duplicate(self):
        app.dependency_overrides[get_current_user] = lambda: mock_admin_user()
        
        try:
            with patch("app.routers.service_category_router.ServiceCategoryService.create", new=AsyncMock(side_effect=ValueError("Service category already exists"))):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.post(
                        "/service-categories",
                        json={
                            "name": "Cleaning",
                            "description": "Cleaning services",
                        },
                        headers={"Authorization": "Bearer admin_token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 400
        assert response.json()["detail"] == "Service category already exists"

    @pytest.mark.anyio
    async def test_update_category_admin(self):
        category = mock_category()
        updated_category = ServiceCategory(
            id=category.id,
            name="Updated Cleaning",
            description="Updated description",
            is_active=False,
        )

        app.dependency_overrides[get_current_user] = lambda: mock_admin_user()
        
        try:
            with patch("app.routers.service_category_router.ServiceCategoryService.get", new=AsyncMock(return_value=category)), \
                 patch("app.routers.service_category_router.ServiceCategoryService.update", new=AsyncMock(return_value=updated_category)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        f"/service-categories/{category.id}",
                        json={
                            "name": "Updated Cleaning",
                            "description": "Updated description",
                            "is_active": False,
                        },
                        headers={"Authorization": "Bearer admin_token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["name"] == "Updated Cleaning"
        assert response.json()["is_active"] is False

    @pytest.mark.anyio
    async def test_delete_category_admin(self):
        category = mock_category()

        app.dependency_overrides[get_current_user] = lambda: mock_admin_user()
        
        try:
            with patch("app.routers.service_category_router.ServiceCategoryService.get", new=AsyncMock(return_value=category)), \
                 patch("app.routers.service_category_router.ServiceCategoryService.delete", new=AsyncMock()):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.delete(
                        f"/service-categories/{category.id}",
                        headers={"Authorization": "Bearer admin_token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 204

    @pytest.mark.anyio
    async def test_delete_category_not_found(self):
        app.dependency_overrides[get_current_user] = lambda: mock_admin_user()
        
        try:
            with patch("app.routers.service_category_router.ServiceCategoryService.get", new=AsyncMock(side_effect=ValueError("Service category not found"))):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.delete(
                        f"/service-categories/{uuid4()}",
                        headers={"Authorization": "Bearer admin_token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 400
        assert response.json()["detail"] == "Service category not found"