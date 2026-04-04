"""
utils/cache.py
Redis-based cache for expensive repeated computations (sector heatmap, predictions).
Falls back gracefully if Redis is unavailable.
"""
import json
from typing import Any
import redis.asyncio as aioredis
from loguru import logger
from config.settings import get_settings

settings = get_settings()

_redis: aioredis.Redis | None = None


async def connect_cache() -> None:
    global _redis
    try:
        _redis = aioredis.from_url(settings.redis_url, decode_responses=True)
        await _redis.ping()
        logger.info("Redis connected")
    except Exception as e:
        logger.warning(f"Redis unavailable ({e}). Cache disabled — will recompute on each request.")
        _redis = None


async def close_cache() -> None:
    global _redis
    if _redis:
        await _redis.close()


async def get_cached(key: str) -> Any | None:
    if not _redis:
        return None
    try:
        raw = await _redis.get(key)
        return json.loads(raw) if raw else None
    except Exception:
        return None


async def set_cached(key: str, value: Any, ttl: int | None = None) -> None:
    if not _redis:
        return
    try:
        ttl = ttl or settings.cache_ttl_seconds
        await _redis.set(key, json.dumps(value), ex=ttl)
    except Exception as e:
        logger.warning(f"Cache write failed: {e}")


async def invalidate(key: str) -> None:
    if not _redis:
        return
    try:
        await _redis.delete(key)
    except Exception:
        pass