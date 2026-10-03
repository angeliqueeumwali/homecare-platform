from uuid import UUID
from pydantic import ConfigDict, BaseModel, Field

class IssueCreate(BaseModel):
    service_request_id: UUID
    assignment_id: UUID | None = None
    title: str = Field(min_length=2, max_length=255)
    description: str = Field(min_length=2)

class IssueResponse(BaseModel):
    id: UUID
    service_request_id: UUID
    assignment_id: UUID | None
    reported_by_id: UUID
    title: str
    description: str
    status: str
    resolution: str | None
    model_config = ConfigDict(from_attributes=True)

class IssueResolveRequest(BaseModel):
    resolution: str = Field(min_length=2)
