from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field

class ProviderProfileCreate(BaseModel):
    business_name: str | None = Field(default=None, max_length=255)
    bio: str | None = None

class ProviderProfileUpdate(BaseModel):
    business_name: str | None = Field(default=None, max_length=255)
    bio: str | None = None
    is_available: bool | None = None

class ProviderProfileResponse(BaseModel):
    id: UUID
    user_id: UUID
    business_name: str | None
    bio: str | None
    approval_status: str
    is_available: bool
    average_rating: float | None
    model_config = ConfigDict(from_attributes=True)

class ProviderServiceCreate(BaseModel):
    service_category_id: UUID

class ProviderServiceResponse(BaseModel):
    id: UUID
    provider_id: UUID
    service_category_id: UUID
    is_active: bool
    model_config = ConfigDict(from_attributes=True)

class ProviderLocationCreate(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    address: str | None = Field(default=None, max_length=255)

class ProviderLocationResponse(BaseModel):
    id: UUID
    provider_id: UUID
    latitude: float
    longitude: float
    address: str | None
    model_config = ConfigDict(from_attributes=True)

class ProviderApprovalRequest(BaseModel):
    approved: bool
