from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.admin_repository import AdminRepository
from app.repositories.provider_repository import ProviderRepository


class AdminService:
    @staticmethod
    async def get_stats(db: AsyncSession) -> dict:
        return await AdminRepository.get_stats(db)

    @staticmethod
    async def list_users(
        db: AsyncSession,
        search: str | None = None,
        role: str | None = None,
        is_active: bool | None = None,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        return await AdminRepository.list_users(
            db,
            search=search,
            role=role,
            is_active=is_active,
            page=page,
            page_size=page_size,
        )

    @staticmethod
    async def list_providers(
        db: AsyncSession,
        search: str | None = None,
        approval_status: str | None = None,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        return await AdminRepository.list_providers(
            db,
            search=search,
            approval_status=approval_status,
            page=page,
            page_size=page_size,
        )

    @staticmethod
    async def list_service_requests(
        db: AsyncSession,
        search: str | None = None,
        status: str | None = None,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        return await AdminRepository.list_service_requests(
            db,
            search=search,
            status=status,
            page=page,
            page_size=page_size,
        )

    @staticmethod
    async def list_quotes(
        db: AsyncSession,
        status: str | None = None,
        request_id: str | None = None,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        return await AdminRepository.list_quotes(
            db,
            status=status,
            request_id=request_id,
            page=page,
            page_size=page_size,
        )

    @staticmethod
    async def list_payments(
        db: AsyncSession,
        status: str | None = None,
        method: str | None = None,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        return await AdminRepository.list_payments(
            db,
            status=status,
            method=method,
            page=page,
            page_size=page_size,
        )

    @staticmethod
    async def list_reviews(
        db: AsyncSession,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        return await AdminRepository.list_reviews(
            db,
            page=page,
            page_size=page_size,
        )

    @staticmethod
    async def list_issues(
        db: AsyncSession,
        status: str | None = None,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        return await AdminRepository.list_issues(
            db,
            status=status,
            page=page,
            page_size=page_size,
        )

    @staticmethod
    async def list_notifications(
        db: AsyncSession,
        page: int | None = None,
        page_size: int | None = None,
    ) -> dict:
        return await AdminRepository.list_notifications(
            db,
            page=page,
            page_size=page_size,
        )

    @staticmethod
    async def get_provider_details(
        db: AsyncSession,
        provider_id: str,
    ) -> dict | None:
        provider = await AdminRepository.get_provider_details(
            db, provider_id
        )
        if not provider:
            return None

        service_category_ids = (
            await AdminRepository.provider_service_ids(
                db, provider_id
            )
        )
        assignment_ids = (
            await AdminRepository.provider_assignment_ids(
                db, provider_id
            )
        )
        review_ids = await AdminRepository.provider_review_ids(
            db, provider_id
        )
        location = await ProviderRepository.get_location(
            db, provider_id
        )

        return {
            "provider": provider,
            "service_category_ids": service_category_ids,
            "assignment_ids": assignment_ids,
            "review_ids": review_ids,
            "location": location,
        }

    @staticmethod
    async def set_user_active(
        db: AsyncSession,
        user,
        is_active: bool,
    ):
        user.is_active = is_active
        return await AdminRepository.update_user(db, user)
