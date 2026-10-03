import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.enums import ServiceRequestStatus
from app.database.base import Base


class ServiceRequest(Base):
    __tablename__ = "service_requests"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey(
            "users.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    status: Mapped[ServiceRequestStatus] = mapped_column(
        Enum(
            ServiceRequestStatus,
            name="service_request_status",
        ),
        nullable=False,
        default=ServiceRequestStatus.PENDING,
        index=True,
    )

    address: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    latitude: Mapped[float] = mapped_column(
        Numeric(9, 6),
        nullable=False,
    )

    longitude: Mapped[float] = mapped_column(
        Numeric(9, 6),
        nullable=False,
    )

    preferred_date: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    notes: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    customer = relationship(
        "User",
        back_populates="service_requests",
    )

    items = relationship(
        "ServiceRequestItem",
        back_populates="service_request",
        cascade="all, delete-orphan",
    )

    assignments = relationship(
        "Assignment",
        back_populates="service_request",
    )

    quotes = relationship(
        "Quote",
        back_populates="service_request",
    )

    payments = relationship(
        "Payment",
        back_populates="service_request",
    )

    issues = relationship(
        "Issue",
        back_populates="service_request",
    )

    images = relationship(
        "ServiceRequestImage",
        back_populates="service_request",
        cascade="all, delete-orphan",
    )