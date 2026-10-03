from unittest.mock import AsyncMock, MagicMock

import pytest

from app.repositories.user_repository import UserRepository


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
async def test_create_user():
    db = create_db()
    user = MagicMock()

    result = await UserRepository.create(db, user)

    assert result == user
    db.add.assert_called_once_with(user)
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(user)


@pytest.mark.asyncio
async def test_get_user_by_id():
    user = MagicMock()
    db = db_with_one(user)

    result = await UserRepository.get_by_id(db, "user-id")

    assert result == user
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_user_by_id_returns_none():
    db = db_with_one(None)

    result = await UserRepository.get_by_id(db, "missing-id")

    assert result is None


@pytest.mark.asyncio
async def test_get_user_by_email():
    user = MagicMock()
    db = db_with_one(user)

    result = await UserRepository.get_by_email(db, "test@example.com")

    assert result == user
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_user_by_email_returns_none():
    db = db_with_one(None)

    result = await UserRepository.get_by_email(db, "missing@example.com")

    assert result is None


@pytest.mark.asyncio
async def test_get_user_by_phone():
    user = MagicMock()
    db = db_with_one(user)

    result = await UserRepository.get_by_phone(db, "0780000000")

    assert result == user
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_user_by_phone_returns_none():
    db = db_with_one(None)

    result = await UserRepository.get_by_phone(db, "missing")

    assert result is None


@pytest.mark.asyncio
async def test_get_all_users():
    users = [MagicMock(), MagicMock()]
    db = db_with_many(users)

    result = await UserRepository.get_all(db)

    assert result == users
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_update_user():
    db = create_db()
    user = MagicMock()

    result = await UserRepository.update(db, user)

    assert result == user
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(user)


@pytest.mark.asyncio
async def test_delete_user():
    db = create_db()
    user = MagicMock()

    await UserRepository.delete(db, user)

    db.delete.assert_awaited_once_with(user)
    db.commit.assert_awaited_once()