import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.enums import AssignmentStatus
from app.database.base import Base


class Assignment(Base):
    __tablename__ = "assignments"

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

    service_request_item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey(
            "service_request_items.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    provider_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey(
            "provider_profiles.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    status: Mapped[AssignmentStatus] = mapped_column(
        Enum(
            AssignmentStatus,
            name="assignment_status",
        ),
        nullable=False,
        default=AssignmentStatus.PENDING,
        index=True,
    )

    assigned_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    accepted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    service_request = relationship(
        "ServiceRequest",
        back_populates="assignments",
    )

    service_request_item = relationship(
        "ServiceRequestItem",
        back_populates="assignments",
    )

    provider = relationship(
        "ProviderProfile",
        back_populates="assignments",
    )
    review = relationship(
        "Review",
        back_populates="assignment",
        uselist=False,
        cascade="all, delete-orphan",
    )
    issues = relationship(
        "Issue",
        back_populates="assignment",
    )