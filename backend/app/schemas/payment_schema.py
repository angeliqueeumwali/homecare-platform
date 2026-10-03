from decimal import Decimal
from uuid import UUID
from pydantic import ConfigDict, BaseModel, Field

class PaymentCreate(BaseModel):
    service_request_id: UUID
    quote_id: UUID
    amount: Decimal = Field(gt=0)
    currency: str = Field(default="RWF", min_length=3, max_length=10)
    payment_method: str

class PaymentResponse(BaseModel):
    id: UUID
    service_request_id: UUID
    quote_id: UUID
    customer_id: UUID
    amount: Decimal
    currency: str
    payment_method: str
    status: str
    transaction_reference: str | None
    model_config = ConfigDict(from_attributes=True)

class PaymentStatusUpdate(BaseModel):
    status: str
    transaction_reference: str | None = None
