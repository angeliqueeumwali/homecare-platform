from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

import pytest

from app.models.support import ContactMessage
from app.services.contact_service import ContactService


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


@pytest.mark.asyncio
async def test_submit_stores_message():
    db = Mock()
    message = mock_contact_message()

    with patch(
        "app.services.contact_service"
        ".SupportRepository.count_recent_contact_messages",
        new=AsyncMock(return_value=0),
    ) as mock_count, patch(
        "app.services.contact_service"
        ".SupportRepository.create_contact_message",
        new=AsyncMock(return_value=message),
    ) as mock_create:
        result = await ContactService.submit(
            db,
            name="Test User",
            email="test@example.com",
            subject="Question",
            message="I have a question about my booking",
            ip_address="127.0.0.1",
            honeypot="",
        )

    assert result["received"] is True
    assert result["id"] == message.id
    assert result["email_delivery_configured"] is False
    mock_create.assert_awaited_once_with(
        db,
        name="Test User",
        email="test@example.com",
        subject="Question",
        message="I have a question about my booking",
        ip_address="127.0.0.1",
    )


@pytest.mark.asyncio
async def test_submit_rejects_honeypot():
    db = Mock()

    with patch(
        "app.services.contact_service"
        ".SupportRepository.create_contact_message",
        new=AsyncMock(),
    ) as mock_create:
        with pytest.raises(ValueError):
            await ContactService.submit(
                db,
                name="Test User",
                email="test@example.com",
                subject="Question",
                message="I have a question about my booking",
                ip_address="127.0.0.1",
                honeypot="spam",
            )

    mock_create.assert_not_awaited()


@pytest.mark.asyncio
async def test_submit_rejects_short_message():
    db = Mock()

    with patch(
        "app.services.contact_service"
        ".SupportRepository.count_recent_contact_messages",
        new=AsyncMock(return_value=0),
    ), patch(
        "app.services.contact_service"
        ".SupportRepository.create_contact_message",
        new=AsyncMock(),
    ) as mock_create:
        with pytest.raises(ValueError):
            await ContactService.submit(
                db,
                name="Test User",
                email="test@example.com",
                subject="Question",
                message="short",
                ip_address="127.0.0.1",
                honeypot="",
            )

    mock_create.assert_not_awaited()


@pytest.mark.asyncio
async def test_submit_enforces_rate_limit():
    db = Mock()
    since = datetime.now(timezone.utc) - timedelta(hours=1)

    with patch(
        "app.services.contact_service"
        ".SupportRepository.count_recent_contact_messages",
        new=AsyncMock(return_value=5),
    ) as mock_count, patch(
        "app.services.contact_service"
        ".SupportRepository.create_contact_message",
        new=AsyncMock(),
    ) as mock_create:
        with pytest.raises(ValueError):
            await ContactService.submit(
                db,
                name="Test User",
                email="test@example.com",
                subject="Question",
                message="I have a question about my booking",
                ip_address="127.0.0.1",
                honeypot="",
            )

    args, kwargs = mock_count.await_args
    assert args[0] is db
    assert args[1] == "127.0.0.1"
    assert args[2] > since
    mock_create.assert_not_awaited()


@pytest.mark.asyncio
async def test_submit_allows_under_limit():
    db = Mock()

    with patch(
        "app.services.contact_service"
        ".SupportRepository.count_recent_contact_messages",
        new=AsyncMock(return_value=4),
    ), patch(
        "app.services.contact_service"
        ".SupportRepository.create_contact_message",
        new=AsyncMock(return_value=mock_contact_message()),
    ):
        result = await ContactService.submit(
            db,
            name="Test User",
            email="test@example.com",
            subject="Question",
            message="I have a question about my booking",
            ip_address="127.0.0.1",
            honeypot="",
        )

    assert result["received"] is True
