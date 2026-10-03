import uuid


from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.database.base import Base
from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    UniqueConstraint,
)


class ProviderService(Base):
    __tablename__ = "provider_services"
    __table_args__ = (
    UniqueConstraint(
        "provider_id",
        "service_category_id",
        name="uq_provider_service",
    ),
)

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
    )

    service_category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey(
            "service_categories.id",
            ondelete="CASCADE",
        ),
        nullable=False,
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
    )

    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    provider = relationship(
        "ProviderProfile",
        back_populates="services",
    )

    service_category = relationship(
        "ServiceCategory",
        back_populates="providers",
    )