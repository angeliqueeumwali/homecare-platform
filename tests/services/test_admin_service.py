from datetime import datetime
from decimal import Decimal
from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

import pytest

from app.models.provider_profile import ProviderProfile
from app.models.provider_location import ProviderLocation
from app.models.service_request import ServiceRequest
from app.models.quote import Quote
from app.services.admin_service import AdminService


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


@pytest.mark.asyncio
async def test_get_stats_aggregates_counts():
    db = Mock()
    stats = {
        "customers_total": 5,
        "providers_total": 3,
        "providers_pending_approval": 2,
        "requests_total": 9,
        "requests_pending": 1,
        "requests_in_progress": 2,
        "requests_completed": 5,
        "requests_cancelled": 1,
        "quotes_pending": 1,
        "quotes_approved": 3,
        "quotes_rejected": 1,
        "payments_total": 4,
        "payments_pending": 1,
        "payments_paid": 3,
        "reviews_total": 7,
        "issues_total": 2,
        "issues_open": 1,
        "assignments_total": 6,
        "notifications_total": 8,
    }

    with patch(
        "app.services.admin_service.AdminRepository.get_stats",
        new=AsyncMock(return_value=stats),
    ):
        result = await AdminService.get_stats(db)

    assert result == stats
    assert result["customers_total"] == 5
    assert result["issues_open"] == 1


@pytest.mark.asyncio
async def test_list_users_delegates_with_defaults():
    db = Mock()
    users = [Mock(), Mock()]
    repository_result = {
        "items": users,
        "total": 2,
        "page": 1,
        "page_size": 20,
        "total_pages": 1,
    }

    with patch(
        "app.services.admin_service.AdminRepository.list_users",
        new=AsyncMock(return_value=repository_result),
    ) as mock_list:
        result = await AdminService.list_users(db)

    assert result == repository_result
    kwargs = mock_list.await_args.kwargs
    assert kwargs["search"] is None
    assert kwargs["role"] is None
    assert kwargs["is_active"] is None
    assert kwargs["page"] is None
    assert kwargs["page_size"] is None


@pytest.mark.asyncio
async def test_list_users_forwards_filters():
    db = Mock()
    repository_result = {
        "items": [],
        "total": 0,
        "page": 2,
        "page_size": 10,
        "total_pages": 0,
    }

    with patch(
        "app.services.admin_service.AdminRepository.list_users",
        new=AsyncMock(return_value=repository_result),
    ) as mock_list:
        result = await AdminService.list_users(
            db,
            search="john",
            role="CUSTOMER",
            is_active=False,
            page=2,
            page_size=10,
        )

    assert result["total"] == 0
    kwargs = mock_list.await_args.kwargs
    assert kwargs["search"] == "john"
    assert kwargs["role"] == "CUSTOMER"
    assert kwargs["is_active"] is False


@pytest.mark.asyncio
async def test_list_providers_forwards_filters():
    db = Mock()
    repository_result = {
        "items": [mock_provider()],
        "total": 1,
        "page": 1,
        "page_size": 20,
        "total_pages": 1,
    }

    with patch(
        "app.services.admin_service.AdminRepository.list_providers",
        new=AsyncMock(return_value=repository_result),
    ) as mock_list:
        result = await AdminService.list_providers(
            db,
            search="Acme",
            approval_status="PENDING",
        )

    assert result["total"] == 1
    kwargs = mock_list.await_args.kwargs
    assert kwargs["search"] == "Acme"
    assert kwargs["approval_status"] == "PENDING"


@pytest.mark.asyncio
async def test_get_provider_details_returns_none_when_missing():
    db = Mock()

    with patch(
        "app.services.admin_service.AdminRepository.get_provider_details",
        new=AsyncMock(return_value=None),
    ):
        result = await AdminService.get_provider_details(db, uuid4())

    assert result is None


