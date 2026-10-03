import pytest
from httpx import ASGITransport, AsyncClient
from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

from app.main import app
from app.core.enums import UserRole, PaymentStatus
from app.models.user import User
from app.models.payment import Payment
from app.models.quote import Quote
from app.models.service_request import ServiceRequest
from app.core.dependencies import get_current_user


def mock_customer_user():
    return User(
        id=uuid4(),
        first_name="Customer",
        last_name="User",
        email="customer@example.com",
        phone_number="07800001",
        password_hash="hashed",
        role=UserRole.CUSTOMER,
        is_active=True,
    )


def mock_admin_user():
    return User(
        id=uuid4(),
        first_name="Admin",
        last_name="User",
        email="admin@example.com",
        phone_number="0780002",
        password_hash="hashed",
        role=UserRole.ADMIN,
        is_active=True,
    )


def mock_quote():
    return Quote(
        id=uuid4(),
        service_request_id=uuid4(),
        service_request_item_id=uuid4(),
        provider_id=uuid4(),
        amount=100.00,
        currency="RWF",
        status="APPROVED",
    )


def mock_payment():
    payment = Payment(
        id=uuid4(),
        service_request_id=uuid4(),
        quote_id=uuid4(),
        customer_id=uuid4(),
        amount=100.00,
        currency="RWF",
        payment_method="MOBILE_MONEY",
        status=PaymentStatus.PENDING,
    )
    return payment


class TestPaymentRouter:
    @pytest.mark.anyio
    async def test_create_payment_customer(self):
        user = mock_customer_user()
        payment = mock_payment()
        payment.customer_id = user.id

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.payment_router.PaymentService.create", new=AsyncMock(return_value=payment)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.post(
                        "/payments",
                        json={
                            "quote_id": str(uuid4()),
                            "service_request_id": str(uuid4()),
                            "amount": 100.00,
                            "currency": "RWF",
                            "payment_method": "MOBILE_MONEY",
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 201
        assert response.json()["amount"] == "100.0"

    @pytest.mark.anyio
    async def test_create_payment_invalid(self):
        user = mock_customer_user()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.payment_router.PaymentService.create", new=AsyncMock(side_effect=ValueError("Invalid quote"))):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.post(
                        "/payments",
                        json={
                            "quote_id": str(uuid4()),
                            "service_request_id": str(uuid4()),
                            "amount": 100.00,
                            "currency": "RWF",
                            "payment_method": "MOBILE_MONEY",
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 400
        assert response.json()["detail"] == "Invalid quote"

    @pytest.mark.anyio
    async def test_my_payments(self):
        user = mock_customer_user()
        payments = [mock_payment(), mock_payment()]

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.routers.payment_router.PaymentService.list_customer", new=AsyncMock(return_value=payments)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.get(
                        "/payments/me",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert len(response.json()) == 2

    @pytest.mark.anyio
    async def test_update_payment_admin(self):
        user = mock_admin_user()
        payment = mock_payment()
        updated_payment = mock_payment()
        updated_payment.status = PaymentStatus.PAID
        updated_payment.transaction_reference = "TXN123"

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.repositories.payment_repository.PaymentRepository.get_by_id", new=AsyncMock(return_value=payment)), \
                 patch("app.routers.payment_router.PaymentService.update_status", new=AsyncMock(return_value=updated_payment)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        f"/payments/{payment.id}/status",
                        json={
                            "status": "PAID",
                            "transaction_reference": "TXN123",
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        assert response.json()["status"] == "PAID"
        assert response.json()["transaction_reference"] == "TXN123"

    @pytest.mark.anyio
    async def test_update_payment_not_found(self):
        user = mock_admin_user()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.repositories.payment_repository.PaymentRepository.get_by_id", new=AsyncMock(return_value=None)):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        f"/payments/{uuid4()}/status",
                        json={
                            "status": "PAID",
                            "transaction_reference": "TXN123",
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 400
        assert response.json()["detail"] == "Payment not found"

    @pytest.mark.anyio
    async def test_update_payment_invalid_status(self):
        user = mock_admin_user()
        payment = mock_payment()

        app.dependency_overrides[get_current_user] = lambda: user
        
        try:
            with patch("app.repositories.payment_repository.PaymentRepository.get_by_id", new=AsyncMock(return_value=payment)), \
                 patch("app.routers.payment_router.PaymentService.update_status", new=AsyncMock(side_effect=ValueError("Invalid payment status"))):
                transport = ASGITransport(app=app)
                async with AsyncClient(transport=transport, base_url="http://test") as client:
                    response = await client.patch(
                        f"/payments/{payment.id}/status",
                        json={
                            "status": "INVALID",
                            "transaction_reference": "TXN123",
                        },
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 400
        assert response.json()["detail"] == "Invalid payment status"