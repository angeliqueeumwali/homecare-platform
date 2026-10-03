from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class PasswordResetRequest(BaseModel):
    email: EmailStr


class PasswordResetConfirm(BaseModel):
    token: str = Field(min_length=20, max_length=512)
    new_password: str = Field(min_length=8, max_length=128)


class PasswordResetResponse(BaseModel):
    requested: bool
    expires_in_minutes: int
    email_delivery_configured: bool = False
    reset_url: str | None = None
    dev_token: str | None = None


class ContactSubmit(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    email: EmailStr
    subject: str = Field(min_length=3, max_length=200)
    message: str = Field(min_length=1, max_length=5000)
    honeypot: str = Field(default="", max_length=200)


class ContactResponse(BaseModel):
    id: UUID
    received: bool
    email_delivery_configured: bool = False


class ContactMessageResponse(BaseModel):
    id: UUID
    name: str
    email: str
    subject: str
    message: str
    ip_address: str | None
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)