@pytest.mark.asyncio
async def test_get_provider_details_returns_related_ids():
    db = Mock()
    provider = mock_provider()
    category_ids = [uuid4(), uuid4()]
    assignment_ids = [uuid4()]
    review_ids = [uuid4()]
    location = ProviderLocation(
        id=uuid4(),
        provider_id=provider.id,
        latitude=-1.9403,
        longitude=30.0613,
        address="Kigali",
    )

    with patch(
        "app.services.admin_service.AdminRepository"
        ".get_provider_details",
        new=AsyncMock(return_value=provider),
    ), patch(
        "app.services.admin_service.AdminRepository"
        ".provider_service_ids",
        new=AsyncMock(return_value=category_ids),
    ), patch(
        "app.services.admin_service.AdminRepository"
        ".provider_assignment_ids",
        new=AsyncMock(return_value=assignment_ids),
    ), patch(
        "app.services.admin_service.AdminRepository"
        ".provider_review_ids",
        new=AsyncMock(return_value=review_ids),
    ), patch(
        "app.services.admin_service.ProviderRepository.get_location",
        new=AsyncMock(return_value=location),
    ):
        result = await AdminService.get_provider_details(
            db, provider.id
        )

    assert result["provider"] is provider
    assert result["service_category_ids"] == category_ids
    assert result["assignment_ids"] == assignment_ids
    assert result["review_ids"] == review_ids
    assert result["location"] is location


@pytest.mark.asyncio
async def test_list_service_requests_forwards_filters():
    db = Mock()
    repository_result = {
        "items": [Mock(spec=ServiceRequest)],
        "total": 1,
        "page": 1,
        "page_size": 20,
        "total_pages": 1,
    }

    with patch(
        "app.services.admin_service.AdminRepository"
        ".list_service_requests",
        new=AsyncMock(return_value=repository_result),
    ) as mock_list:
        result = await AdminService.list_service_requests(
            db, search="plumber", status="PENDING"
        )

    assert result["total"] == 1
    kwargs = mock_list.await_args.kwargs
    assert kwargs["search"] == "plumber"
    assert kwargs["status"] == "PENDING"


@pytest.mark.asyncio
async def test_list_quotes_forwards_filters():
    db = Mock()
    quote = Quote(
        id=uuid4(),
        service_request_id=uuid4(),
        service_request_item_id=uuid4(),
        provider_id=uuid4(),
        amount=Decimal("100.00"),
        currency="KES",
        status="PENDING",
    )
    repository_result = {
        "items": [quote],
        "total": 1,
        "page": 1,
        "page_size": 20,
        "total_pages": 1,
    }

    with patch(
        "app.services.admin_service.AdminRepository.list_quotes",
        new=AsyncMock(return_value=repository_result),
    ) as mock_list:
        result = await AdminService.list_quotes(
            db, status="PENDING", request_id=str(uuid4())
        )

    assert result["total"] == 1
    kwargs = mock_list.await_args.kwargs
    assert kwargs["status"] == "PENDING"
    assert kwargs["request_id"] is not None


@pytest.mark.asyncio
async def test_list_payments_forwards_filters():
    db = Mock()
    repository_result = {
        "items": [],
        "total": 0,
        "page": 1,
        "page_size": 20,
        "total_pages": 0,
    }

    with patch(
        "app.services.admin_service.AdminRepository.list_payments",
        new=AsyncMock(return_value=repository_result),
    ) as mock_list:
        result = await AdminService.list_payments(
            db, status="PAID", method="CARD"
        )

    assert result["total"] == 0
    kwargs = mock_list.await_args.kwargs
    assert kwargs["status"] == "PAID"
    assert kwargs["method"] == "CARD"


@pytest.mark.asyncio
async def test_list_reviews_paginates():
    db = Mock()
    repository_result = {
        "items": [],
        "total": 0,
        "page": 3,
        "page_size": 15,
        "total_pages": 0,
    }

    with patch(
        "app.services.admin_service.AdminRepository.list_reviews",
        new=AsyncMock(return_value=repository_result),
    ) as mock_list:
        result = await AdminService.list_reviews(
            db, page=3, page_size=15
        )

    assert result == repository_result
    assert mock_list.await_args.kwargs["page"] == 3


@pytest.mark.asyncio
async def test_list_issues_forwards_filters():
    db = Mock()
    repository_result = {
        "items": [],
        "total": 0,
        "page": 1,
        "page_size": 20,
        "total_pages": 0,
    }

    with patch(
        "app.services.admin_service.AdminRepository.list_issues",
        new=AsyncMock(return_value=repository_result),
    ) as mock_list:
        result = await AdminService.list_issues(db, status="OPEN")

    assert result["total"] == 0
    assert mock_list.await_args.kwargs["status"] == "OPEN"


@pytest.mark.asyncio
async def test_list_notifications_paginates():
    db = Mock()
    repository_result = {
        "items": [],
        "total": 0,
        "page": 1,
        "page_size": 20,
        "total_pages": 0,
    }

    with patch(
        "app.services.admin_service.AdminRepository.list_notifications",
        new=AsyncMock(return_value=repository_result),
    ):
        result = await AdminService.list_notifications(db)

    assert result == repository_result
