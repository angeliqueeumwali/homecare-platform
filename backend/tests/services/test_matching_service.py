from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

import pytest

from app.core.enums import ProviderApprovalStatus
from app.models.provider_profile import ProviderProfile
from app.models.provider_location import ProviderLocation
from app.services.matching_service import MatchingService, calculate_distance_km


def test_calculate_distance_km():
    # Test with known coordinates (Kigali city center to another location)
    # This is a basic sanity check
    dist = calculate_distance_km(-1.9441, 30.0619, -1.9500, 30.0500)
    assert dist > 0
    assert isinstance(dist, float)


def test_calculate_distance_km_same_point():
    dist = calculate_distance_km(0.0, 0.0, 0.0, 0.0)
    assert dist == 0.0


@pytest.mark.asyncio
async def test_find_nearest_providers():
    db = Mock()
    service_category_id = uuid4()
    latitude = -1.9441
    longitude = 30.0619

    provider1 = ProviderProfile(
        id=uuid4(),
        user_id=uuid4(),
        business_name="Provider 1",
        bio="Bio 1",
        is_available=True,
        approval_status=ProviderApprovalStatus.APPROVED,
    )
    provider1.location = ProviderLocation(
        provider_id=provider1.id,
        latitude=-1.9500,
        longitude=30.0500,
    )

    provider2 = ProviderProfile(
        id=uuid4(),
        user_id=uuid4(),
        business_name="Provider 2",
        bio="Bio 2",
        is_available=True,
        approval_status=ProviderApprovalStatus.APPROVED,
    )
    provider2.location = ProviderLocation(
        provider_id=provider2.id,
        latitude=-1.9600,
        longitude=30.0400,
    )

    providers = [provider1, provider2]

    with patch(
        "app.services.matching_service.ProviderRepository.get_available_for_service",
        new=AsyncMock(return_value=providers),
    ):
        result = await MatchingService.find_nearest_providers(db, service_category_id, latitude, longitude)

    assert len(result) == 2
    assert "provider" in result[0]
    assert "distance_km" in result[0]
    assert "provider" in result[1]
    assert "distance_km" in result[1]
    # Results should be sorted by distance
    assert result[0]["distance_km"] <= result[1]["distance_km"]


@pytest.mark.asyncio
async def test_find_nearest_providers_excludes_not_approved():
    db = Mock()
    service_category_id = uuid4()
    latitude = -1.9441
    longitude = 30.0619

    provider1 = ProviderProfile(
        id=uuid4(),
        user_id=uuid4(),
        business_name="Provider 1",
        bio="Bio 1",
        is_available=True,
        approval_status=ProviderApprovalStatus.APPROVED,
    )
    provider1.location = ProviderLocation(
        provider_id=provider1.id,
        latitude=-1.9500,
        longitude=30.0500,
    )

    provider2 = ProviderProfile(
        id=uuid4(),
        user_id=uuid4(),
        business_name="Provider 2",
        bio="Bio 2",
        is_available=True,
        approval_status=ProviderApprovalStatus.PENDING,
    )
    provider2.location = ProviderLocation(
        provider_id=provider2.id,
        latitude=-1.9600,
        longitude=30.0400,
    )

    providers = [provider1, provider2]

    with patch(
        "app.services.matching_service.ProviderRepository.get_available_for_service",
        new=AsyncMock(return_value=providers),
    ):
        result = await MatchingService.find_nearest_providers(db, service_category_id, latitude, longitude)

    assert len(result) == 1
    assert result[0]["provider"].id == provider1.id


@pytest.mark.asyncio
async def test_find_nearest_providers_excludes_no_location():
    db = Mock()
    service_category_id = uuid4()
    latitude = -1.9441
    longitude = 30.0619

    provider1 = ProviderProfile(
        id=uuid4(),
        user_id=uuid4(),
        business_name="Provider 1",
        bio="Bio 1",
        is_available=True,
        approval_status=ProviderApprovalStatus.APPROVED,
    )
    provider1.location = ProviderLocation(
        provider_id=provider1.id,
        latitude=-1.9500,
        longitude=30.0500,
    )

    provider2 = ProviderProfile(
        id=uuid4(),
        user_id=uuid4(),
        business_name="Provider 2",
        bio="Bio 2",
        is_available=True,
        approval_status=ProviderApprovalStatus.APPROVED,
    )
    provider2.location = None

    providers = [provider1, provider2]

    with patch(
        "app.services.matching_service.ProviderRepository.get_available_for_service",
        new=AsyncMock(return_value=providers),
    ):
        result = await MatchingService.find_nearest_providers(db, service_category_id, latitude, longitude)

    assert len(result) == 1
    assert result[0]["provider"].id == provider1.id


@pytest.mark.asyncio
async def test_find_nearest_providers_empty():
    db = Mock()
    service_category_id = uuid4()
    latitude = -1.9441
    longitude = 30.0619

    with patch(
        "app.services.matching_service.ProviderRepository.get_available_for_service",
        new=AsyncMock(return_value=[]),
    ):
        result = await MatchingService.find_nearest_providers(db, service_category_id, latitude, longitude)

    assert result == []