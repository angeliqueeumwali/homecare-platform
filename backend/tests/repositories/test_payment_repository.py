from unittest.mock import AsyncMock, MagicMock

import pytest

from app.repositories.payment_repository import PaymentRepository


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
async def test_create_payment():
    db = create_db()
    payment = MagicMock()

    result = await PaymentRepository.create(db, payment)

    assert result == payment
    db.add.assert_called_once_with(payment)
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(payment)


@pytest.mark.asyncio
async def test_get_payment_by_id():
    payment = MagicMock()
    db = db_with_one(payment)

    result = await PaymentRepository.get_by_id(db, "payment-id")

    assert result == payment
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_payment_by_id_returns_none():
    db = db_with_one(None)

    result = await PaymentRepository.get_by_id(db, "missing-id")

    assert result is None


@pytest.mark.asyncio
async def test_get_customer_payments():
    payments = [MagicMock(), MagicMock()]
    db = db_with_many(payments)

    result = await PaymentRepository.get_customer_payments(db, "customer-id")

    assert result == payments
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_update_payment():
    db = create_db()
    payment = MagicMock()

    result = await PaymentRepository.update(db, payment)

    assert result == payment
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(payment)