import uuid
from datetime import datetime
from decimal import Decimal
from sqlalchemy import DateTime, Enum, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.core.enums import QuoteStatus
from app.database.base import Base

class Quote(Base):
    __tablename__ = "quotes"
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    service_request_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("service_requests.id", ondelete="CASCADE"), nullable=False, index=True)
    service_request_item_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("service_request_items.id", ondelete="CASCADE"), nullable=False, index=True)
    provider_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("provider_profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(10), nullable=False)
    status: Mapped[QuoteStatus] = mapped_column(Enum(QuoteStatus, name="quote_status"), default=QuoteStatus.PENDING, nullable=False, index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    service_request = relationship("ServiceRequest", back_populates="quotes")
    service_request_item = relationship("ServiceRequestItem", back_populates="quotes")
    provider = relationship("ProviderProfile", back_populates="quotes")
    payments = relationship("Payment", back_populates="quote")
