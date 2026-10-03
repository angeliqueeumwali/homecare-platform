from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

import pytest

from app.core.enums import AssignmentStatus, ServiceRequestItemStatus, ServiceRequestStatus
from app.models.assignment import Assignment
from app.models.provider_profile import ProviderProfile
from app.models.service_request import ServiceRequest
from app.models.service_request_item import ServiceRequestItem
from app.services.assignment_service import AssignmentService


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


def create_test_provider():
    return ProviderProfile(
        id=uuid4(),
        user_id=uuid4(),
        business_name="Test Business",
        bio="Test Bio",
        is_available=True,
    )


def create_test_assignment():
    return Assignment(
        id=uuid4(),
        service_request_id=uuid4(),
        service_request_item_id=uuid4(),
        provider_id=uuid4(),
        status=AssignmentStatus.PENDING,
    )


@pytest.mark.asyncio
async def test_create_assignment():
    db = AsyncMock()
    request = create_test_request()
    item = create_test_item()
    item.service_request_id = request.id
    provider = create_test_provider()
    assignment = create_test_assignment()
    assignment.service_request_id = request.id
    assignment.service_request_item_id = item.id
    assignment.provider_id = provider.id

    with patch(
        "app.services.assignment_service.ServiceRequestRepository.get_by_id",
        new=AsyncMock(return_value=request),
    ), patch(
        "app.services.assignment_service.ServiceRequestRepository.get_item",
        new=AsyncMock(return_value=item),
    ), patch(
        "app.services.assignment_service.ProviderRepository.get_by_id",
        new=AsyncMock(return_value=provider),
    ), patch(
        "app.services.assignment_service.AssignmentRepository.create",
        new=AsyncMock(return_value=assignment),
    ):
        result = await AssignmentService.create(db, request.id, item.id, provider.id)

    assert result == assignment
    assert item.status == ServiceRequestItemStatus.PROVIDER_ASSIGNED
    assert request.status == ServiceRequestStatus.IN_PROGRESS


@pytest.mark.asyncio
async def test_create_assignment_request_not_found():
    db = AsyncMock()

    with patch(
        "app.services.assignment_service.ServiceRequestRepository.get_by_id",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError, match="Service request or item not found"):
            await AssignmentService.create(db, uuid4(), uuid4(), uuid4())


@pytest.mark.asyncio
async def test_create_assignment_item_not_found():
    db = AsyncMock()
    request = create_test_request()

    with patch(
        "app.services.assignment_service.ServiceRequestRepository.get_by_id",
        new=AsyncMock(return_value=request),
    ), patch(
        "app.services.assignment_service.ServiceRequestRepository.get_item",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError, match="Service request or item not found"):
            await AssignmentService.create(db, request.id, uuid4(), uuid4())


@pytest.mark.asyncio
async def test_create_assignment_item_not_belong_to_request():
    db = AsyncMock()
    request = create_test_request()
    item = create_test_item()
    item.service_request_id = uuid4()

    with patch(
        "app.services.assignment_service.ServiceRequestRepository.get_by_id",
        new=AsyncMock(return_value=request),
    ), patch(
        "app.services.assignment_service.ServiceRequestRepository.get_item",
        new=AsyncMock(return_value=item),
    ):
        with pytest.raises(ValueError, match="Item does not belong to request"):
            await AssignmentService.create(db, request.id, item.id, uuid4())


@pytest.mark.asyncio
async def test_create_assignment_provider_not_found():
    db = AsyncMock()
    request = create_test_request()
    item = create_test_item()
    item.service_request_id = request.id

    with patch(
        "app.services.assignment_service.ServiceRequestRepository.get_by_id",
        new=AsyncMock(return_value=request),
    ), patch(
        "app.services.assignment_service.ServiceRequestRepository.get_item",
        new=AsyncMock(return_value=item),
    ), patch(
        "app.services.assignment_service.ProviderRepository.get_by_id",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError, match="Provider not found"):
            await AssignmentService.create(db, request.id, item.id, uuid4())


@pytest.mark.asyncio
async def test_get_assignment():
    db = AsyncMock()
    assignment = create_test_assignment()

    with patch(
        "app.services.assignment_service.AssignmentRepository.get_by_id",
        new=AsyncMock(return_value=assignment),
    ):
        result = await AssignmentService.get(db, assignment.id)

    assert result == assignment


