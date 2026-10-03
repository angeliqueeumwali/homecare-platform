from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.assignment import Assignment
from app.models.issue import Issue
from app.models.notification import Notification
from app.models.payment import Payment
from app.models.provider_profile import ProviderProfile
from app.models.provider_service import ProviderService
from app.models.quote import Quote
from app.models.review import Review
from app.models.service_request import ServiceRequest
from app.models.user import User


def paginate(total: int, page: int, page_size: int) -> dict:
    total_pages = (total + page_size - 1) // page_size if page_size else 0
    return {
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": total_pages,
    }


def clamp_page(page: int | None, page_size: int | None) -> tuple[int, int]:
    p = page if page and page > 0 else 1
    ps = page_size if page_size and page_size > 0 else 20
    return p, min(ps, 100)


def _ilike(value: str | None) -> str | None:
    return f"%{value}%" if value else None


async def _count(db: AsyncSession, stmt) -> int:
    result = await db.execute(stmt)
    return int(result.scalar() or 0)


def _user_search(term: str | None):
    like = _ilike(term)
    if not like:
        return None
    return (User.first_name.ilike(like) |
            User.last_name.ilike(like) |
            User.email.ilike(like))


class AdminRepository:
    @staticmethod
    async def list_users(
        db: AsyncSession,
        search: str | None = None,
        role: str | None = None,
        is_active: bool | None = None,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        p, ps = clamp_page(page, page_size)
        filters = []
        search_filter = _user_search(search)
        if search_filter is not None:
            filters.append(search_filter)
        if role:
            filters.append(User.role == role.upper())
        if is_active is not None:
            filters.append(User.is_active == is_active)

        base = select(User).where(*filters)
        count_stmt = select(func.count()).select_from(
            base.subquery()
        )
        total = await _count(db, count_stmt)

        rows = await db.execute(
            base.order_by(User.created_at.desc())
            .offset((p - 1) * ps)
            .limit(ps)
        )
        return {
            "items": list(rows.scalars().all()),
            **paginate(total, p, ps),
        }

    @staticmethod
    async def list_providers(
        db: AsyncSession,
        search: str | None = None,
        approval_status: str | None = None,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        p, ps = clamp_page(page, page_size)
        filters = []
        if search:
            like = _ilike(search)
            filters.append(
                ProviderProfile.business_name.ilike(like)
                if like
                else False
            )
        if approval_status:
            filters.append(
                ProviderProfile.approval_status
                == approval_status.upper()
            )

        base = select(ProviderProfile).where(*filters)
        count_stmt = select(func.count()).select_from(
            base.subquery()
        )
        total = await _count(db, count_stmt)

        rows = await db.execute(
            base.order_by(ProviderProfile.created_at.desc())
            .offset((p - 1) * ps)
            .limit(ps)
        )
        return {
            "items": list(rows.scalars().all()),
            **paginate(total, p, ps),
        }

    @staticmethod
    async def list_service_requests(
        db: AsyncSession,
        search: str | None = None,
        status: str | None = None,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        p, ps = clamp_page(page, page_size)
        filters = []
        if status:
            filters.append(ServiceRequest.status == status.upper())
        if search:
            like = _ilike(search)
            filters.append(
                (ServiceRequest.address.ilike(like) |
                 ServiceRequest.notes.ilike(like))
                if like
                else False
            )

        base = (
            select(ServiceRequest)
            .options(selectinload(ServiceRequest.items))
            .where(*filters)
        )
        count_stmt = select(func.count()).select_from(
            base.subquery()
        )
        total = await _count(db, count_stmt)

        rows = await db.execute(
            base.order_by(ServiceRequest.created_at.desc())
            .offset((p - 1) * ps)
            .limit(ps)
        )
        return {
            "items": list(rows.scalars().all()),
            **paginate(total, p, ps),
        }

    @staticmethod
    async def list_quotes(
        db: AsyncSession,
        status: str | None = None,
        request_id: str | None = None,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        p, ps = clamp_page(page, page_size)
        filters = []
        if status:
            filters.append(Quote.status == status.upper())
        if request_id:
            filters.append(
                Quote.service_request_id == request_id
            )

        base = select(Quote).where(*filters)
        count_stmt = select(func.count()).select_from(
            base.subquery()
        )
        total = await _count(db, count_stmt)

        rows = await db.execute(
            base.order_by(Quote.created_at.desc())
            .offset((p - 1) * ps)
            .limit(ps)
        )
        return {
            "items": list(rows.scalars().all()),
            **paginate(total, p, ps),
        }

    @staticmethod
    async def list_payments(
        db: AsyncSession,
        status: str | None = None,
        method: str | None = None,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        p, ps = clamp_page(page, page_size)
        filters = []
        if status:
            filters.append(Payment.status == status.upper())
        if method:
            filters.append(Payment.payment_method == method.upper())

        base = select(Payment).where(*filters)
        count_stmt = select(func.count()).select_from(
            base.subquery()
        )
        total = await _count(db, count_stmt)

        rows = await db.execute(
            base.order_by(Payment.created_at.desc())
            .offset((p - 1) * ps)
            .limit(ps)
        )
        return {
            "items": list(rows.scalars().all()),
            **paginate(total, p, ps),
        }

    @staticmethod
    async def list_reviews(
        db: AsyncSession,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        p, ps = clamp_page(page, page_size)
        base = select(Review)
        count_stmt = select(func.count()).select_from(
            base.subquery()
        )
        total = await _count(db, count_stmt)

        rows = await db.execute(
            base.order_by(Review.created_at.desc())
            .offset((p - 1) * ps)
            .limit(ps)
        )
        return {
            "items": list(rows.scalars().all()),
            **paginate(total, p, ps),
        }

    @staticmethod
    async def list_issues(
        db: AsyncSession,
        status: str | None = None,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        p, ps = clamp_page(page, page_size)
        filters = []
        if status:
            filters.append(Issue.status == status.upper())

        base = select(Issue).where(*filters)
        count_stmt = select(func.count()).select_from(
            base.subquery()
        )
        total = await _count(db, count_stmt)

        rows = await db.execute(
            base.order_by(Issue.created_at.desc())
            .offset((p - 1) * ps)
            .limit(ps)
        )
        return {
            "items": list(rows.scalars().all()),
            **paginate(total, p, ps),
        }

    @staticmethod
    async def list_notifications(
        db: AsyncSession,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        p, ps = clamp_page(page, page_size)
        base = select(Notification)
        count_stmt = select(func.count()).select_from(
            base.subquery()
        )
        total = await _count(db, count_stmt)

        rows = await db.execute(
            base.order_by(Notification.created_at.desc())
            .offset((p - 1) * ps)
            .limit(ps)
        )
        return {
            "items": list(rows.scalars().all()),
            **paginate(total, p, ps),
        }

    @staticmethod
    async def get_provider_details(db: AsyncSession, provider_id: str):
        provider = await db.execute(
            select(ProviderProfile).where(
                ProviderProfile.id == provider_id
            )
        )
        return provider.scalar_one_or_none()

    @staticmethod
    async def provider_service_ids(
        db: AsyncSession,
        provider_id: str,
    ) -> list:
        rows = await db.execute(
            select(ProviderService.service_category_id).where(
                ProviderService.provider_id == provider_id
            )
        )
        return [r[0] for r in rows.all()]

    @staticmethod
    async def provider_assignment_ids(
        db: AsyncSession,
        provider_id: str,
    ) -> list:
        rows = await db.execute(
            select(Assignment.id).where(
                Assignment.provider_id == provider_id
            )
        )
        return [r[0] for r in rows.all()]

    @staticmethod
    async def provider_review_ids(
        db: AsyncSession,
        provider_id: str,
    ) -> list:
        rows = await db.execute(
            select(Review.id).where(Review.provider_id == provider_id)
        )
        return [r[0] for r in rows.all()]

    @staticmethod
    async def update_user(db: AsyncSession, user: User) -> User:
        await db.commit()
        await db.refresh(user)
        return user

    @staticmethod
    async def get_stats(db: AsyncSession) -> dict:
        async def _table_count(model) -> int:
            return await _count(
                db, select(func.count()).select_from(model)
            )

        async def _request_status_count(status: str) -> int:
            return await _count(
                db,
                select(func.count()).select_from(ServiceRequest).where(
                    ServiceRequest.status == status
                ),
            )

        async def _quote_status_count(status: str) -> int:
            return await _count(
                db,
                select(func.count()).select_from(Quote).where(
                    Quote.status == status
                ),
            )

        async def _payment_status_count(status: str) -> int:
            return await _count(
                db,
                select(func.count()).select_from(Payment).where(
                    Payment.status == status
                ),
            )

        providers_total = await _table_count(ProviderProfile)
        providers_pending = await _count(
            db,
            select(func.count())
            .select_from(ProviderProfile)
            .where(
                ProviderProfile.approval_status == "PENDING"
            ),
        )

        customers_total = await _count(
            db,
            select(func.count())
            .select_from(User)
            .where(User.role == "CUSTOMER"),
        )

        requests_total = await _table_count(ServiceRequest)
        pending_payments = await _payment_status_count("PENDING")
        open_issues = await _count(
            db,
            select(func.count())
            .select_from(Issue)
            .where(Issue.status == "OPEN"),
        )

        return {
            "customers_total": customers_total,
            "providers_total": providers_total,
            "providers_pending_approval": providers_pending,
            "requests_total": requests_total,
            "requests_pending": await _request_status_count("PENDING"),
            "requests_in_progress": await _request_status_count(
                "IN_PROGRESS"
            ),
            "requests_completed": await _request_status_count(
                "COMPLETED"
            ),
            "requests_cancelled": await _request_status_count(
                "CANCELLED"
            ),
            "quotes_pending": await _quote_status_count("PENDING"),
            "quotes_approved": await _quote_status_count("APPROVED"),
            "quotes_rejected": await _quote_status_count("REJECTED"),
            "payments_total": await _table_count(Payment),
            "payments_pending": pending_payments,
            "payments_paid": await _payment_status_count("PAID"),
            "reviews_total": await _table_count(Review),
            "issues_total": await _table_count(Issue),
            "issues_open": open_issues,
            "assignments_total": await _table_count(Assignment),
            "notifications_total": await _table_count(Notification),
        }
