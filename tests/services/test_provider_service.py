from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

import pytest

from app.core.enums import ProviderApprovalStatus
from app.models.provider_profile import ProviderProfile
from app.models.provider_service import ProviderService as ProviderServiceModel
from app.models.provider_location import ProviderLocation
from app.models.user import User
from app.services.provider_service import ProviderService


def create_test_user():
    return User(
        id=uuid4(),
        first_name="Provider",
        last_name="Test",
        email="provider.test@example.com",
        phone_number="0780000000",
        password_hash="hashed_password",
        role="SERVICE_PROVIDER",
        is_active=True,
    )


def create_test_provider(user_id=None):
    return ProviderProfile(
        id=uuid4(),
        user_id=user_id or uuid4(),
        business_name="Test Business",
        bio="Test Bio",
        is_available=True,
        approval_status=ProviderApprovalStatus.APPROVED,
    )


def create_test_service(provider_id, category_id):
    return ProviderServiceModel(
        id=uuid4(),
        provider_id=provider_id,
        service_category_id=category_id,
        is_active=True,
    )


def create_test_location(provider_id):
    return ProviderLocation(
        id=uuid4(),
        provider_id=provider_id,
        latitude=1.0,
        longitude=2.0,
        address="Test Address",
    )


@pytest.fixture(autouse=True)
def patch_provider_service_model():
    """Patch the ProviderService model reference in the service module to avoid naming conflict."""
    with patch("app.services.provider_service.ProviderService", ProviderServiceModel):
        yield


@pytest.mark.asyncio
async def test_create_profile():
    db = AsyncMock()
    user = create_test_user()
    created_provider = create_test_provider(user.id)

    with patch(
        "app.services.provider_service.ProviderRepository.get_by_user_id",
        new=AsyncMock(return_value=None),
    ), patch(
        "app.services.provider_service.ProviderRepository.create",
        new=AsyncMock(return_value=created_provider),
    ):
        result = await ProviderService.create_profile(db, user, "Test Business", "Test Bio")

    assert result == created_provider
    assert result.business_name == "Test Business"
    assert result.bio == "Test Bio"


@pytest.mark.asyncio
async def test_create_profile_already_exists():
    db = AsyncMock()
    user = create_test_user()
    existing_provider = create_test_provider(user.id)

    with patch(
        "app.services.provider_service.ProviderRepository.get_by_user_id",
        new=AsyncMock(return_value=existing_provider),
    ):
        with pytest.raises(ValueError, match="Provider profile already exists"):
            await ProviderService.create_profile(db, user, "Test Business", "Test Bio")


@pytest.mark.asyncio
async def test_get_my_profile():
    db = AsyncMock()
    user = create_test_user()
    provider = create_test_provider(user.id)

    with patch(
        "app.services.provider_service.ProviderRepository.get_by_user_id",
        new=AsyncMock(return_value=provider),
    ):
        result = await ProviderService.get_my_profile(db, user)

    assert result == provider


@pytest.mark.asyncio
async def test_get_my_profile_not_found():
    db = AsyncMock()
    user = create_test_user()

    with patch(
        "app.services.provider_service.ProviderRepository.get_by_user_id",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError, match="Provider profile not found"):
            await ProviderService.get_my_profile(db, user)


@pytest.mark.asyncio
async def test_update_profile():
    db = AsyncMock()
    provider = create_test_provider()
    updated_provider = create_test_provider()
    updated_provider.business_name = "Updated Business"
    updated_provider.bio = "Updated Bio"
    updated_provider.is_available = False

    with patch(
        "app.services.provider_service.ProviderRepository.create",
        new=AsyncMock(return_value=updated_provider),
    ):
        result = await ProviderService.update_profile(
            db, provider, "Updated Business", "Updated Bio", False
        )

    assert result == updated_provider
    assert result.business_name == "Updated Business"
    assert result.bio == "Updated Bio"
    assert result.is_available is False


@pytest.mark.asyncio
async def test_update_profile_not_approved_cannot_be_available():
    db = AsyncMock()
    provider = create_test_provider()
    provider.approval_status = ProviderApprovalStatus.PENDING

    with pytest.raises(ValueError, match="Provider must be approved before becoming available"):
        await ProviderService.update_profile(db, provider, None, None, True)


