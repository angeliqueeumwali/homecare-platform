from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field

class ServiceRequestItemCreate(BaseModel):
    service_category_id: UUID
    notes: str | None = None

class ServiceRequestCreate(BaseModel):
    address: str = Field(min_length=2, max_length=255)
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    preferred_date: datetime | None = None
    notes: str | None = None
    items: list[ServiceRequestItemCreate] = Field(min_length=1)

class ServiceRequestItemResponse(BaseModel):
    id: UUID
    service_request_id: UUID
    service_category_id: UUID
    status: str
    notes: str | None
    model_config = ConfigDict(from_attributes=True)

class ServiceRequestResponse(BaseModel):
    id: UUID
    customer_id: UUID
    status: str
    address: str
    latitude: float
    longitude: float
    preferred_date: datetime | None
    notes: str | None
    items: list[ServiceRequestItemResponse] = []
    model_config = ConfigDict(from_attributes=True)

class ServiceRequestStatusUpdate(BaseModel):
    status: str
