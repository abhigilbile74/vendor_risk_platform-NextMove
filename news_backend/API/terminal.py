"""
api/terminal.py
Terminal-ready endpoints that return fully formatted Bloomberg-style
signal cards — used directly by the frontend dashboard.
"""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Query, HTTPException, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase

from utils.database import get_db
from utils.cache import get_cached, set_cached
from services.intelligence import build_terminal_summary, market_session_status
from config.sectors import get_sector

router = APIRouter(prefix="/api/terminal", tags=["Terminal"])


@router.get("/card/{symbol}")
async def get_terminal_card(
    symbol: str,
    hours: int = Query(6, ge=1, le=48),
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    """
    Returns a fully-rendered signal card for a symbol.
    Powers the Bloomberg terminal detail panel.
    """
    symbol = symbol.upper()
    cache_key = f"terminal_card:{symbol}:{hours}"
    cached = await get_cached(cache_key)
    if cached:
        return cached

    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)

    # Get latest prediction
    pred = await db.predictions.find_one(
        {"symbol": symbol, "created_at": {"$gte": cutoff.isoformat()}},
        sort=[("created_at", -1)],
    )
    if not pred:
        raise HTTPException(status_code=404, detail=f"No recent data for {symbol}")

    # Get recent headlines
    cursor = db.raw_news.find(
        {"symbol": symbol, "collected_at": {"$gte": cutoff.isoformat()}},
        sort=[("collected_at", -1)],
        limit=5,
    )
    headlines = await cursor.to_list(length=5)

    card = build_terminal_summary(
        symbol=symbol,
        signal=pred.get("signal", "NEUTRAL"),
        confidence=pred.get("confidence", 0.5),
        sentiment_score=pred.get("sentiment_score", 0.0),
        reasoning=pred.get("reasoning", []),
        headlines=headlines,
        sector=get_sector(symbol),
    )

    await set_cached(cache_key, card, ttl=120)
    return card


@router.get("/market-status")
async def get_market_status():
    """Returns current NSE market session status."""
    return market_session_status()


@router.get("/summary")
async def get_terminal_summary(
    hours: int = Query(6, ge=1, le=24),
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    """
    Top-level market summary for the terminal header bar.
    Returns: session status, overall market bias, top movers.
    """
    cache_key = f"terminal_summary:{hours}"
    cached = await get_cached(cache_key)
    if cached:
        return cached

    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)

    # Aggregate signals
    pipeline = [
        {"$match": {"created_at": {"$gte": cutoff.isoformat()}}},
        {"$sort": {"created_at": -1}},
        {"$group": {
            "_id": "$symbol",
            "signal": {"$first": "$signal"},
            "confidence": {"$first": "$confidence"},
            "sentiment_score": {"$first": "$sentiment_score"},
            "latest_headline": {"$first": "$latest_headline"},
        }},
    ]
    cursor = db.predictions.aggregate(pipeline)
    docs = await cursor.to_list(length=100)

    buy_count = sum(1 for d in docs if d["signal"] == "BUY")
    sell_count = sum(1 for d in docs if d["signal"] == "SELL")
    neutral_count = sum(1 for d in docs if d["signal"] == "NEUTRAL")
    total = len(docs)

    if total == 0:
        market_bias = "NEUTRAL"
    elif buy_count / total > 0.55:
        market_bias = "BULLISH"
    elif sell_count / total > 0.55:
        market_bias = "BEARISH"
    else:
        market_bias = "MIXED"

    # Top 3 by confidence
    top_buy = sorted(
        [d for d in docs if d["signal"] == "BUY"],
        key=lambda x: x["confidence"], reverse=True
    )[:3]
    top_sell = sorted(
        [d for d in docs if d["signal"] == "SELL"],
        key=lambda x: x["confidence"], reverse=True
    )[:3]

    result = {
        "market_session": market_session_status(),
        "market_bias": market_bias,
        "signal_counts": {
            "BUY": buy_count,
            "SELL": sell_count,
            "NEUTRAL": neutral_count,
            "total": total,
        },
        "top_buy": [{"symbol": d["_id"], "confidence": d["confidence"], "headline": d.get("latest_headline", "")} for d in top_buy],
        "top_sell": [{"symbol": d["_id"], "confidence": d["confidence"], "headline": d.get("latest_headline", "")} for d in top_sell],
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }

    await set_cached(cache_key, result, ttl=180)
    return result