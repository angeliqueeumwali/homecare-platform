from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field

class ServiceCategoryCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    description: str | None = None
    image_url: str | None = Field(default=None, max_length=500)

class ServiceCategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)
    description: str | None = None
    image_url: str | None = Field(default=None, max_length=500)
    is_active: bool | None = None

class ServiceCategoryResponse(BaseModel):
    id: UUID
    name: str
    description: str | None
    image_url: str | None
    is_active: bool
    model_config = ConfigDict(from_attributes=True)
