import uuid

from sqlalchemy import Boolean, DateTime, Enum, Float, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.enums import ProviderApprovalStatus
from app.database.base import Base


class ProviderProfile(Base):
    __tablename__ = "provider_profiles"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )

    business_name: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    bio: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    approval_status: Mapped[ProviderApprovalStatus] = mapped_column(
        Enum(
            ProviderApprovalStatus,
            name="provider_approval_status",
        ),
        default=ProviderApprovalStatus.PENDING,
        nullable=False,
    )

    is_available: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )

    average_rating: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
    )

    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    user = relationship(
        "User",
        back_populates="provider_profile",
    )

    services = relationship(
        "ProviderService",
        back_populates="provider",
        cascade="all, delete-orphan",
    )

    location = relationship(
        "ProviderLocation",
        back_populates="provider",
        uselist=False,
        cascade="all, delete-orphan",


    )

    assignments = relationship(
        "Assignment",
        back_populates="provider",
    )

    reviews_received = relationship(
        "Review",
        back_populates="provider",
    )
    quotes = relationship(
    "Quote",
    back_populates="provider",
)