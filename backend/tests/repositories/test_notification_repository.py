from unittest.mock import AsyncMock, MagicMock

import pytest

from app.repositories.notification_repository import NotificationRepository


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
    return db


@pytest.mark.asyncio
async def test_create_notification():
    db = create_db()
    notification = MagicMock()

    result = await NotificationRepository.create(db, notification)

    assert result == notification
    db.add.assert_called_once_with(notification)
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(notification)


@pytest.mark.asyncio
async def test_get_user_notifications():
    notifications = [MagicMock(), MagicMock()]
    db = db_with_many(notifications)

    result = await NotificationRepository.get_user_notifications(
        db,
        "user-id",
    )

    assert result == notifications
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_notification_by_id():
    notification = MagicMock()
    db = db_with_one(notification)

    result = await NotificationRepository.get_by_id(
        db,
        "notification-id",
    )

    assert result == notification
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_notification_by_id_returns_none():
    db = db_with_one(None)

    result = await NotificationRepository.get_by_id(
        db,
        "missing-id",
    )

    assert result is None


@pytest.mark.asyncio
async def test_update_notification():
    db = create_db()
    notification = MagicMock()

    result = await NotificationRepository.update(db, notification)

    assert result == notification
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(notification)