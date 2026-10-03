import uuid

from sqlalchemy import DateTime, ForeignKey, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.database.base import Base


class ProviderLocation(Base):
    __tablename__ = "provider_locations"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    provider_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey(
            "provider_profiles.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        unique=True,
    )

    latitude: Mapped[float] = mapped_column(
        Numeric(9, 6),
        nullable=False,
    )

    longitude: Mapped[float] = mapped_column(
        Numeric(9, 6),
        nullable=False,
    )

    address: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    provider = relationship(
        "ProviderProfile",
        back_populates="location",
    )