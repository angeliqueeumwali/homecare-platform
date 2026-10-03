import uuid

from sqlalchemy import DateTime, Enum, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.enums import ServiceRequestItemStatus
from app.database.base import Base


class ServiceRequestItem(Base):
    __tablename__ = "service_request_items"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    service_request_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey(
            "service_requests.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    service_category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey(
            "service_categories.id",
            ondelete="RESTRICT",
        ),
        nullable=False,
        index=True,
    )

    status: Mapped[ServiceRequestItemStatus] = mapped_column(
        Enum(
            ServiceRequestItemStatus,
            name="service_request_item_status",
        ),
        nullable=False,
        default=ServiceRequestItemStatus.PENDING,
        index=True,
    )

    notes: Mapped[str | None] = mapped_column(
        Text,
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

    service_request = relationship(
        "ServiceRequest",
        back_populates="items",
    )

    service_category = relationship(
        "ServiceCategory",
        back_populates="request_items",
    )

    assignments = relationship(
        "Assignment",
        back_populates="service_request_item",
    )

    quotes = relationship(
        "Quote",
        back_populates="service_request_item",
    )