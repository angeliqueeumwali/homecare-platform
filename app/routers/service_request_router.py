from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_current_user, require_roles
from app.core.enums import UserRole
from app.database.connection import get_db
from app.models.user import User
from app.schemas.service_request_schema import ServiceRequestCreate, ServiceRequestResponse, ServiceRequestStatusUpdate
from app.schemas.service_request_image_schema import ServiceRequestImageResponse
from app.services.service_request_service import ServiceRequestService
from app.services.service_request_image_service import ServiceRequestImageService
from app.repositories.service_request_image_repository import ServiceRequestImageRepository

router = APIRouter(prefix="/service-requests", tags=["Service Requests"])
customer = require_roles(UserRole.CUSTOMER)


async def _owned_request(db, request_id, current_user):
    """Fetch a request and confirm the caller is allowed to see it."""
    try:
        request = await ServiceRequestService.get(db, request_id)
    except ValueError as e:
        raise HTTPException(404, str(e))
    if current_user.role != UserRole.ADMIN and request.customer_id != current_user.id:
        raise HTTPException(403, "You do not have access to this request")
    return request

@router.post("", response_model=ServiceRequestResponse, status_code=201)
async def create_request(data: ServiceRequestCreate, db=Depends(get_db), current_user: User=Depends(customer)):
    try:
        return await ServiceRequestService.create(db, current_user.id, data)
    except ValueError as e:
        raise HTTPException(400, str(e))

@router.get("/me", response_model=list[ServiceRequestResponse])
async def my_requests(db=Depends(get_db), current_user: User=Depends(get_current_user)):
    return await ServiceRequestService.customer_list(db, current_user.id)

@router.get("/{request_id}", response_model=ServiceRequestResponse)
async def get_request(request_id, db=Depends(get_db), current_user: User=Depends(get_current_user)):
    try:
        request = await ServiceRequestService.get(db, request_id)
        if current_user.role != UserRole.ADMIN and request.customer_id != current_user.id:
            raise HTTPException(403, "You do not have access to this request")
        return request
    except ValueError as e:
        raise HTTPException(404, str(e))

@router.patch("/{request_id}/status", response_model=ServiceRequestResponse)
async def update_status(request_id, data: ServiceRequestStatusUpdate, db=Depends(get_db), current_user: User=Depends(get_current_user)):
    try:
        request = await ServiceRequestService.get(db, request_id)
        if current_user.role != UserRole.ADMIN and request.customer_id != current_user.id:
            raise HTTPException(403, "You do not have access to this request")
        return await ServiceRequestService.update_status(db, request, data.status)
    except ValueError as e:
        raise HTTPException(400, str(e))

@router.get("", response_model=list[ServiceRequestResponse])
async def all_requests(db=Depends(get_db), _: object=Depends(require_roles(UserRole.ADMIN))):
    return await ServiceRequestService.all(db)


@router.get("/{request_id}/images", response_model=list[ServiceRequestImageResponse])
async def list_images(request_id, db=Depends(get_db), current_user: User=Depends(get_current_user)):
    await _owned_request(db, request_id, current_user)
    return await ServiceRequestImageService.list_for_request(db, request_id)


@router.post("/{request_id}/images", response_model=ServiceRequestImageResponse, status_code=201)
async def upload_image(
    request_id,
    file: UploadFile = File(...),
    db=Depends(get_db),
    current_user: User=Depends(get_current_user),
):
    await _owned_request(db, request_id, current_user)
    try:
        return await ServiceRequestImageService.upload(db, request_id, file)
    except ValueError as e:
        raise HTTPException(400, str(e))


@router.delete("/{request_id}/images/{image_id}", status_code=204)
async def delete_image(
    request_id,
    image_id,
    db=Depends(get_db),
    current_user: User=Depends(get_current_user),
):
    await _owned_request(db, request_id, current_user)

    image = await ServiceRequestImageRepository.get_by_id(db, image_id)
    # The path params arrive as strings while the columns are UUID objects,
    # so compare their string forms.
    if not image or str(image.service_request_id) != str(request_id):
        raise HTTPException(404, "Image not found for this request")

    await ServiceRequestImageService.delete(db, image)
