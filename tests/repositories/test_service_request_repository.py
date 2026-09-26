from unittest.mock import AsyncMock, MagicMock

import pytest

from app.repositories.service_request_repository import ServiceRequestRepository


def db_with_one(value):
    db = MagicMock()
    db.execute = AsyncMock()

    result = MagicMock()
    result.scalar_one_or_none.return_value = value

    db.execute.return_value = result
    return db


def db_with_many(values):
    db = MagicMock()
    db.execute = AsyncMock()

    result = MagicMock()
    result.scalars.return_value.all.return_value = values

    db.execute.return_value = result
    return db


def create_db():
    db = MagicMock()
    db.add = MagicMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    db.delete = AsyncMock()
    return db


@pytest.mark.asyncio
async def test_create_service_request():
    db = create_db()
    request = MagicMock()
    items = [MagicMock(), MagicMock()]

    result = await ServiceRequestRepository.create(db, request, items)

    assert result == request
    assert db.add.call_count == 3
    db.add.assert_any_call(request)
    db.add.assert_any_call(items[0])
    db.add.assert_any_call(items[1])
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(request)


@pytest.mark.asyncio
async def test_get_service_request_by_id():
    request = MagicMock()
    db = db_with_one(request)

    result = await ServiceRequestRepository.get_by_id(db, "request-id")

    assert result == request
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_service_request_by_id_returns_none():
    db = db_with_one(None)

    result = await ServiceRequestRepository.get_by_id(db, "missing-id")

    assert result is None


@pytest.mark.asyncio
async def test_get_customer_requests():
    requests = [MagicMock(), MagicMock()]
    db = db_with_many(requests)

    result = await ServiceRequestRepository.get_customer_requests(db, "customer-id")

    assert result == requests
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_items():
    items = [MagicMock(), MagicMock()]
    db = db_with_many(items)

    result = await ServiceRequestRepository.get_items(db, "request-id")

    assert result == items
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_item():
    item = MagicMock()
    db = db_with_one(item)

    result = await ServiceRequestRepository.get_item(db, "item-id")

    assert result == item
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_item_returns_none():
    db = db_with_one(None)

    result = await ServiceRequestRepository.get_item(db, "missing-id")

    assert result is None


@pytest.mark.asyncio
async def test_update_service_request():
    db = create_db()
    request = MagicMock()

    result = await ServiceRequestRepository.update(db, request)

    assert result == request
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(request)


@pytest.mark.asyncio
async def test_update_item():
    db = create_db()
    item = MagicMock()

    result = await ServiceRequestRepository.update_item(db, item)

    assert result == item
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(item)


@pytest.mark.asyncio
async def test_get_all_requests():
    requests = [MagicMock(), MagicMock()]
    db = db_with_many(requests)

    result = await ServiceRequestRepository.get_all(db)

    assert result == requests
    db.execute.assert_awaited_once()