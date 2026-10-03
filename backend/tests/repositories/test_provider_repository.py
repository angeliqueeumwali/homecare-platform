from unittest.mock import AsyncMock, MagicMock

import pytest

from app.repositories.provider_repository import ProviderRepository


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


def db_with_join(values):
    """Create a mock db for the get_available_for_service join query"""
    db = MagicMock()
    db.execute = AsyncMock()

    # The query chain: select(...).join(...).where(...)
    # We need to mock the chain: execute -> result -> scalars().unique().all()
    mock_result = MagicMock()
    mock_scalars = MagicMock()
    mock_unique = MagicMock()
    mock_unique.all.return_value = values
    mock_scalars.unique.return_value = mock_unique
    mock_result.scalars.return_value = mock_scalars

    db.execute.return_value = mock_result
    return db


def create_db():
    db = MagicMock()
    db.add = MagicMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    db.delete = AsyncMock()
    return db


@pytest.mark.asyncio
async def test_get_provider_by_id():
    provider = MagicMock()
    db = db_with_one(provider)

    result = await ProviderRepository.get_by_id(db, "provider-id")

    assert result == provider
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_provider_by_id_returns_none():
    db = db_with_one(None)

    result = await ProviderRepository.get_by_id(db, "missing-id")

    assert result is None


@pytest.mark.asyncio
async def test_get_provider_by_user_id():
    provider = MagicMock()
    db = db_with_one(provider)

    result = await ProviderRepository.get_by_user_id(db, "user-id")

    assert result == provider
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_provider_by_user_id_returns_none():
    db = db_with_one(None)

    result = await ProviderRepository.get_by_user_id(db, "missing-id")

    assert result is None


@pytest.mark.asyncio
async def test_get_all_providers():
    providers = [MagicMock(), MagicMock()]
    db = db_with_many(providers)

    result = await ProviderRepository.get_all(db)

    assert result == providers
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_available_for_service():
    providers = [MagicMock(), MagicMock()]
    db = db_with_join(providers)

    result = await ProviderRepository.get_available_for_service(db, "category-id")

    assert result == providers
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_create_provider():
    db = create_db()
    provider = MagicMock()

    result = await ProviderRepository.create(db, provider)

    assert result == provider
    db.add.assert_called_once_with(provider)
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(provider)


@pytest.mark.asyncio
async def test_create_provider_service():
    db = create_db()
    provider_service = MagicMock()

    result = await ProviderRepository.create_service(db, provider_service)

    assert result == provider_service
    db.add.assert_called_once_with(provider_service)
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(provider_service)


@pytest.mark.asyncio
async def test_get_provider_service():
    provider_service = MagicMock()
    db = db_with_one(provider_service)

    result = await ProviderRepository.get_service(db, "provider-id", "category-id")

    assert result == provider_service
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_provider_service_returns_none():
    db = db_with_one(None)

    result = await ProviderRepository.get_service(db, "provider-id", "category-id")

    assert result is None


@pytest.mark.asyncio
async def test_delete_provider_service():
    db = create_db()
    provider_service = MagicMock()

    await ProviderRepository.delete_service(db, provider_service)

    db.delete.assert_awaited_once_with(provider_service)
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_provider_location():
    location = MagicMock()
    db = db_with_one(location)

    result = await ProviderRepository.get_location(db, "provider-id")

    assert result == location
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_provider_location_returns_none():
    db = db_with_one(None)

    result = await ProviderRepository.get_location(db, "provider-id")

    assert result is None


@pytest.mark.asyncio
async def test_save_provider_location():
    db = create_db()
    location = MagicMock()

    result = await ProviderRepository.save_location(db, location)

    assert result == location
    db.add.assert_called_once_with(location)
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(location)


@pytest.mark.asyncio
async def test_list_provider_services():
    services = [MagicMock(), MagicMock()]
    db = db_with_many(services)

    result = await ProviderRepository.list_services(db, "provider-id")

    assert result == services
    db.execute.assert_awaited_once()