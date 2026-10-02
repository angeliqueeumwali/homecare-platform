from app.models.service_category import ServiceCategory
from app.repositories.service_category_repository import ServiceCategoryRepository

class ServiceCategoryService:
    @staticmethod
    async def create(db, name, description=None, image_url=None):
        if await ServiceCategoryRepository.get_by_name(db, name):
            raise ValueError("Service category already exists")
        return await ServiceCategoryRepository.create(
            db,
            ServiceCategory(name=name, description=description, image_url=image_url),
        )

    @staticmethod
    async def get(db, category_id):
        category = await ServiceCategoryRepository.get_by_id(db, category_id)
        if not category:
            raise ValueError("Service category not found")
        return category

    @staticmethod
    async def list(db):
        return await ServiceCategoryRepository.get_all(db)

    @staticmethod
    async def update(db, category, name=None, description=None, image_url=None, is_active=None):
        if name is not None and name != category.name:
            if await ServiceCategoryRepository.get_by_name(db, name):
                raise ValueError("Service category already exists")
            category.name = name
        if description is not None:
            category.description = description
        if image_url is not None:
            category.image_url = image_url
        if is_active is not None:
            category.is_active = is_active
        return await ServiceCategoryRepository.update(db, category)

    @staticmethod
    async def delete(db, category):
        await ServiceCategoryRepository.delete(db, category)