@pytest.mark.asyncio
async def test_get_assignment_not_found():
    db = AsyncMock()

    with patch(
        "app.services.assignment_service.AssignmentRepository.get_by_id",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError, match="Assignment not found"):
            await AssignmentService.get(db, uuid4())


@pytest.mark.asyncio
async def test_provider_list():
    db = AsyncMock()
    provider_id = uuid4()
    assignments = [create_test_assignment(), create_test_assignment()]

    with patch(
        "app.services.assignment_service.AssignmentRepository.get_provider_assignments",
        new=AsyncMock(return_value=assignments),
    ):
        result = await AssignmentService.provider_list(db, provider_id)

    assert result == assignments


@pytest.mark.asyncio
async def test_request_list():
    db = AsyncMock()
    request_id = uuid4()
    assignments = [create_test_assignment(), create_test_assignment()]

    with patch(
        "app.services.assignment_service.AssignmentRepository.get_request_assignments",
        new=AsyncMock(return_value=assignments),
    ):
        result = await AssignmentService.request_list(db, request_id)

    assert result == assignments


@pytest.mark.asyncio
async def test_update_status_accepted():
    db = AsyncMock()
    assignment = create_test_assignment()
    assignment.service_request_item = create_test_item()
    assignment.service_request_item.status = ServiceRequestItemStatus.PROVIDER_ASSIGNED
    updated_assignment = create_test_assignment()
    updated_assignment.status = AssignmentStatus.ACCEPTED
    updated_assignment.accepted_at = Mock()

    with patch(
        "app.services.assignment_service.AssignmentRepository.update",
        new=AsyncMock(return_value=updated_assignment),
    ):
        result = await AssignmentService.update_status(db, assignment, "ACCEPTED")

    assert result == updated_assignment
    assert assignment.status == AssignmentStatus.ACCEPTED
    assert assignment.accepted_at is not None
    assert assignment.service_request_item.status == ServiceRequestItemStatus.PROVIDER_ASSIGNED


@pytest.mark.asyncio
async def test_update_status_in_progress():
    db = AsyncMock()
    assignment = create_test_assignment()
    assignment.service_request_item = create_test_item()

    with patch(
        "app.services.assignment_service.AssignmentRepository.update",
        new=AsyncMock(return_value=assignment),
    ):
        result = await AssignmentService.update_status(db, assignment, "IN_PROGRESS")

    assert result == assignment
    assert assignment.status == AssignmentStatus.IN_PROGRESS
    assert assignment.service_request_item.status == ServiceRequestItemStatus.IN_PROGRESS


@pytest.mark.asyncio
async def test_update_status_completed():
    db = AsyncMock()
    assignment = create_test_assignment()
    assignment.service_request_item = create_test_item()

    with patch(
        "app.services.assignment_service.AssignmentRepository.update",
        new=AsyncMock(return_value=assignment),
    ):
        result = await AssignmentService.update_status(db, assignment, "COMPLETED")

    assert result == assignment
    assert assignment.status == AssignmentStatus.COMPLETED
    assert assignment.completed_at is not None
    assert assignment.service_request_item.status == ServiceRequestItemStatus.COMPLETED


@pytest.mark.asyncio
async def test_update_status_cancelled():
    db = AsyncMock()
    assignment = create_test_assignment()
    assignment.service_request_item = create_test_item()

    with patch(
        "app.services.assignment_service.AssignmentRepository.update",
        new=AsyncMock(return_value=assignment),
    ):
        result = await AssignmentService.update_status(db, assignment, "CANCELLED")

    assert result == assignment
    assert assignment.status == AssignmentStatus.CANCELLED
    assert assignment.service_request_item.status == ServiceRequestItemStatus.CANCELLED


@pytest.mark.asyncio
async def test_update_status_invalid():
    db = AsyncMock()
    assignment = create_test_assignment()
    assignment.service_request_item = create_test_item()

    with pytest.raises(ValueError, match="Invalid assignment status"):
        await AssignmentService.update_status(db, assignment, "INVALID_STATUS")