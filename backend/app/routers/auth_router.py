from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_current_user
from app.database.connection import get_db
from app.models.user import User
from app.schemas.auth_schema import RegisterRequest, LoginRequest, TokenResponse, UserResponse
from app.schemas.support_schema import PasswordResetConfirm, PasswordResetRequest, PasswordResetResponse
from app.services.auth_service import AuthService
from app.services.password_reset_service import PasswordResetService

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(data: RegisterRequest, db: AsyncSession = Depends(get_db)):
    try:
        return await AuthService.register_user(db, data.first_name, data.last_name, data.email, data.phone_number, data.password)
    except ValueError as e:
        raise HTTPException(400, str(e))

@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, db: AsyncSession = Depends(get_db)):
    try:
        return {"access_token": await AuthService.login_user(db, data.email, data.password), "token_type": "bearer"}
    except ValueError as e:
        raise HTTPException(401, str(e), headers={"WWW-Authenticate": "Bearer"})

@router.get("/me", response_model=UserResponse)
async def me(current_user: User = Depends(get_current_user)):
    return current_user

@router.post("/password-reset/request", response_model=PasswordResetResponse)
async def password_reset_request(
    data: PasswordResetRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    base_url = str(request.base_url)
    return await PasswordResetService.request_reset(db, data.email, base_url)

@router.post("/password-reset/confirm")
async def password_reset_confirm(
    data: PasswordResetConfirm,
    db: AsyncSession = Depends(get_db),
):
    try:
        user = await PasswordResetService.confirm_reset(db, data.token, data.new_password)
    except ValueError as e:
        raise HTTPException(400, str(e))
    return {"success": True, "user_id": str(user.id)}
