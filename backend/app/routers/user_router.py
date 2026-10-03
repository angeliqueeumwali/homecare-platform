from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.database.connection import get_db
from app.models.user import User
from app.schemas.user_schema import (
    UserResponse,
    UserUpdateRequest,
)
from app.services.user_service import UserService


router = APIRouter(
    prefix="/users",
    tags=["Users"],
)


@router.get(
    "/me",
    response_model=UserResponse,
)
async def get_profile(
    current_user: User = Depends(get_current_user),
):
    return current_user


@router.patch(
    "/me",
    response_model=UserResponse,
)
async def update_profile(
    data: UserUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):

    try:
        return await UserService.update_user(
            db=db,
            user=current_user,
            first_name=data.first_name,
            last_name=data.last_name,
            phone_number=data.phone_number,
        )

    except ValueError as error:
        raise HTTPException(
            status_code=400,
            detail=str(error),
        )