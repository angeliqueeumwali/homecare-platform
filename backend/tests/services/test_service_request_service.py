from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

import pytest

from app.core.enums import ServiceRequestItemStatus, ServiceRequestStatus
from app.models.service_request import ServiceRequest
from app.models.service_request_item import ServiceRequestItem
from app.models.service_category import ServiceCategory
from app.services.service_request_service import ServiceRequestService


def create_test_request():
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


def create_test_item():
    return ServiceRequestItem(
        id=uuid4(),
        service_request_id=uuid4(),
        service_category_id=uuid4(),
        status=ServiceRequestItemStatus.PENDING,
        notes="Test item",
    )


def create_test_category():
    return ServiceCategory(
        id=uuid4(),
        name="Cleaning",
        description="Cleaning services",
        is_active=True,
    )


class MockCreateData:
    def __init__(self):
        self.address = "Test Address"
        self.latitude = 1.0
        self.longitude = 2.0
        self.preferred_date = "2024-01-01"
        self.notes = "Test notes"
        self.items = [MockItem(uuid4()), MockItem(uuid4())]


class MockItem:
    def __init__(self, category_id):
        self.service_category_id = category_id
        self.notes = "Test item"


@pytest.mark.asyncio
async def test_create_service_request():
    db = Mock()
    customer_id = uuid4()
    data = MockCreateData()
    category = create_test_category()
    request = create_test_request()

    with patch(
        "app.services.service_request_service.ServiceCategoryRepository.get_by_id",
        new=AsyncMock(return_value=category),
    ), patch(
        "app.services.service_request_service.ServiceRequestRepository.create",
        new=AsyncMock(return_value=request),
    ) as mock_create:
        result = await ServiceRequestService.create(db, customer_id, data)

    assert result == request
    assert mock_create.awaited_once()


@pytest.mark.asyncio
async def test_create_service_request_category_not_available():
    db = Mock()
    customer_id = uuid4()
    data = MockCreateData()
    category = create_test_category()
    category.is_active = False

    with patch(
        "app.services.service_request_service.ServiceCategoryRepository.get_by_id",
        new=AsyncMock(return_value=category),
    ):
        with pytest.raises(ValueError, match="is not available"):
            await ServiceRequestService.create(db, customer_id, data)


@pytest.mark.asyncio
async def test_create_service_request_category_not_found():
    db = Mock()
    customer_id = uuid4()
    data = MockCreateData()

    with patch(
        "app.services.service_request_service.ServiceCategoryRepository.get_by_id",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError, match="is not available"):
            await ServiceRequestService.create(db, customer_id, data)


@pytest.mark.asyncio
async def test_get_service_request():
    db = Mock()
    request = create_test_request()

    with patch(
        "app.services.service_request_service.ServiceRequestRepository.get_by_id",
        new=AsyncMock(return_value=request),
    ):
        result = await ServiceRequestService.get(db, request.id)

    assert result == request


@pytest.mark.asyncio
async def test_get_service_request_not_found():
    db = Mock()

    with patch(
        "app.services.service_request_service.ServiceRequestRepository.get_by_id",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError, match="Service request not found"):
            await ServiceRequestService.get(db, uuid4())


@pytest.mark.asyncio
async def test_customer_list():
    db = Mock()
    customer_id = uuid4()
    requests = [create_test_request(), create_test_request()]

    with patch(
        "app.services.service_request_service.ServiceRequestRepository.get_customer_requests",
        new=AsyncMock(return_value=requests),
    ):
        result = await ServiceRequestService.customer_list(db, customer_id)

    assert result == requests


@pytest.mark.asyncio
async def test_all_requests():
    db = Mock()
    requests = [create_test_request(), create_test_request()]

    with patch(
        "app.services.service_request_service.ServiceRequestRepository.get_all",
        new=AsyncMock(return_value=requests),
    ):
        result = await ServiceRequestService.all(db)

    assert result == requests


@pytest.mark.asyncio
async def test_update_status():
    db = Mock()
    request = create_test_request()

    with patch(
        "app.services.service_request_service.ServiceRequestRepository.update",
        new=AsyncMock(return_value=request),
    ):
        result = await ServiceRequestService.update_status(db, request, "IN_PROGRESS")

    assert result == request
    assert request.status == ServiceRequestStatus.IN_PROGRESS


@pytest.mark.asyncio
async def test_update_status_invalid():
    db = Mock()
    request = create_test_request()

    with pytest.raises(ValueError, match="Invalid service request status"):
        await ServiceRequestService.update_status(db, request, "INVALID_STATUS")


@pytest.mark.asyncio
async def test_get_item():
    db = Mock()
    item = create_test_item()

    with patch(
        "app.services.service_request_service.ServiceRequestRepository.get_item",
        new=AsyncMock(return_value=item),
    ):
        result = await ServiceRequestService.get_item(db, item.id)

    assert result == item


@pytest.mark.asyncio
async def test_get_item_not_found():
    db = Mock()

    with patch(
        "app.services.service_request_service.ServiceRequestRepository.get_item",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError, match="Service request item not found"):
            await ServiceRequestService.get_item(db, uuid4())