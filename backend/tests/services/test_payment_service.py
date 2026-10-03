from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

import pytest

from app.core.enums import PaymentMethod, PaymentStatus, QuoteStatus
from app.models.payment import Payment
from app.models.quote import Quote
from app.services.payment_service import PaymentService


def create_test_quote(quote_id=None, service_request_id=None, amount=100.00, status=QuoteStatus.APPROVED):
    return Quote(
        id=quote_id or uuid4(),
        service_request_id=service_request_id or uuid4(),
        service_request_item_id=uuid4(),
        provider_id=uuid4(),
        amount=amount,
        currency="RWF",
        status=status,
    )


def create_test_payment(customer_id=None, quote_id=None, service_request_id=None):
    return Payment(
        id=uuid4(),
        service_request_id=service_request_id or uuid4(),
        quote_id=quote_id or uuid4(),
        customer_id=customer_id or uuid4(),
        amount=100.00,
        currency="RWF",
        payment_method=PaymentMethod.MOBILE_MONEY,
        status=PaymentStatus.PENDING,
    )


class MockCreateData:
    def __init__(self, quote_id=None, service_request_id=None, amount=100.00, payment_method="MOBILE_MONEY"):
        self.quote_id = quote_id or uuid4()
        self.service_request_id = service_request_id or uuid4()
        self.amount = amount
        self.currency = "RWF"
        self.payment_method = payment_method


@pytest.mark.asyncio
async def test_create_payment():
    db = AsyncMock()
    customer_id = uuid4()
    data = MockCreateData()
    quote = create_test_quote(quote_id=data.quote_id, service_request_id=data.service_request_id, amount=data.amount)
    created_payment = create_test_payment(customer_id=customer_id, quote_id=data.quote_id, service_request_id=data.service_request_id)

    with patch(
        "app.services.payment_service.QuoteRepository.get_by_id",
        new=AsyncMock(return_value=quote),
    ), patch(
        "app.services.payment_service.PaymentRepository.create",
        new=AsyncMock(return_value=created_payment),
    ) as mock_create:
        result = await PaymentService.create(db, customer_id, data)

    assert result == created_payment
    mock_create.assert_awaited_once()
    call_args = mock_create.call_args
    created_payment_obj = call_args[0][1]  # second positional arg
    assert created_payment_obj.customer_id == customer_id
    assert created_payment_obj.quote_id == data.quote_id
    assert created_payment_obj.service_request_id == data.service_request_id
    assert created_payment_obj.amount == data.amount
    assert created_payment_obj.payment_method == PaymentMethod.MOBILE_MONEY


@pytest.mark.asyncio
async def test_create_payment_quote_not_found():
    db = AsyncMock()
    customer_id = uuid4()
    data = MockCreateData()

    with patch(
        "app.services.payment_service.QuoteRepository.get_by_id",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError, match="Invalid quote"):
            await PaymentService.create(db, customer_id, data)


@pytest.mark.asyncio
async def test_create_payment_quote_wrong_request():
    db = AsyncMock()
    customer_id = uuid4()
    data = MockCreateData()
    quote = create_test_quote(quote_id=data.quote_id, service_request_id=uuid4())

    with patch(
        "app.services.payment_service.QuoteRepository.get_by_id",
        new=AsyncMock(return_value=quote),
    ):
        with pytest.raises(ValueError, match="Invalid quote"):
            await PaymentService.create(db, customer_id, data)


@pytest.mark.asyncio
async def test_create_payment_quote_not_approved():
    db = AsyncMock()
    customer_id = uuid4()
    data = MockCreateData()
    quote = create_test_quote(quote_id=data.quote_id, service_request_id=data.service_request_id, status=QuoteStatus.PENDING)

    with patch(
        "app.services.payment_service.QuoteRepository.get_by_id",
        new=AsyncMock(return_value=quote),
    ):
        with pytest.raises(ValueError, match="Quote must be approved before payment"):
            await PaymentService.create(db, customer_id, data)


@pytest.mark.asyncio
async def test_create_payment_amount_mismatch():
    db = AsyncMock()
    customer_id = uuid4()
    data = MockCreateData(amount=200.00)
    quote = create_test_quote(quote_id=data.quote_id, service_request_id=data.service_request_id, amount=100.00)

    with patch(
        "app.services.payment_service.QuoteRepository.get_by_id",
        new=AsyncMock(return_value=quote),
    ):
        with pytest.raises(ValueError, match="Payment amount must match the approved quote"):
            await PaymentService.create(db, customer_id, data)


@pytest.mark.asyncio
async def test_create_payment_invalid_method():
    db = AsyncMock()
    customer_id = uuid4()
    data = MockCreateData(payment_method="INVALID_METHOD")
    quote = create_test_quote(quote_id=data.quote_id, service_request_id=data.service_request_id)

    with patch(
        "app.services.payment_service.QuoteRepository.get_by_id",
        new=AsyncMock(return_value=quote),
    ):
        with pytest.raises(ValueError, match="Invalid payment method"):
            await PaymentService.create(db, customer_id, data)


@pytest.mark.asyncio
async def test_list_customer_payments():
    db = AsyncMock()
    customer_id = uuid4()
    payments = [create_test_payment(customer_id=customer_id), create_test_payment(customer_id=customer_id)]

    with patch(
        "app.services.payment_service.PaymentRepository.get_customer_payments",
        new=AsyncMock(return_value=payments),
    ):
        result = await PaymentService.list_customer(db, customer_id)

    assert result == payments


@pytest.mark.asyncio
async def test_update_status():
    db = AsyncMock()
    payment = create_test_payment()
    updated_payment = create_test_payment()
    updated_payment.status = PaymentStatus.PAID

    with patch(
        "app.services.payment_service.PaymentRepository.update",
        new=AsyncMock(return_value=updated_payment),
    ):
        result = await PaymentService.update_status(db, payment, "PAID", "TXN123")

    assert result == updated_payment
    assert payment.status == PaymentStatus.PAID
    assert payment.transaction_reference == "TXN123"
    assert payment.paid_at is not None


@pytest.mark.asyncio
async def test_update_status_invalid():
    db = AsyncMock()
    payment = create_test_payment()

    with pytest.raises(ValueError, match="Invalid payment status"):
        await PaymentService.update_status(db, payment, "INVALID_STATUS")


@pytest.mark.asyncio
async def test_update_status_without_transaction_reference():
    db = AsyncMock()
    payment = create_test_payment()
    updated_payment = create_test_payment()
    updated_payment.status = PaymentStatus.PAID

    with patch(
        "app.services.payment_service.PaymentRepository.update",
        new=AsyncMock(return_value=updated_payment),
    ):
        result = await PaymentService.update_status(db, payment, "PAID")

    assert result == updated_payment
    assert payment.status == PaymentStatus.PAID
    assert payment.transaction_reference is None
    assert payment.paid_at is not None