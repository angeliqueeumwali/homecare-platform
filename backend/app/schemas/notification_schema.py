from uuid import UUID
from pydantic import BaseModel, ConfigDict

class NotificationResponse(BaseModel):
    id: UUID
    user_id: UUID
    notification_type: str
    title: str
    message: str
    reference_id: UUID | None
    is_read: bool
    model_config = ConfigDict(from_attributes=True)
