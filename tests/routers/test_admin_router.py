import pytest
from datetime import datetime
from decimal import Decimal
from httpx import ASGITransport, AsyncClient
from unittest.mock import AsyncMock, patch
from uuid import uuid4

from app.main import app
from app.core.enums import UserRole
from app.models.user import User
from app.models.provider_profile import ProviderProfile
from app.models.service_request import ServiceRequest
from app.models.quote import Quote
from app.models.payment import Payment
from app.models.review import Review
from app.models.issue import Issue
from app.models.notification import Notification
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


def mock_provider():
    return ProviderProfile(
        id=uuid4(),
        user_id=uuid4(),
        business_name="Test Business",
        bio="Test Bio",
        is_available=True,
        approval_status="APPROVED",
        average_rating=None,
        created_at=datetime.utcnow(),
    )


def stats_payload():
    return {
        "customers_total": 3,
        "providers_total": 2,
        "providers_pending_approval": 1,
        "requests_total": 10,
        "requests_pending": 2,
        "requests_in_progress": 3,
        "requests_completed": 4,
        "requests_cancelled": 1,
        "quotes_pending": 1,
        "quotes_approved": 2,
        "quotes_rejected": 0,
        "payments_total": 5,
        "payments_pending": 1,
        "payments_paid": 4,
        "reviews_total": 6,
        "issues_total": 2,
        "issues_open": 1,
        "assignments_total": 7,
        "notifications_total": 9,
    }


