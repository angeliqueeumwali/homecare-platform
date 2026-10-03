import asyncio
import os
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy import select

from app.database.connection import SessionLocal
from app.core.security import hash_password
from app.models.user import User
from app.models.service_category import ServiceCategory
from app.services.user_service import UserService
from app.services.provider_service import ProviderService
from app.services.service_request_service import ServiceRequestService
from app.services.quote_service import QuoteService
from app.services.assignment_service import AssignmentService
from app.services.payment_service import PaymentService
from app.services.review_service import ReviewService
from app.services.issue_service import IssueService
from app.services.notification_service import NotificationService
from app.schemas.service_request_schema import (
    ServiceRequestCreate,
    ServiceRequestItemCreate,
)
from app.schemas.quote_schema import QuoteCreate
from app.schemas.payment_schema import PaymentCreate
from app.schemas.review_schema import ReviewCreate
from app.schemas.issue_schema import IssueCreate


# Development-only fallback passwords for local acceptance seeding.
# These are not secrets and must NEVER be used against a shared,
# staging, or production database. Always set SEED_ADMIN_PASSWORD,
# SEED_CUSTOMER_PASSWORD, and SEED_PROVIDER_PASSWORD explicitly for
# any environment other than your local development machine.
ADMIN_PASSWORD = os.getenv("SEED_ADMIN_PASSWORD", "local-admin-password")
CUSTOMER_PASSWORD = os.getenv("SEED_CUSTOMER_PASSWORD", "local-customer-password")
PROVIDER_PASSWORD = os.getenv("SEED_PROVIDER_PASSWORD", "local-provider-password")


async def main():
    async with SessionLocal() as db:
        suffix = uuid.uuid4().hex[:8]

        admin = await UserService.create_user(
            db,
            first_name="Stage",
            last_name="Admin",
            email=f"stage-admin-{suffix}@example.com",
            phone_number=f"071{suffix[-7:]}",
            password_hash=hash_password(ADMIN_PASSWORD),
            role="ADMIN",
        )
        print("ADMIN_EMAIL", admin.email)

        customer = await UserService.create_user(
            db,
            first_name="Stage",
            last_name="Customer",
            email=f"stage-customer-{suffix}@example.com",
            phone_number=f"072{suffix[-7:]}",
            password_hash=hash_password(CUSTOMER_PASSWORD),
            role="CUSTOMER",
        )
        print("CUSTOMER_EMAIL", customer.email)

        provider_user = await UserService.create_user(
            db,
            first_name="Stage",
            last_name="Provider",
            email=f"stage-provider-{suffix}@example.com",
            phone_number=f"073{suffix[-7:]}",
            password_hash=hash_password(PROVIDER_PASSWORD),
            role="SERVICE_PROVIDER",
        )
        print("PROVIDER_EMAIL", provider_user.email)

        provider = await ProviderService.create_profile(
            db, provider_user, "Stage Provider Services",
            "Acceptance test provider"
        )
        print("PROVIDER_ID", str(provider.id))

        categories = list(
            (
                await db.execute(select(ServiceCategory))
            ).scalars().all()
        )
        category = categories[0]
        await ProviderService.add_service(
            db, provider, category.id
        )
        print("CATEGORY", category.name, str(category.id))

        expires = datetime.now(timezone.utc) + timedelta(days=2)
        request_data = ServiceRequestCreate(
            address="123 Acceptance Ave",
            latitude=-1.9403,
            longitude=30.0613,
            preferred_date=expires,
            notes="Acceptance test request",
            items=[
                ServiceRequestItemCreate(
                    service_category_id=category.id,
                    notes="Standard service item"
                )
            ],
        )
        request = await ServiceRequestService.create(
            db, customer.id, request_data
        )
        print("REQUEST_ID", str(request.id))
        item_id = request.items[0].id

        quote_data = QuoteCreate(
            service_request_id=request.id,
            service_request_item_id=item_id,
            amount=Decimal("150.00"),
            currency="RWF",
            description="Acceptance test quote",
        )
        quote = await QuoteService.create(
            db, provider.id, quote_data
        )
        print("QUOTE_ID", str(quote.id))

        await QuoteService.update_status(
            db, quote, "APPROVED"
        )

        assignment = await AssignmentService.create(
            db, request.id, item_id, provider.id
        )
        print("ASSIGNMENT_ID", str(assignment.id))

        await AssignmentService.update_status(
            db, assignment, "COMPLETED"
        )

        payment_data = PaymentCreate(
            service_request_id=request.id,
            quote_id=quote.id,
            amount=Decimal("150.00"),
            currency="RWF",
            payment_method="MOBILE_MONEY",
        )
        payment = await PaymentService.create(
            db, customer.id, payment_data
        )
        print("PAYMENT_ID", str(payment.id))

        review_data = ReviewCreate(
            assignment_id=assignment.id,
            rating=5,
            comment="Excellent acceptance test service",
        )
        review = await ReviewService.create(
            db, customer.id, review_data
        )
        print("REVIEW_ID", str(review.id))

        issue_data = IssueCreate(
            service_request_id=request.id,
            assignment_id=assignment.id,
            title="Acceptance test issue",
            description="Issue created for acceptance testing",
        )
        issue = await IssueService.create(
            db, customer.id, issue_data
        )
        print("ISSUE_ID", str(issue.id))

        await NotificationService.create(
            db, admin.id, "GENERAL",
            "Acceptance notification",
            "Notification for acceptance testing"
        )
        await NotificationService.create(
            db, customer.id, "SERVICE_REQUEST",
            "Request received",
            "Your service request was received"
        )

        contact_email = f"stage-contact-{suffix}@example.com"
        print("DONE", suffix)


asyncio.run(main())
