from datetime import datetime, timezone
from app.core.enums import AssignmentStatus, ServiceRequestItemStatus, ServiceRequestStatus
from app.models.assignment import Assignment
from app.repositories.assignment_repository import AssignmentRepository
from app.repositories.provider_repository import ProviderRepository
from app.repositories.service_request_repository import ServiceRequestRepository

class AssignmentService:
    @staticmethod
    async def create(db, service_request_id, item_id, provider_id):
        request = await ServiceRequestRepository.get_by_id(db, service_request_id)
        item = await ServiceRequestRepository.get_item(db, item_id)
        provider = await ProviderRepository.get_by_id(db, provider_id)
        if not request or not item:
            raise ValueError("Service request or item not found")
        if item.service_request_id != request.id:
            raise ValueError("Item does not belong to request")
        if not provider:
            raise ValueError("Provider not found")
        assignment = Assignment(
            service_request_id=request.id,
            service_request_item_id=item.id,
            provider_id=provider.id,
        )
        item.status = ServiceRequestItemStatus.PROVIDER_ASSIGNED
        request.status = ServiceRequestStatus.IN_PROGRESS
        return await AssignmentRepository.create(db, assignment)

    @staticmethod
    async def get(db, assignment_id):
        assignment = await AssignmentRepository.get_by_id(db, assignment_id)
        if not assignment:
            raise ValueError("Assignment not found")
        return assignment

    @staticmethod
    async def provider_list(db, provider_id):
        return await AssignmentRepository.get_provider_assignments(db, provider_id)

    @staticmethod
    async def request_list(db, request_id):
        return await AssignmentRepository.get_request_assignments(db, request_id)

    @staticmethod
    async def update_status(db, assignment, status):
        try:
            new_status = AssignmentStatus(status)
        except ValueError as error:
            raise ValueError("Invalid assignment status") from error
        now = datetime.now(timezone.utc)
        assignment.status = new_status
        if new_status == AssignmentStatus.ACCEPTED:
            assignment.accepted_at = now
        if new_status == AssignmentStatus.COMPLETED:
            assignment.completed_at = now
            assignment.service_request_item.status = ServiceRequestItemStatus.COMPLETED
        if new_status == AssignmentStatus.IN_PROGRESS:
            assignment.service_request_item.status = ServiceRequestItemStatus.IN_PROGRESS
        if new_status == AssignmentStatus.CANCELLED:
            assignment.service_request_item.status = ServiceRequestItemStatus.CANCELLED
        return await AssignmentRepository.update(db, assignment)
