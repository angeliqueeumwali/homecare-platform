from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

import pytest

from app.core.enums import QuoteStatus
from app.models.quote import Quote
from app.models.service_request import ServiceRequest
from app.models.service_request_item import ServiceRequestItem
from app.services.quote_service import QuoteService


def create_test_request(request_id=None):
    return ServiceRequest(
        id=request_id or uuid4(),
        customer_id=uuid4(),
        address="Test Address",
        latitude=1.0,
        longitude=2.0,
        preferred_date="2024-01-01",
        notes="Test notes",
    )


def create_test_item(item_id=None, request_id=None):
    return ServiceRequestItem(
        id=item_id or uuid4(),
        service_request_id=request_id or uuid4(),
        service_category_id=uuid4(),
        status="PENDING",
        notes="Test item",
    )


def create_test_quote(quote_id=None, request_id=None, item_id=None, provider_id=None):
    return Quote(
        id=quote_id or uuid4(),
        service_request_id=request_id or uuid4(),
        service_request_item_id=item_id or uuid4(),
        provider_id=provider_id or uuid4(),
        amount=100.00,
        currency="RWF",
        status=QuoteStatus.PENDING,
        description="Test quote",
    )


class MockCreateData:
    def __init__(self, service_request_id=None, service_request_item_id=None, amount=100.00, currency="RWF", description="Test quote"):
        self.service_request_id = service_request_id or uuid4()
        self.service_request_item_id = service_request_item_id or uuid4()
        self.amount = amount
        self.currency = currency
        self.description = description


@pytest.mark.asyncio
async def test_create_quote():
    db = AsyncMock()
    provider_id = uuid4()
    data = MockCreateData()
    request = create_test_request(request_id=data.service_request_id)
    item = create_test_item(item_id=data.service_request_item_id, request_id=data.service_request_id)
    created_quote = create_test_quote(quote_id=uuid4(), request_id=data.service_request_id, item_id=data.service_request_item_id, provider_id=provider_id)

    with patch(
        "app.services.quote_service.ServiceRequestRepository.get_by_id",
        new=AsyncMock(return_value=request),
    ), patch(
        "app.services.quote_service.ServiceRequestRepository.get_item",
        new=AsyncMock(return_value=item),
    ), patch(
        "app.services.quote_service.QuoteRepository.create",
        new=AsyncMock(return_value=created_quote),
    ) as mock_create:
        result = await QuoteService.create(db, provider_id, data)

    assert result == created_quote
    mock_create.assert_awaited_once()
    call_args = mock_create.call_args
    created_quote_obj = call_args[0][1]  # second positional arg
    assert created_quote_obj.service_request_id == data.service_request_id
    assert created_quote_obj.service_request_item_id == data.service_request_item_id
    assert created_quote_obj.provider_id == provider_id


@pytest.mark.asyncio
async def test_create_quote_invalid_request():
    db = AsyncMock()
    provider_id = uuid4()
    data = MockCreateData()

    with patch(
        "app.services.quote_service.ServiceRequestRepository.get_by_id",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError, match="Invalid service request item"):
            await QuoteService.create(db, provider_id, data)


@pytest.mark.asyncio
async def test_create_quote_invalid_item():
    db = AsyncMock()
    provider_id = uuid4()
    data = MockCreateData()
    request = create_test_request(request_id=data.service_request_id)
    item = create_test_item(item_id=data.service_request_item_id, request_id=uuid4())

    with patch(
        "app.services.quote_service.ServiceRequestRepository.get_by_id",
        new=AsyncMock(return_value=request),
    ), patch(
        "app.services.quote_service.ServiceRequestRepository.get_item",
        new=AsyncMock(return_value=item),
    ):
        with pytest.raises(ValueError, match="Invalid service request item"):
            await QuoteService.create(db, provider_id, data)


@pytest.mark.asyncio
async def test_get_quote():
    db = AsyncMock()
    quote = create_test_quote()

    with patch(
        "app.services.quote_service.QuoteRepository.get_by_id",
        new=AsyncMock(return_value=quote),
    ):
        result = await QuoteService.get(db, quote.id)

    assert result == quote


@pytest.mark.asyncio
async def test_get_quote_not_found():
    db = AsyncMock()

    with patch(
        "app.services.quote_service.QuoteRepository.get_by_id",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError, match="Quote not found"):
            await QuoteService.get(db, uuid4())


@pytest.mark.asyncio
async def test_list_for_request():
    db = AsyncMock()
    request_id = uuid4()
    quotes = [create_test_quote(request_id=request_id), create_test_quote(request_id=request_id)]

    with patch(
        "app.services.quote_service.QuoteRepository.get_request_quotes",
        new=AsyncMock(return_value=quotes),
    ):
        result = await QuoteService.list_for_request(db, request_id)

    assert result == quotes


@pytest.mark.asyncio
async def test_update_status():
    db = AsyncMock()
    quote = create_test_quote()
    updated_quote = create_test_quote()
    updated_quote.status = QuoteStatus.APPROVED

    with patch(
        "app.services.quote_service.QuoteRepository.update",
        new=AsyncMock(return_value=updated_quote),
    ):
        result = await QuoteService.update_status(db, quote, "APPROVED")

    assert result == updated_quote
    assert quote.status == QuoteStatus.APPROVED


@pytest.mark.asyncio
async def test_update_status_invalid():
    db = AsyncMock()
    quote = create_test_quote()

    with pytest.raises(ValueError, match="Invalid quote status"):
        await QuoteService.update_status(db, quote, "INVALID_STATUS")