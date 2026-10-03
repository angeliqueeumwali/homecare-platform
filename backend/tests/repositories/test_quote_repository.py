from unittest.mock import AsyncMock, MagicMock

import pytest

from app.repositories.quote_repository import QuoteRepository


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
async def test_create_quote():
    db = create_db()
    quote = MagicMock()

    result = await QuoteRepository.create(db, quote)

    assert result == quote
    db.add.assert_called_once_with(quote)
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(quote)


@pytest.mark.asyncio
async def test_get_quote_by_id():
    quote = MagicMock()
    db = db_with_one(quote)

    result = await QuoteRepository.get_by_id(db, "quote-id")

    assert result == quote
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_quote_by_id_returns_none():
    db = db_with_one(None)

    result = await QuoteRepository.get_by_id(db, "missing-id")

    assert result is None


@pytest.mark.asyncio
async def test_get_request_quotes():
    quotes = [MagicMock(), MagicMock()]
    db = db_with_many(quotes)

    result = await QuoteRepository.get_request_quotes(db, "request-id")

    assert result == quotes
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_update_quote():
    db = create_db()
    quote = MagicMock()

    result = await QuoteRepository.update(db, quote)

    assert result == quote
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(quote)