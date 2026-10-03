from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import require_roles
from app.core.enums import UserRole
from app.database.connection import get_db
from app.schemas.support_schema import (
    ContactMessageResponse,
    ContactSubmit,
    ContactResponse,
)
from app.services.contact_service import ContactService
from app.repositories.support_repository import SupportRepository

router = APIRouter(prefix="/support", tags=["Support"])


@router.post("/contact", response_model=ContactResponse)
async def submit_contact(
    data: ContactSubmit,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    client_ip = request.client.host if request.client else None
    try:
        return await ContactService.submit(
            db,
            name=data.name,
            email=data.email,
            subject=data.subject,
            message=data.message,
            ip_address=client_ip,
            honeypot=data.honeypot,
        )
    except ValueError as e:
        raise HTTPException(400, str(e))


@router.get(
    "/contact-messages",
    response_model=list[ContactMessageResponse],
)
async def contact_messages(
    db: AsyncSession = Depends(get_db),
    _: object = Depends(require_roles(UserRole.ADMIN)),
):
    return await SupportRepository.list_contact_messages(db)
