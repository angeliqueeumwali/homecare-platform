from enum import Enum


class UserRole(str, Enum):
    CUSTOMER = "CUSTOMER"
    SERVICE_PROVIDER = "SERVICE_PROVIDER"
    ADMIN = "ADMIN"


class ProviderApprovalStatus(str, Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"


class ServiceRequestStatus(str, Enum):
    PENDING = "PENDING"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class ServiceRequestItemStatus(str, Enum):
    PENDING = "PENDING"
    SEARCHING_PROVIDER = "SEARCHING_PROVIDER"
    PROVIDER_ASSIGNED = "PROVIDER_ASSIGNED"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class AssignmentStatus(str, Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    DECLINED = "DECLINED"
    ON_THE_WAY = "ON_THE_WAY"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class QuoteStatus(str, Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"


class PaymentMethod(str, Enum):
    MOBILE_MONEY = "MOBILE_MONEY"
    CARD = "CARD"
    CASH = "CASH"


class PaymentStatus(str, Enum):
    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    PAID = "PAID"
    FAILED = "FAILED"
    REFUNDED = "REFUNDED"


class IssueStatus(str, Enum):
    OPEN = "OPEN"
    UNDER_REVIEW = "UNDER_REVIEW"
    RESOLVED = "RESOLVED"


class NotificationType(str, Enum):
    SERVICE_REQUEST = "SERVICE_REQUEST"
    ASSIGNMENT = "ASSIGNMENT"
    QUOTE = "QUOTE"
    PAYMENT = "PAYMENT"
    ISSUE = "ISSUE"
    GENERAL = "GENERAL"