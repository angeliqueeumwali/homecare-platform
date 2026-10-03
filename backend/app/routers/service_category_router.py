from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import require_roles
from app.core.enums import UserRole
from app.database.connection import get_db
from app.schemas.service_category_schema import ServiceCategoryCreate, ServiceCategoryUpdate, ServiceCategoryResponse
from app.services.service_category_service import ServiceCategoryService

router = APIRouter(prefix="/service-categories", tags=["Service Categories"])
admin = require_roles(UserRole.ADMIN)

@router.get("", response_model=list[ServiceCategoryResponse])
async def list_categories(db: AsyncSession = Depends(get_db)):
    return await ServiceCategoryService.list(db)

@router.get("/{category_id}", response_model=ServiceCategoryResponse)
async def get_category(category_id, db=Depends(get_db)):
    try:
        return await ServiceCategoryService.get(db, category_id)
    except ValueError as e:
        raise HTTPException(404, str(e))

@router.post("", response_model=ServiceCategoryResponse, status_code=201)
async def create_category(data: ServiceCategoryCreate, db=Depends(get_db), _: object = Depends(admin)):
    try:
        return await ServiceCategoryService.create(db, data.name, data.description, data.image_url)
    except ValueError as e:
        raise HTTPException(400, str(e))

@router.patch("/{category_id}", response_model=ServiceCategoryResponse)
async def update_category(category_id, data: ServiceCategoryUpdate, db=Depends(get_db), _: object = Depends(admin)):
    try:
        category = await ServiceCategoryService.get(db, category_id)
        return await ServiceCategoryService.update(db, category, data.name, data.description, data.image_url, data.is_active)
    except ValueError as e:
        raise HTTPException(400, str(e))

@router.delete("/{category_id}", status_code=204)
async def delete_category(category_id, db=Depends(get_db), _: object = Depends(admin)):
    try:
        category = await ServiceCategoryService.get(db, category_id)
        await ServiceCategoryService.delete(db, category)
    except ValueError as e:
        raise HTTPException(400, str(e))
