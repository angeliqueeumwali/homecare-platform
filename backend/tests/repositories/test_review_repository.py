from unittest.mock import AsyncMock, MagicMock

import pytest

from app.repositories.review_repository import ReviewRepository


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
async def test_create_review():
    db = create_db()
    review = MagicMock()

    result = await ReviewRepository.create(db, review)

    assert result == review
    db.add.assert_called_once_with(review)
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(review)


@pytest.mark.asyncio
async def test_get_review_by_assignment():
    review = MagicMock()
    db = db_with_one(review)

    result = await ReviewRepository.get_by_assignment(db, "assignment-id")

    assert result == review
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_review_by_assignment_returns_none():
    db = db_with_one(None)

    result = await ReviewRepository.get_by_assignment(db, "missing-id")

    assert result is None


@pytest.mark.asyncio
async def test_get_provider_reviews():
    reviews = [MagicMock(), MagicMock()]
    db = db_with_many(reviews)

    result = await ReviewRepository.get_provider_reviews(db, "provider-id")

    assert result == reviews
    db.execute.assert_awaited_once()