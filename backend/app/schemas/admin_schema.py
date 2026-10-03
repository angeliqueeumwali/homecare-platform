from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, field_validator

from app.models.assignment import Assignment
from app.models.issue import Issue
from app.models.notification import Notification
from app.models.payment import Payment
from app.models.provider_location import ProviderLocation
from app.models.provider_profile import ProviderProfile
from app.models.provider_service import ProviderService
from app.models.quote import Quote
from app.models.review import Review
from app.models.service_request import ServiceRequest
from app.models.service_request_item import ServiceRequestItem
from app.models.user import User


class UserSummaryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    first_name: str
    last_name: str
    email: str
    phone_number: str
    role: str
    is_active: bool


class ProviderSummaryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    business_name: str | None
    bio: str | None
    approval_status: str
    is_available: bool
    average_rating: float | None
    created_at: datetime


class ServiceRequestSummaryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    customer_id: UUID
    status: str
    address: str
    preferred_date: datetime | None
    created_at: datetime


class QuoteSummaryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    service_request_id: UUID
    service_request_item_id: UUID
    provider_id: UUID
    amount: str
    currency: str
    status: str
    description: str | None
    created_at: datetime

    @field_validator("amount", mode="before")
    @classmethod
    def amount_to_str(cls, value):
        return str(value) if value is not None else value


class PaymentSummaryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    service_request_id: UUID
    quote_id: UUID
    customer_id: UUID
    amount: str
    currency: str
    payment_method: str
    status: str
    transaction_reference: str | None
    created_at: datetime

    @field_validator("amount", mode="before")
    @classmethod
    def amount_to_str(cls, value):
        return str(value) if value is not None else value


class ReviewSummaryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    customer_id: UUID
    provider_id: UUID
    assignment_id: UUID
    rating: int
    comment: str | None
    created_at: datetime


class IssueSummaryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    service_request_id: UUID
    assignment_id: UUID | None
    reported_by_id: UUID
    title: str
    status: str
    resolution: str | None
    created_at: datetime


class NotificationSummaryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    notification_type: str
    title: str
    message: str
    is_read: bool
    created_at: datetime


class LocationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    provider_id: UUID
    latitude: float
    longitude: float
    address: str | None


class ProviderDetailResponse(BaseModel):
    provider: ProviderSummaryResponse
    service_category_ids: list[UUID]
    assignment_ids: list[UUID]
    review_ids: list[UUID]
    location: LocationResponse | None


class StatsResponse(BaseModel):
    customers_total: int
    providers_total: int
    providers_pending_approval: int
    requests_total: int
    requests_pending: int
    requests_in_progress: int
    requests_completed: int
    requests_cancelled: int
    quotes_pending: int
    quotes_approved: int
    quotes_rejected: int
    payments_total: int
    payments_pending: int
    payments_paid: int
    reviews_total: int
    issues_total: int
    issues_open: int
    assignments_total: int
    notifications_total: int


def user_page(items, total: int, page: int, page_size: int, total_pages: int):
    return {
        "items": [UserSummaryResponse.model_validate(i) for i in items],
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": total_pages,
    }


def provider_page(items, total, page, page_size, total_pages):
    return {
        "items": [
            ProviderSummaryResponse.model_validate(i) for i in items
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": total_pages,
    }


def request_page(items, total, page, page_size, total_pages):
    return {
        "items": [
            ServiceRequestSummaryResponse.model_validate(i)
            for i in items
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": total_pages,
    }


def quote_page(items, total, page, page_size, total_pages):
    return {
        "items": [QuoteSummaryResponse.model_validate(i) for i in items],
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": total_pages,
    }


def payment_page(items, total, page, page_size, total_pages):
    return {
        "items": [
            PaymentSummaryResponse.model_validate(i) for i in items
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": total_pages,
    }


def review_page(items, total, page, page_size, total_pages):
    return {
        "items": [ReviewSummaryResponse.model_validate(i) for i in items],
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": total_pages,
    }


def issue_page(items, total, page, page_size, total_pages):
    return {
        "items": [IssueSummaryResponse.model_validate(i) for i in items],
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": total_pages,
    }


def provider_detail_response(details: dict) -> dict:
    provider = details.get("provider")
    return {
        "provider": ProviderSummaryResponse.model_validate(
            provider
        ),
        "service_category_ids": details.get(
            "service_category_ids", []
        ),
        "assignment_ids": details.get("assignment_ids", []),
        "review_ids": details.get("review_ids", []),
        "location": (
            LocationResponse.model_validate(details["location"])
            if details.get("location")
            else None
        ),
    }


def notification_page(items, total, page, page_size, total_pages):
    return {
        "items": [
            NotificationSummaryResponse.model_validate(i)
            for i in items
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": total_pages,
    }
