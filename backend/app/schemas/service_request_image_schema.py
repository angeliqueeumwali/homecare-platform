from uuid import UUID

from pydantic import BaseModel, ConfigDict


class ServiceRequestImageResponse(BaseModel):
    id: UUID
    service_request_id: UUID
    image_url: str
    original_filename: str | None
    model_config = ConfigDict(from_attributes=True)