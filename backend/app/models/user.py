import uuid
from datetime import datetime
from sqlalchemy import Boolean, DateTime, Enum, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.core.enums import UserRole
from app.database.base import Base

class User(Base):
    __tablename__ = "users"
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    first_name: Mapped[str] = mapped_column(String(100), nullable=False)
    last_name: Mapped[str] = mapped_column(String(100), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    phone_number: Mapped[str] = mapped_column(String(30), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole, name="user_role"), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    provider_profile = relationship("ProviderProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    service_requests = relationship("ServiceRequest", back_populates="customer")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    reviews_given = relationship("Review", foreign_keys="Review.customer_id", back_populates="customer")
    payments = relationship("Payment", back_populates="customer")
    issues_reported = relationship("Issue", back_populates="reported_by")
