from fastapi import APIRouter, Depends, HTTPException
from app.core.dependencies import get_current_user, require_roles
from app.core.enums import UserRole
from app.database.connection import get_db
from app.models.user import User
from app.schemas.quote_schema import QuoteCreate, QuoteResponse, QuoteStatusUpdate
from app.services.quote_service import QuoteService
from app.services.provider_service import ProviderService

router = APIRouter(prefix="/quotes", tags=["Quotes"])

@router.post("", response_model=QuoteResponse, status_code=201)
async def create_quote(data: QuoteCreate, db=Depends(get_db), current_user: User=Depends(require_roles(UserRole.SERVICE_PROVIDER))):
    try:
        provider = await ProviderService.get_my_profile(db, current_user)
        return await QuoteService.create(db, provider.id, data)
    except ValueError as e:
        raise HTTPException(400, str(e))

@router.get("/request/{request_id}", response_model=list[QuoteResponse])
async def request_quotes(request_id, db=Depends(get_db), current_user: User=Depends(get_current_user)):
    return await QuoteService.list_for_request(db, request_id)

@router.patch("/{quote_id}/status", response_model=QuoteResponse)
async def update_quote(quote_id, data: QuoteStatusUpdate, db=Depends(get_db), current_user: User=Depends(get_current_user)):
    try:
        quote = await QuoteService.get(db, quote_id)
        if current_user.role == UserRole.SERVICE_PROVIDER:
            provider = await ProviderService.get_my_profile(db, current_user)
            if quote.provider_id != provider.id:
                raise HTTPException(403, "Access denied")
        elif current_user.role == UserRole.CUSTOMER:
            if quote.service_request.customer_id != current_user.id:
                raise HTTPException(403, "Access denied")
        elif current_user.role != UserRole.ADMIN:
            raise HTTPException(403, "Access denied")
        return await QuoteService.update_status(db, quote, data.status)
    except ValueError as e:
        raise HTTPException(400, str(e))
