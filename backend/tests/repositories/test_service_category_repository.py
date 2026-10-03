from unittest.mock import AsyncMock, MagicMock

import pytest

from app.repositories.service_category_repository import ServiceCategoryRepository


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
async def test_create_service_category():
    db = create_db()
    category = MagicMock()

    result = await ServiceCategoryRepository.create(db, category)

    assert result == category
    db.add.assert_called_once_with(category)
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(category)


@pytest.mark.asyncio
async def test_get_service_category_by_id():
    category = MagicMock()
    db = db_with_one(category)

    result = await ServiceCategoryRepository.get_by_id(db, "category-id")

    assert result == category
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_service_category_by_id_returns_none():
    db = db_with_one(None)

    result = await ServiceCategoryRepository.get_by_id(db, "missing-id")

    assert result is None


@pytest.mark.asyncio
async def test_get_service_category_by_name():
    category = MagicMock()
    db = db_with_one(category)

    result = await ServiceCategoryRepository.get_by_name(db, "Cleaning")

    assert result == category
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_all_service_categories():
    categories = [MagicMock(), MagicMock()]
    db = db_with_many(categories)

    result = await ServiceCategoryRepository.get_all(db)

    assert result == categories
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_service_category_by_name_returns_none():
    db = db_with_one(None)

    result = await ServiceCategoryRepository.get_by_name(db, "Nonexistent")

    assert result is None


@pytest.mark.asyncio
async def test_get_all_service_categories_empty():
    db = db_with_many([])

    result = await ServiceCategoryRepository.get_all(db)

    assert result == []


@pytest.mark.asyncio
async def test_update_service_category():
    db = create_db()
    category = MagicMock()

    result = await ServiceCategoryRepository.update(db, category)

    assert result == category
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(category)


@pytest.mark.asyncio
async def test_delete_service_category():
    db = create_db()
    category = MagicMock()

    await ServiceCategoryRepository.delete(db, category)

    db.delete.assert_awaited_once_with(category)
    db.commit.assert_awaited_once()