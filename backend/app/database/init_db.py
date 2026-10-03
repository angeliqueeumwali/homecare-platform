import asyncio

import app.models

from app.database.base import Base
from app.database.connection import engine


async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


if __name__ == "__main__":
    asyncio.run(init_db())
    print("Database tables created successfully")