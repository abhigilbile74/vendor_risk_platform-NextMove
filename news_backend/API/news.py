"""
api/news.py
Endpoints for live news feed with sentiment signals.
"""
from datetime import datetime, timedelta, timezone
from typing import Literal

from fastapi import APIRouter, Query, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase

from utils.database import get_db

router = APIRouter(prefix="/api/news", tags=["News"])


@router.get("/feed")
async def get_news_feed(
    symbol: str | None = Query(None, description="Filter by stock symbol"),
    signal: Literal["BUY", "SELL", "NEUTRAL"] | None = Query(None),
    hours: int = Query(6, ge=1, le=72),
    limit: int = Query(50, ge=1, le=200),
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    """
    Returns recent news items with sentiment + signal annotations.
    """
    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)
    query: dict = {"collected_at": {"$gte": cutoff.isoformat()}}

    if symbol:
        query["symbol"] = symbol.upper()

    if signal:
        query["sentiment.label"] = "POSITIVE" if signal == "BUY" else (
            "NEGATIVE" if signal == "SELL" else "NEUTRAL"
        )

    cursor = db.raw_news.find(
        query,
        sort=[("collected_at", -1)],
        limit=limit,
    )
    docs = await cursor.to_list(length=limit)

    items = []
    for doc in docs:
        doc["_id"] = str(doc["_id"])
        items.append(doc)

    return {"count": len(items), "hours": hours, "items": items}


@router.get("/article/{article_hash}")
async def get_article_detail(
    article_hash: str,
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    """Returns full detail of a single news article."""
    doc = await db.raw_news.find_one({"article_hash": article_hash})
    if not doc:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Article not found")
    doc["_id"] = str(doc["_id"])
    return doc