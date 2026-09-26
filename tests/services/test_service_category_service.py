from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

import pytest

from app.models.service_category import ServiceCategory
from app.services.service_category_service import ServiceCategoryService


def create_test_category():
    return ServiceCategory(
        id=uuid4(),
        name="Cleaning",
        description="Cleaning services",
        is_active=True,
    )


@pytest.mark.asyncio
async def test_create_service_category():
    db = Mock()
    category = create_test_category()

    with patch(
        "app.services.service_category_service.ServiceCategoryRepository.get_by_name",
        new=AsyncMock(return_value=None),
    ), patch(
        "app.services.service_category_service.ServiceCategoryRepository.create",
        new=AsyncMock(return_value=category),
    ):
        result = await ServiceCategoryService.create(db, "Cleaning", "Cleaning services")

    assert result == category
    assert result.name == "Cleaning"
    assert result.description == "Cleaning services"


@pytest.mark.asyncio
async def test_create_service_category_duplicate():
    db = Mock()
    existing_category = create_test_category()

    with patch(
        "app.services.service_category_service.ServiceCategoryRepository.get_by_name",
        new=AsyncMock(return_value=existing_category),
    ):
        with pytest.raises(ValueError, match="Service category already exists"):
            await ServiceCategoryService.create(db, "Cleaning", "Cleaning services")


@pytest.mark.asyncio
async def test_get_service_category():
    db = Mock()
    category = create_test_category()

    with patch(
        "app.services.service_category_service.ServiceCategoryRepository.get_by_id",
        new=AsyncMock(return_value=category),
    ):
        result = await ServiceCategoryService.get(db, category.id)

    assert result == category


@pytest.mark.asyncio
async def test_get_service_category_not_found():
    db = Mock()

    with patch(
        "app.services.service_category_service.ServiceCategoryRepository.get_by_id",
        new=AsyncMock(return_value=None),
    ):
        with pytest.raises(ValueError, match="Service category not found"):
            await ServiceCategoryService.get(db, uuid4())


@pytest.mark.asyncio
async def test_list_service_categories():
    db = Mock()
    categories = [create_test_category(), create_test_category()]

    with patch(
        "app.services.service_category_service.ServiceCategoryRepository.get_all",
        new=AsyncMock(return_value=categories),
    ):
        result = await ServiceCategoryService.list(db)

    assert result == categories


@pytest.mark.asyncio
async def test_update_service_category():
    db = Mock()
    category = create_test_category()
    updated_category = create_test_category()
    updated_category.name = "Updated Cleaning"
    updated_category.description = "Updated description"
    updated_category.is_active = False

    with patch(
        "app.services.service_category_service.ServiceCategoryRepository.get_by_name",
        new=AsyncMock(return_value=None),
    ), patch(
        "app.services.service_category_service.ServiceCategoryRepository.update",
        new=AsyncMock(return_value=updated_category),
    ):
        result = await ServiceCategoryService.update(db, category, "Updated Cleaning", "Updated description", False)

    assert result == updated_category
    assert result.name == "Updated Cleaning"
    assert result.description == "Updated description"
    assert result.is_active is False


@pytest.mark.asyncio
async def test_update_service_category_duplicate_name():
    db = Mock()
    category = create_test_category()
    other_category = create_test_category()
    other_category.id = uuid4()

    with patch(
        "app.services.service_category_service.ServiceCategoryRepository.get_by_name",
        new=AsyncMock(return_value=other_category),
    ):
        with pytest.raises(ValueError, match="Service category already exists"):
            await ServiceCategoryService.update(db, category, "Other Category", None, None)


@pytest.mark.asyncio
async def test_update_service_category_same_name():
    db = Mock()
    category = create_test_category()

    with patch(
        "app.services.service_category_service.ServiceCategoryRepository.get_by_name",
        new=AsyncMock(return_value=category),
    ), patch(
        "app.services.service_category_service.ServiceCategoryRepository.update",
        new=AsyncMock(return_value=category),
    ):
        result = await ServiceCategoryService.update(db, category, "Cleaning", "New description", None)

    assert result == category
    assert result.description == "New description"


@pytest.mark.asyncio
async def test_delete_service_category():
    db = Mock()
    category = create_test_category()

    with patch(
        "app.services.service_category_service.ServiceCategoryRepository.delete",
        new=AsyncMock(),
    ) as mock_delete:
        await ServiceCategoryService.delete(db, category)

    mock_delete.assert_awaited_once_with(db, category)