from fastapi import APIRouter, Depends, HTTPException
from app.core.dependencies import get_current_user, require_roles
from app.core.enums import UserRole
from app.database.connection import get_db
from app.models.user import User
from app.schemas.payment_schema import PaymentCreate, PaymentResponse, PaymentStatusUpdate
from app.services.payment_service import PaymentService

router = APIRouter(prefix="/payments", tags=["Payments"])

@router.post("", response_model=PaymentResponse, status_code=201)
async def create_payment(data: PaymentCreate, db=Depends(get_db), current_user: User=Depends(require_roles(UserRole.CUSTOMER))):
    try:
        return await PaymentService.create(db, current_user.id, data)
    except ValueError as e:
        raise HTTPException(400, str(e))

@router.get("/me", response_model=list[PaymentResponse])
async def my_payments(db=Depends(get_db), current_user: User=Depends(require_roles(UserRole.CUSTOMER))):
    return await PaymentService.list_customer(db, current_user.id)

@router.patch("/{payment_id}/status", response_model=PaymentResponse)
async def update_payment(payment_id, data: PaymentStatusUpdate, db=Depends(get_db), _: object=Depends(require_roles(UserRole.ADMIN))):
    from app.repositories.payment_repository import PaymentRepository
    try:
        payment = await PaymentRepository.get_by_id(db, payment_id)
        if not payment:
            raise ValueError("Payment not found")
        return await PaymentService.update_status(db, payment, data.status, data.transaction_reference)
    except ValueError as e:
        raise HTTPException(400, str(e))
