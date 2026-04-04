"""
utils/database.py
Async MongoDB connection using Motor.
Collections are initialised with proper indexes on startup.
"""
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from loguru import logger
from config.settings import get_settings

settings = get_settings()

_client: AsyncIOMotorClient | None = None


async def connect_db() -> None:
    global _client
    _client = AsyncIOMotorClient(settings.mongodb_uri)
    db = _client[settings.mongodb_db]
    await _create_indexes(db)
    logger.info(f"MongoDB connected → {settings.mongodb_db}")


async def close_db() -> None:
    global _client
    if _client:
        _client.close()
        logger.info("MongoDB disconnected")


def get_db() -> AsyncIOMotorDatabase:
    if _client is None:
        raise RuntimeError("Database not connected. Call connect_db() first.")
    return _client[settings.mongodb_db]


async def _create_indexes(db: AsyncIOMotorDatabase) -> None:
    """Create indexes for all collections."""

    # raw_news: deduplicate by URL, fast lookup by symbol + collected_at
    await db.raw_news.create_index("url", unique=True)
    await db.raw_news.create_index([("symbol", 1), ("collected_at", -1)])
    await db.raw_news.create_index("labeled")

    # labeled_news: training dataset
    await db.labeled_news.create_index([("symbol", 1), ("collected_at", -1)])

    # predictions: live signal cache
    await db.predictions.create_index([("symbol", 1), ("created_at", -1)])
    await db.predictions.create_index("created_at")

    # model_metrics: training run history
    await db.model_metrics.create_index("trained_at")

    logger.info("MongoDB indexes ensured")