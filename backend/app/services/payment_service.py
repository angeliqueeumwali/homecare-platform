from datetime import datetime, timezone
from app.core.enums import PaymentMethod, PaymentStatus, QuoteStatus
from app.models.payment import Payment
from app.repositories.payment_repository import PaymentRepository
from app.repositories.quote_repository import QuoteRepository

class PaymentService:
    @staticmethod
    async def create(db, customer_id, data):
        quote = await QuoteRepository.get_by_id(db, data.quote_id)
        if not quote or quote.service_request_id != data.service_request_id:
            raise ValueError("Invalid quote")
        if quote.status != QuoteStatus.APPROVED:
            raise ValueError("Quote must be approved before payment")
        if data.amount != quote.amount:
            raise ValueError("Payment amount must match the approved quote")
        try:
            method = PaymentMethod(data.payment_method)
        except ValueError as error:
            raise ValueError("Invalid payment method") from error
        payment = Payment(
            service_request_id=data.service_request_id,
            quote_id=data.quote_id,
            customer_id=customer_id,
            amount=data.amount,
            currency=data.currency,
            payment_method=method,
        )
        return await PaymentRepository.create(db, payment)

    @staticmethod
    async def list_customer(db, customer_id):
        return await PaymentRepository.get_customer_payments(db, customer_id)

    @staticmethod
    async def update_status(db, payment, status, transaction_reference=None):
        try:
            new_status = PaymentStatus(status)
        except ValueError as error:
            raise ValueError("Invalid payment status") from error
        payment.status = new_status
        if transaction_reference is not None:
            payment.transaction_reference = transaction_reference
        if new_status == PaymentStatus.PAID:
            payment.paid_at = datetime.now(timezone.utc)
        return await PaymentRepository.update(db, payment)
