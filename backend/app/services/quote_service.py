from app.core.enums import QuoteStatus
from app.models.quote import Quote
from app.repositories.quote_repository import QuoteRepository
from app.repositories.service_request_repository import ServiceRequestRepository

class QuoteService:
    @staticmethod
    async def create(db, provider_id, data):
        request = await ServiceRequestRepository.get_by_id(db, data.service_request_id)
        item = await ServiceRequestRepository.get_item(db, data.service_request_item_id)
        if not request or not item or item.service_request_id != request.id:
            raise ValueError("Invalid service request item")
        quote = Quote(
            service_request_id=request.id,
            service_request_item_id=item.id,
            provider_id=provider_id,
            amount=data.amount,
            currency=data.currency,
            description=data.description,
        )
        return await QuoteRepository.create(db, quote)

    @staticmethod
    async def get(db, quote_id):
        quote = await QuoteRepository.get_by_id(db, quote_id)
        if not quote:
            raise ValueError("Quote not found")
        return quote

    @staticmethod
    async def list_for_request(db, request_id):
        return await QuoteRepository.get_request_quotes(db, request_id)

    @staticmethod
    async def update_status(db, quote, status):
        try:
            quote.status = QuoteStatus(status)
        except ValueError as error:
            raise ValueError("Invalid quote status") from error
        return await QuoteRepository.update(db, quote)