class TestAdminRouter:
    @pytest.mark.anyio
    async def test_stats_requires_admin(self):
        user = mock_user(role=UserRole.CUSTOMER)
        app.dependency_overrides[get_current_user] = lambda: user
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(
                transport=transport, base_url="http://test"
            ) as client:
                response = await client.get(
                    "/admin/stats",
                    headers={"Authorization": "Bearer token"},
                )
        finally:
            app.dependency_overrides.clear()
        assert response.status_code == 403

    @pytest.mark.anyio
    async def test_stats_provider_forbidden(self):
        user = mock_user(role=UserRole.SERVICE_PROVIDER)
        app.dependency_overrides[get_current_user] = lambda: user
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(
                transport=transport, base_url="http://test"
            ) as client:
                response = await client.get(
                    "/admin/stats",
                    headers={"Authorization": "Bearer token"},
                )
        finally:
            app.dependency_overrides.clear()
        assert response.status_code == 403

    @pytest.mark.anyio
    async def test_stats(self):
        admin = mock_user(role=UserRole.ADMIN)
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.routers.admin_router.AdminService.get_stats",
                new=AsyncMock(return_value=stats_payload()),
            ):
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.get(
                        "/admin/stats",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        data = response.json()
        assert data["customers_total"] == 3
        assert data["providers_pending_approval"] == 1
        assert data["issues_open"] == 1
        assert data["notifications_total"] == 9

    @pytest.mark.anyio
    async def test_list_users_pagination(self):
        admin = mock_user(role=UserRole.ADMIN)
        users = [mock_user(), mock_user()]
        result = {
            "items": users,
            "total": 2,
            "page": 1,
            "page_size": 20,
            "total_pages": 1,
        }
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.routers.admin_router.AdminService.list_users",
                new=AsyncMock(return_value=result),
            ) as mock_list:
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.get(
                        "/admin/users/list?page=1&page_size=20",
                        headers={"Authorization": "Bearer token"},
                    )
                assert mock_list.await_args.kwargs["page"] == 1
                assert mock_list.await_args.kwargs["page_size"] == 20
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 2
        assert data["total_pages"] == 1
        assert len(data["items"]) == 2
        assert data["items"][0]["email"] == "test@example.com"

    @pytest.mark.anyio
    async def test_list_users_filters_and_search(self):
        admin = mock_user(role=UserRole.ADMIN)
        result = {"items": [], "total": 0, "page": 1, "page_size": 20, "total_pages": 0}
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.routers.admin_router.AdminService.list_users",
                new=AsyncMock(return_value=result),
            ) as mock_list:
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.get(
                        "/admin/users/list"
                        "?search=john&role=CUSTOMER&is_active=true"
                        "&page=2&page_size=10",
                        headers={"Authorization": "Bearer token"},
                    )
                kwargs = mock_list.await_args.kwargs
                assert kwargs["search"] == "john"
                assert kwargs["role"] == "CUSTOMER"
                assert kwargs["is_active"] is True
                assert kwargs["page"] == 2
                assert kwargs["page_size"] == 10
        finally:
            app.dependency_overrides.clear()
        assert response.status_code == 200
        assert response.json()["total"] == 0

    @pytest.mark.anyio
    async def test_list_users_rejects_non_admin(self):
        user = mock_user()
        app.dependency_overrides[get_current_user] = lambda: user
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(
                transport=transport, base_url="http://test"
            ) as client:
                response = await client.get(
                    "/admin/users/list",
                    headers={"Authorization": "Bearer token"},
                )
        finally:
            app.dependency_overrides.clear()
        assert response.status_code == 403

    @pytest.mark.anyio
    async def test_user_detail(self):
        admin = mock_user(role=UserRole.ADMIN)
        target = mock_user()
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.repositories.user_repository.UserRepository.get_by_id",
                new=AsyncMock(return_value=target),
            ):
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.get(
                        f"/admin/users/{target.id}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["id"] == str(target.id)

    @pytest.mark.anyio
    async def test_user_detail_not_found(self):
        admin = mock_user(role=UserRole.ADMIN)
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.repositories.user_repository.UserRepository.get_by_id",
                new=AsyncMock(return_value=None),
            ):
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.get(
                        f"/admin/users/{uuid4()}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()
        assert response.status_code == 404

    @pytest.mark.anyio
    async def test_deactivate_user(self):
        admin = mock_user(role=UserRole.ADMIN)
        target = mock_user()
        deactivated = mock_user()
        deactivated.id = target.id
        deactivated.is_active = False
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.repositories.user_repository.UserRepository.get_by_id",
                new=AsyncMock(return_value=target),
            ), patch(
                "app.routers.admin_router.AdminService.set_user_active",
                new=AsyncMock(return_value=deactivated),
            ):
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.patch(
                        f"/admin/users/{target.id}/status?is_active=false",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["is_active"] is False

    @pytest.mark.anyio
    async def test_cannot_deactivate_self(self):
        admin = mock_user(role=UserRole.ADMIN)
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(
                transport=transport, base_url="http://test"
            ) as client:
                response = await client.patch(
                    f"/admin/users/{admin.id}/status?is_active=false",
                    headers={"Authorization": "Bearer token"},
                )
        finally:
            app.dependency_overrides.clear()
        assert response.status_code == 400

    @pytest.mark.anyio
    async def test_list_providers(self):
        admin = mock_user(role=UserRole.ADMIN)
        providers = [mock_provider(), mock_provider()]
        result = {
            "items": providers,
            "total": 2,
            "page": 1,
            "page_size": 20,
            "total_pages": 1,
        }
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.routers.admin_router.AdminService.list_providers",
                new=AsyncMock(return_value=result),
            ) as mock_list:
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.get(
                        "/admin/providers/list"
                        "?search=Acme&approval_status=PENDING"
                        "&page=1&page_size=20",
                        headers={"Authorization": "Bearer token"},
                    )
                kwargs = mock_list.await_args.kwargs
                assert kwargs["search"] == "Acme"
                assert kwargs["approval_status"] == "PENDING"
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 2
        assert data["items"][0]["business_name"] == "Test Business"

    @pytest.mark.anyio
    async def test_provider_detail(self):
        admin = mock_user(role=UserRole.ADMIN)
        provider = mock_provider()
        details = {
            "provider": provider,
            "service_category_ids": [uuid4(), uuid4()],
            "assignment_ids": [uuid4()],
            "review_ids": [],
            "location": None,
        }
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.routers.admin_router.AdminService.get_provider_details",
                new=AsyncMock(return_value=details),
            ):
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.get(
                        f"/admin/providers/{provider.id}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        data = response.json()
        assert data["provider"]["id"] == str(provider.id)
        assert len(data["service_category_ids"]) == 2
        assert data["location"] is None

    @pytest.mark.anyio
    async def test_provider_detail_not_found(self):
        admin = mock_user(role=UserRole.ADMIN)
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.routers.admin_router.AdminService.get_provider_details",
                new=AsyncMock(return_value=None),
            ):
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.get(
                        f"/admin/providers/{uuid4()}",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()
        assert response.status_code == 404

    @pytest.mark.anyio
    async def test_list_service_requests(self):
        admin = mock_user(role=UserRole.ADMIN)
        request = ServiceRequest(
            id=uuid4(),
            customer_id=uuid4(),
            address="Test Address",
            latitude=1.0,
            longitude=2.0,
            status="PENDING",
            created_at=datetime.utcnow(),
        )
        result = {
            "items": [request],
            "total": 1,
            "page": 1,
            "page_size": 20,
            "total_pages": 1,
        }
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.routers.admin_router.AdminService.list_service_requests",
                new=AsyncMock(return_value=result),
            ) as mock_list:
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.get(
                        "/admin/service-requests"
                        "?status=PENDING&search=Address"
                        "&page=1&page_size=20",
                        headers={"Authorization": "Bearer token"},
                    )
                kwargs = mock_list.await_args.kwargs
                assert kwargs["status"] == "PENDING"
                assert kwargs["search"] == "Address"
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert data["items"][0]["address"] == "Test Address"

    @pytest.mark.anyio
    async def test_list_quotes(self):
        admin = mock_user(role=UserRole.ADMIN)
        quote = Quote(
            id=uuid4(),
            service_request_id=uuid4(),
            service_request_item_id=uuid4(),
            provider_id=uuid4(),
            amount=Decimal("120.50"),
            currency="KES",
            status="PENDING",
            description="Quote desc",
            created_at=datetime.utcnow(),
        )
        result = {
            "items": [quote],
            "total": 1,
            "page": 1,
            "page_size": 20,
            "total_pages": 1,
        }
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.routers.admin_router.AdminService.list_quotes",
                new=AsyncMock(return_value=result),
            ):
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.get(
                        "/admin/quotes?status=PENDING&page=1&page_size=20",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        data = response.json()
        assert data["items"][0]["amount"] == "120.50"
        assert data["items"][0]["currency"] == "KES"

    @pytest.mark.anyio
    async def test_list_payments(self):
        admin = mock_user(role=UserRole.ADMIN)
        payment = Payment(
            id=uuid4(),
            service_request_id=uuid4(),
            quote_id=uuid4(),
            customer_id=uuid4(),
            amount=Decimal("99.99"),
            currency="KES",
            payment_method="MOBILE_MONEY",
            status="PAID",
            transaction_reference="TXN123",
            created_at=datetime.utcnow(),
        )
        result = {
            "items": [payment],
            "total": 1,
            "page": 1,
            "page_size": 20,
            "total_pages": 1,
        }
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.routers.admin_router.AdminService.list_payments",
                new=AsyncMock(return_value=result),
            ) as mock_list:
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.get(
                        "/admin/payments?status=PAID&method=MOBILE_MONEY"
                        "&page=1&page_size=20",
                        headers={"Authorization": "Bearer token"},
                    )
                kwargs = mock_list.await_args.kwargs
                assert kwargs["method"] == "MOBILE_MONEY"
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        data = response.json()
        assert data["items"][0]["transaction_reference"] == "TXN123"

    @pytest.mark.anyio
    async def test_list_reviews(self):
        admin = mock_user(role=UserRole.ADMIN)
        review = Review(
            id=uuid4(),
            customer_id=uuid4(),
            provider_id=uuid4(),
            assignment_id=uuid4(),
            rating=5,
            comment="Great",
            created_at=datetime.utcnow(),
        )
        result = {
            "items": [review],
            "total": 1,
            "page": 1,
            "page_size": 20,
            "total_pages": 1,
        }
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.routers.admin_router.AdminService.list_reviews",
                new=AsyncMock(return_value=result),
            ):
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.get(
                        "/admin/reviews?page=1&page_size=20",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["items"][0]["rating"] == 5

    @pytest.mark.anyio
    async def test_list_issues(self):
        admin = mock_user(role=UserRole.ADMIN)
        issue = Issue(
            id=uuid4(),
            service_request_id=uuid4(),
            assignment_id=None,
            reported_by_id=uuid4(),
            title="Broken tap",
            description="details",
            status="OPEN",
            resolution=None,
            created_at=datetime.utcnow(),
        )
        result = {
            "items": [issue],
            "total": 1,
            "page": 1,
            "page_size": 20,
            "total_pages": 1,
        }
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.routers.admin_router.AdminService.list_issues",
                new=AsyncMock(return_value=result),
            ) as mock_list:
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.get(
                        "/admin/issues?status=OPEN&page=1&page_size=20",
                        headers={"Authorization": "Bearer token"},
                    )
                assert mock_list.await_args.kwargs["status"] == "OPEN"
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["items"][0]["title"] == "Broken tap"

    @pytest.mark.anyio
    async def test_list_notifications(self):
        admin = mock_user(role=UserRole.ADMIN)
        notification = Notification(
            id=uuid4(),
            user_id=uuid4(),
            notification_type="GENERAL",
            title="Hello",
            message="World",
            is_read=False,
            created_at=datetime.utcnow(),
        )
        result = {
            "items": [notification],
            "total": 1,
            "page": 1,
            "page_size": 20,
            "total_pages": 1,
        }
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.routers.admin_router.AdminService.list_notifications",
                new=AsyncMock(return_value=result),
            ):
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.get(
                        "/admin/notifications?page=1&page_size=20",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        data = response.json()
        assert data["items"][0]["is_read"] is False
        assert data["items"][0]["title"] == "Hello"
