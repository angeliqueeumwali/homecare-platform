import pytest
from datetime import datetime
from httpx import ASGITransport, AsyncClient
from unittest.mock import AsyncMock, patch
from uuid import uuid4

from app.main import app
from app.core.enums import UserRole
from app.models.user import User
from app.models.support import ContactMessage
from app.core.dependencies import get_current_user


def mock_user(role=UserRole.CUSTOMER):
    return User(
        id=uuid4(),
        first_name="Test",
        last_name="User",
        email="test@example.com",
        phone_number="0780000000",
        password_hash="hashed",
        role=role,
        is_active=True,
    )


def mock_contact_message():
    return ContactMessage(
        id=uuid4(),
        name="Test User",
        email="test@example.com",
        subject="Question",
        message="I have a question about my booking",
        ip_address="127.0.0.1",
        created_at=datetime.utcnow(),
    )


class TestSupportRouter:
    @pytest.mark.anyio
    async def test_submit_contact(self):
        message = mock_contact_message()
        with patch(
            "app.routers.support_router.ContactService.submit",
            new=AsyncMock(
                return_value={
                    "id": message.id,
                    "received": True,
                    "email_delivery_configured": False,
                }
            ),
        ) as mock_submit:
            transport = ASGITransport(app=app)
            async with AsyncClient(
                transport=transport, base_url="http://test"
            ) as client:
                response = await client.post(
                    "/support/contact",
                    json={
                        "name": "Test User",
                        "email": "test@example.com",
                        "subject": "Question",
                        "message": "I have a question about my booking",
                    },
                )

        assert response.status_code == 200
        data = response.json()
        assert data["received"] is True
        assert data["email_delivery_configured"] is False
        kwargs = mock_submit.await_args.kwargs
        assert kwargs["name"] == "Test User"
        assert kwargs["email"] == "test@example.com"
        assert kwargs["honeypot"] == ""

    @pytest.mark.anyio
    async def test_submit_contact_validation_error(self):
        with patch(
            "app.routers.support_router.ContactService.submit",
            new=AsyncMock(
                side_effect=ValueError("Message too short")
            ),
        ):
            transport = ASGITransport(app=app)
            async with AsyncClient(
                transport=transport, base_url="http://test"
            ) as client:
                response = await client.post(
                    "/support/contact",
                    json={
                        "name": "Test User",
                        "email": "test@example.com",
                        "subject": "Question",
                        "message": "I have a question about my booking",
                    },
                )

        assert response.status_code == 400
        assert response.json()["detail"] == "Message too short"

    @pytest.mark.anyio
    async def test_submit_contact_invalid_payload(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(
            transport=transport, base_url="http://test"
        ) as client:
            response = await client.post(
                "/support/contact",
                json={
                    "name": "T",
                    "email": "not-an-email",
                    "subject": "Q",
                    "message": "short",
                },
            )
        assert response.status_code == 422

    @pytest.mark.anyio
    async def test_list_contact_messages_requires_admin(self):
        user = mock_user(role=UserRole.CUSTOMER)
        app.dependency_overrides[get_current_user] = lambda: user
        try:
            transport = ASGITransport(app=app)
            async with AsyncClient(
                transport=transport, base_url="http://test"
            ) as client:
                response = await client.get(
                    "/support/contact-messages",
                    headers={"Authorization": "Bearer token"},
                )
        finally:
            app.dependency_overrides.clear()
        assert response.status_code == 403

    @pytest.mark.anyio
    async def test_list_contact_messages_as_admin(self):
        admin = mock_user(role=UserRole.ADMIN)
        messages = [mock_contact_message()]
        app.dependency_overrides[get_current_user] = lambda: admin
        try:
            with patch(
                "app.routers.support_router.SupportRepository"
                ".list_contact_messages",
                new=AsyncMock(return_value=messages),
            ):
                transport = ASGITransport(app=app)
                async with AsyncClient(
                    transport=transport, base_url="http://test"
                ) as client:
                    response = await client.get(
                        "/support/contact-messages",
                        headers={"Authorization": "Bearer token"},
                    )
        finally:
            app.dependency_overrides.clear()

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["subject"] == "Question"
        assert data[0]["ip_address"] == "127.0.0.1"
