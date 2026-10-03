import pytest
from httpx import ASGITransport, AsyncClient
from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

from app.main import app
from app.core.enums import UserRole, QuoteStatus
from app.models.user import User
from app.models.quote import Quote
from app.models.provider_profile import ProviderProfile
from app.models.service_request import ServiceRequest
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
        first_name="Customer",
        last_name="User",
        email="customer@example.com",
        phone_number="0780000001",
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
        phone_number="0780000002",
        password_hash="hashed",
        role=UserRole.ADMIN,
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


def mock_quote():
    quote = Quote(
        id=uuid4(),
        service_request_id=uuid4(),
        service_request_item_id=uuid4(),
        provider_id=uuid4(),
        amount=100.00,
        currency="RWF",
        status=QuoteStatus.PENDING,
        description="Test quote",
    )
    quote.service_request = ServiceRequest(
        id=quote.service_request_id,
        customer_id=uuid4(),
    )
    return quote


class TestQuoteRouter:
    @pytest.mark.anyio
    async def test_create_quote_provider(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id
        quote = mock_quote()
        quote.provider_id = provider.id

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.quote_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)), \
                 patch("app.routers.quote_router.QuoteService.create", new=AsyncMock(return_value=quote)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.post(
                        "/quotes",
                        json={
                            "service_request_id": str(uuid4()),
                            "service_request_item_id": str(uuid4()),
                            "amount": 100.00,
                            "currency": "RWF",
                            "description": "Test quote",
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 201
        assert response.json()["amount"] == "100.0"

    @pytest.mark.anyio
    async def test_create_quote_invalid(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.quote_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)), \
                 patch("app.routers.quote_router.QuoteService.create", new=AsyncMock(side_effect=ValueError("Invalid service request item"))):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.post(
                        "/quotes",
                        json={
                            "service_request_id": str(uuid4()),
                            "service_request_item_id": str(uuid4()),
                            "amount": 100.00,
                            "currency": "RWF",
                            "description": "Test quote",
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 400
        assert response.json()["detail"] == "Invalid service request item"

    @pytest.mark.anyio
    async def test_request_quotes(self):
        user = mock_customer_user()
        request_id = uuid4()
        quotes = [mock_quote(), mock_quote()]

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.quote_router.QuoteService.list_for_request", new=AsyncMock(return_value=quotes)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        f"/quotes/request/{request_id}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert len(response.json()) == 2

    @pytest.mark.anyio
    async def test_update_quote_provider_owner(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id
        quote = mock_quote()
        quote.provider_id = provider.id
        updated_quote = mock_quote()
        updated_quote.status = QuoteStatus.APPROVED

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.quote_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)), \
                 patch("app.routers.quote_router.QuoteService.get", new=AsyncMock(return_value=quote)), \
                 patch("app.routers.quote_router.QuoteService.update_status", new=AsyncMock(return_value=updated_quote)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        f"/quotes/{quote.id}/status",
                        json={"status": "APPROVED"},
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["status"] == "APPROVED"

    @pytest.mark.anyio
    async def test_update_quote_provider_forbidden(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id
        quote = mock_quote()
        quote.provider_id = uuid4()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.quote_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)), \
                 patch("app.routers.quote_router.QuoteService.get", new=AsyncMock(return_value=quote)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        f"/quotes/{quote.id}/status",
                        json={"status": "APPROVED"},
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 403

    @pytest.mark.anyio
    async def test_update_quote_customer_owner(self):
        user = mock_customer_user()
        quote = mock_quote()
        quote.service_request.customer_id = user.id
        updated_quote = mock_quote()
        updated_quote.status = QuoteStatus.REJECTED

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.quote_router.QuoteService.get", new=AsyncMock(return_value=quote)), \
                 patch("app.routers.quote_router.QuoteService.update_status", new=AsyncMock(return_value=updated_quote)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        f"/quotes/{quote.id}/status",
                        json={"status": "REJECTED"},
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["status"] == "REJECTED"

    @pytest.mark.anyio
    async def test_update_quote_admin(self):
        user = mock_admin_user()
        quote = mock_quote()
        updated_quote = mock_quote()
        updated_quote.status = QuoteStatus.APPROVED

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.quote_router.QuoteService.get", new=AsyncMock(return_value=quote)), \
                 patch("app.routers.quote_router.QuoteService.update_status", new=AsyncMock(return_value=updated_quote)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        f"/quotes/{quote.id}/status",
                        json={"status": "APPROVED"},
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200

    @pytest.mark.anyio
    async def test_update_quote_invalid_status(self):
        user = mock_provider_user()
        provider = mock_provider()
        provider.user_id = user.id
        quote = mock_quote()
        quote.provider_id = provider.id

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.quote_router.ProviderService.get_my_profile", new=AsyncMock(return_value=provider)), \
                 patch("app.routers.quote_router.QuoteService.get", new=AsyncMock(return_value=quote)), \
                 patch("app.routers.quote_router.QuoteService.update_status", new=AsyncMock(side_effect=ValueError("Invalid quote status"))):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        f"/quotes/{quote.id}/status",
                        json={"status": "INVALID"},
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 400
        assert response.json()["detail"] == "Invalid quote status"