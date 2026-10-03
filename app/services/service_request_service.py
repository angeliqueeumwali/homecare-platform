from app.core.enums import ServiceRequestItemStatus, ServiceRequestStatus
from app.models.service_request import ServiceRequest
from app.models.service_request_item import ServiceRequestItem
from app.repositories.service_request_repository import ServiceRequestRepository
from app.repositories.assignment_repository import AssignmentRepository
from app.repositories.service_category_repository import ServiceCategoryRepository

class ServiceRequestService:
    @staticmethod
    async def create(db, customer_id, data):
        items = []
        for item in data.items:
            category = await ServiceCategoryRepository.get_by_id(db, item.service_category_id)
            if not category or not category.is_active:
                raise ValueError(f"Service category {item.service_category_id} is not available")
            items.append(ServiceRequestItem(
                service_category_id=item.service_category_id,
                notes=item.notes,
                status=ServiceRequestItemStatus.PENDING,
            ))
        request = ServiceRequest(
            customer_id=customer_id,
            address=data.address,
            latitude=data.latitude,
            longitude=data.longitude,
            preferred_date=data.preferred_date,
            notes=data.notes,
            status=ServiceRequestStatus.PENDING,
        )
        for item in items:
            item.service_request = request
        return await ServiceRequestRepository.create(db, request, items)

    @staticmethod
    async def get(db, request_id):
        request = await ServiceRequestRepository.get_by_id(db, request_id)
        if not request:
            raise ValueError("Service request not found")
        return request

    @staticmethod
    async def get_for_provider(db, request_id, provider_id):
        request = await ServiceRequestRepository.get_by_id(db, request_id)
        if not request:
            raise ValueError("Service request not found")

        assignments = await AssignmentRepository.get_provider_assignments(
            db, provider_id
        )
        assigned = any(
            a.service_request_id == request.id for a in assignments
        )
        if not assigned:
            raise PermissionError(
                "You can only view requests assigned to you"
            )

        return request

    @staticmethod
    async def customer_list(db, customer_id):
        return await ServiceRequestRepository.get_customer_requests(db, customer_id)

    @staticmethod
    async def all(db):
        return await ServiceRequestRepository.get_all(db)

    @staticmethod
    async def update_status(db, request, status):
        try:
            request.status = ServiceRequestStatus(status)
        except ValueError as error:
            raise ValueError("Invalid service request status") from error
        return await ServiceRequestRepository.update(db, request)

    @staticmethod
    async def get_item(db, item_id):
        item = await ServiceRequestRepository.get_item(db, item_id)
        if not item:
            raise ValueError("Service request item not found")
        return item
