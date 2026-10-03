from fastapi import APIRouter, Depends, HTTPException
from app.core.dependencies import get_current_user
from app.database.connection import get_db
from app.models.user import User
from app.schemas.notification_schema import NotificationResponse
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["Notifications"])

@router.get("", response_model=list[NotificationResponse])
async def notifications(db=Depends(get_db), current_user: User=Depends(get_current_user)):
    return await NotificationService.list_user(db, current_user.id)

@router.patch("/{notification_id}/read", response_model=NotificationResponse)
async def mark_read(notification_id, db=Depends(get_db), current_user: User=Depends(get_current_user)):
    try:
        return await NotificationService.mark_read(db, notification_id, current_user.id)
    except ValueError as e:
        raise HTTPException(404, str(e))
