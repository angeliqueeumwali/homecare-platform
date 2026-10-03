from uuid import UUID
from pydantic import ConfigDict, BaseModel, Field

class ReviewCreate(BaseModel):
    assignment_id: UUID
    rating: int = Field(ge=1, le=5)
    comment: str | None = None

class ReviewResponse(BaseModel):
    id: UUID
    customer_id: UUID
    provider_id: UUID
    assignment_id: UUID
    rating: int
    comment: str | None
    model_config = ConfigDict(from_attributes=True)
