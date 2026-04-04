"""
api/signals.py
Endpoints for company signals + sector heatmap.
"""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Query, HTTPException, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase

from utils.database import get_db
from utils.cache import get_cached, set_cached
from services.sector_logic import build_sector_heatmap
from config.sectors import SECTOR_TO_SYMBOLS

router = APIRouter(prefix="/api/signals", tags=["Signals"])


@router.get("/heatmap")
async def get_sector_heatmap(
    hours: int = Query(6, ge=1, le=48),
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    """
    Returns sector-level aggregated signals for the Bloomberg heatmap.
    Cached for 5 minutes.
    """
    cache_key = f"heatmap:{hours}"
    cached = await get_cached(cache_key)
    if cached:
        return {"source": "cache", "data": cached}

    data = await build_sector_heatmap(db, hours_back=hours)
    await set_cached(cache_key, data, ttl=300)
    return {"source": "live", "data": data}


@router.get("/company/{symbol}")
async def get_company_signal(
    symbol: str,
    hours: int = Query(6, ge=1, le=48),
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    """Returns the latest prediction + history for a given symbol."""
    symbol = symbol.upper()
    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)

    # Latest prediction
    latest = await db.predictions.find_one(
        {"symbol": symbol, "created_at": {"$gte": cutoff.isoformat()}},
        sort=[("created_at", -1)],
    )
    if not latest:
        raise HTTPException(status_code=404, detail=f"No recent signal for {symbol}")
    latest["_id"] = str(latest["_id"])

    # Signal history for sparkline
    cursor = db.predictions.find(
        {"symbol": symbol, "created_at": {"$gte": cutoff.isoformat()}},
        sort=[("created_at", 1)],
        projection={"signal": 1, "confidence": 1, "sentiment_score": 1, "created_at": 1},
    )
    history = await cursor.to_list(length=100)
    for h in history:
        h["_id"] = str(h["_id"])

    # Recent headlines
    cursor2 = db.raw_news.find(
        {"symbol": symbol, "collected_at": {"$gte": cutoff.isoformat()}},
        sort=[("collected_at", -1)],
        limit=5,
        projection={"title": 1, "source": 1, "url": 1, "sentiment": 1, "collected_at": 1},
    )
    headlines = await cursor2.to_list(length=5)
    for h in headlines:
        h["_id"] = str(h["_id"])

    return {
        "symbol": symbol,
        "latest_signal": latest,
        "signal_history": history,
        "recent_headlines": headlines,
    }


@router.get("/watchlist")
async def get_watchlist_summary(
    hours: int = Query(6, ge=1, le=48),
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    """
    Returns latest signal for every symbol in the watchlist.
    Used for the terminal's top ticker strip.
    """
    from config.settings import get_settings
    settings = get_settings()
    watchlist = settings.watchlist_symbols

    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)
    results = []

    for sym in watchlist:
        doc = await db.predictions.find_one(
            {"symbol": sym, "created_at": {"$gte": cutoff.isoformat()}},
            sort=[("created_at", -1)],
            projection={"signal": 1, "confidence": 1, "sentiment_score": 1, "latest_headline": 1, "created_at": 1},
        )
        if doc:
            doc["_id"] = str(doc["_id"])
            results.append({"symbol": sym, **doc})
        else:
            results.append({"symbol": sym, "signal": "NEUTRAL", "confidence": 0.0, "sentiment_score": 0.0})

    return {"count": len(results), "hours": hours, "symbols": results}