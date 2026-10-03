from sqlalchemy import select
from app.models.payment import Payment

class PaymentRepository:
    @staticmethod
    async def create(db, payment):
        db.add(payment)
        await db.commit()
        await db.refresh(payment)
        return payment

    @staticmethod
    async def get_by_id(db, payment_id):
        r = await db.execute(select(Payment).where(Payment.id == payment_id))
        return r.scalar_one_or_none()

    @staticmethod
    async def get_customer_payments(db, customer_id):
        r = await db.execute(select(Payment).where(Payment.customer_id == customer_id).order_by(Payment.created_at.desc()))
        return list(r.scalars().all())

    @staticmethod
    async def update(db, payment):
        await db.commit()
        await db.refresh(payment)
        return payment
