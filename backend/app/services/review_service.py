from sqlalchemy import func, select
from app.models.service_request import ServiceRequest
from app.models.review import Review
from app.repositories.assignment_repository import AssignmentRepository
from app.repositories.review_repository import ReviewRepository
from app.models.provider_profile import ProviderProfile

class ReviewService:
    @staticmethod
    async def create(db, customer_id, data):
        assignment = await AssignmentRepository.get_by_id(db, data.assignment_id)
        if not assignment:
            raise ValueError("Assignment not found")
        request = await db.get(ServiceRequest, assignment.service_request_id)
        if not request or request.customer_id != customer_id:
            raise ValueError("You cannot review this assignment")
        if getattr(assignment.status, "value", assignment.status) != "COMPLETED":
            raise ValueError("Service must be completed before reviewing")
        if await ReviewRepository.get_by_assignment(db, data.assignment_id):
            raise ValueError("This assignment has already been reviewed")
        review = Review(
            customer_id=customer_id,
            provider_id=assignment.provider_id,
            assignment_id=assignment.id,
            rating=data.rating,
            comment=data.comment,
        )
        result = await ReviewRepository.create(db, review)
        avg = await db.scalar(select(func.avg(Review.rating)).where(Review.provider_id == assignment.provider_id))
        provider = await db.get(ProviderProfile, assignment.provider_id)
        if provider:
            provider.average_rating = float(avg) if avg is not None else None
            await db.commit()
        return result

    @staticmethod
    async def provider_reviews(db, provider_id):
        return await ReviewRepository.get_provider_reviews(db, provider_id)
