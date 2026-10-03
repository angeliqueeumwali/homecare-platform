from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserUpdateRequest(BaseModel):
    first_name: str | None = Field(
        default=None,
        min_length=2,
        max_length=100,
    )

    last_name: str | None = Field(
        default=None,
        min_length=2,
        max_length=100,
    )

    phone_number: str | None = Field(
        default=None,
        min_length=7,
        max_length=30,
    )


class UserResponse(BaseModel):
    id: UUID
    first_name: str
    last_name: str
    email: EmailStr
    phone_number: str
    role: str
    is_active: bool

    model_config = ConfigDict(from_attributes=True)