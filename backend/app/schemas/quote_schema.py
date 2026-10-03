from decimal import Decimal
from uuid import UUID
from pydantic import ConfigDict, BaseModel, Field

class QuoteCreate(BaseModel):
    service_request_id: UUID
    service_request_item_id: UUID
    amount: Decimal = Field(gt=0)
    currency: str = Field(default="RWF", min_length=3, max_length=10)
    description: str | None = None

class QuoteResponse(BaseModel):
    id: UUID
    service_request_id: UUID
    service_request_item_id: UUID
    provider_id: UUID
    amount: Decimal
    currency: str
    status: str
    description: str | None
    model_config = ConfigDict(from_attributes=True)

class QuoteStatusUpdate(BaseModel):
    status: str
