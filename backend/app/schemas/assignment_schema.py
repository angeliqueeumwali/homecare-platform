from uuid import UUID
from pydantic import ConfigDict, BaseModel

class AssignmentCreate(BaseModel):
    service_request_id: UUID
    service_request_item_id: UUID
    provider_id: UUID

class AssignmentResponse(BaseModel):
    id: UUID
    service_request_id: UUID
    service_request_item_id: UUID
    provider_id: UUID
    status: str
    model_config = ConfigDict(from_attributes=True)

class AssignmentStatusUpdate(BaseModel):
    status: str