@pytest.mark.asyncio
async def test_add_service_new():
    db = AsyncMock()
    provider = create_test_provider()
    service = create_test_service(provider.id, uuid4())

    with patch(
        "app.services.provider_service.ProviderRepository.get_service",
        new=AsyncMock(return_value=None),
    ), patch(
        "app.services.provider_service.ProviderRepository.create_service",
        new=AsyncMock(return_value=service),
    ):
        result = await ProviderService.add_service(db, provider, service.service_category_id)

    assert result == service


@pytest.mark.asyncio
async def test_add_service_existing_reactivate():
    db = AsyncMock()
    provider = create_test_provider()
    existing_service = create_test_service(provider.id, uuid4())
    existing_service.is_active = False

    with patch(
        "app.services.provider_service.ProviderRepository.get_service",
        new=AsyncMock(return_value=existing_service),
    ), patch(
        "app.services.provider_service.ProviderRepository.create_service",
        new=AsyncMock(),
    ) as mock_create:
        result = await ProviderService.add_service(db, provider, existing_service.service_category_id)

    assert result == existing_service
    assert existing_service.is_active is True
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(existing_service)
    mock_create.assert_not_awaited()


@pytest.mark.asyncio
async def test_remove_service():
    db = AsyncMock()
    provider = create_test_provider()
    service = create_test_service(provider.id, uuid4())

    with patch(
        "app.services.provider_service.ProviderRepository.get_service",
        new=AsyncMock(return_value=service),
    ):
        await ProviderService.remove_service(db, provider, service.service_category_id)

    db.delete.assert_awaited_once()


@pytest.mark.asyncio
async def test_remove_service_not_found():
    db = AsyncMock()
    provider = create_test_provider()

    with patch(
        "app.services.provider_service.ProviderRepository.get_service",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError, match="Provider service not found"):
            await ProviderService.remove_service(db, provider, uuid4())


@pytest.mark.asyncio
async def test_set_location_new():
    db = AsyncMock()
    provider = create_test_provider()
    location = create_test_location(provider.id)

    with patch(
        "app.services.provider_service.ProviderRepository.get_location",
        new=AsyncMock(return_value=None),
    ), patch(
        "app.services.provider_service.ProviderRepository.save_location",
        new=AsyncMock(return_value=location),
    ):
        result = await ProviderService.set_location(db, provider, 1.0, 2.0, "Test Address")

    assert result == location


@pytest.mark.asyncio
async def test_set_location_existing():
    db = AsyncMock()
    provider = create_test_provider()
    existing_location = create_test_location(provider.id)

    with patch(
        "app.services.provider_service.ProviderRepository.get_location",
        new=AsyncMock(return_value=existing_location),
    ):
        result = await ProviderService.set_location(db, provider, 3.0, 4.0, "New Address")

    assert result == existing_location
    assert existing_location.latitude == 3.0
    assert existing_location.longitude == 4.0
    assert existing_location.address == "New Address"
    db.commit.assert_awaited_once()
    db.refresh.assert_awaited_once_with(existing_location)


@pytest.mark.asyncio
async def test_get_services():
    db = AsyncMock()
    provider = create_test_provider()
    services = [create_test_service(provider.id, uuid4()), create_test_service(provider.id, uuid4())]

    with patch(
        "app.services.provider_service.ProviderRepository.list_services",
        new=AsyncMock(return_value=services),
    ):
        result = await ProviderService.get_services(db, provider)

    assert result == services


@pytest.mark.asyncio
async def test_approve():
    db = AsyncMock()
    provider = create_test_provider()
    provider.approval_status = ProviderApprovalStatus.PENDING
    provider.is_available = False
    approved_provider = create_test_provider()
    approved_provider.approval_status = ProviderApprovalStatus.APPROVED
    approved_provider.is_available = True

    with patch(
        "app.services.provider_service.ProviderRepository.create",
        new=AsyncMock(return_value=approved_provider),
    ):
        result = await ProviderService.approve(db, provider, True)

    assert result == approved_provider
    assert result.approval_status == ProviderApprovalStatus.APPROVED


@pytest.mark.asyncio
async def test_reject():
    db = AsyncMock()
    provider = create_test_provider()
    provider.approval_status = ProviderApprovalStatus.PENDING
    provider.is_available = True
    rejected_provider = create_test_provider()
    rejected_provider.approval_status = ProviderApprovalStatus.REJECTED
    rejected_provider.is_available = False

    with patch(
        "app.services.provider_service.ProviderRepository.create",
        new=AsyncMock(return_value=rejected_provider),
    ):
        result = await ProviderService.approve(db, provider, False)

    assert result == rejected_provider
    assert result.approval_status == ProviderApprovalStatus.REJECTED
    assert result.is_available is False