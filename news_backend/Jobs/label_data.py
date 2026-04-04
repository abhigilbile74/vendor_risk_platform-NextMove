"""
jobs/label_data.py
Scheduled job: runs every 30 minutes.
Finds raw_news items collected 2+ hours ago that are still unlabeled,
fetches the current stock price, computes the label (UP/DOWN/STABLE),
and moves them to the labeled_news collection for ML training.
"""
import asyncio
from datetime import datetime, timedelta, timezone

import yfinance as yf
from loguru import logger
from motor.motor_asyncio import AsyncIOMotorDatabase

from config.settings import get_settings

settings = get_settings()

# Threshold: price change % to qualify as UP or DOWN
UP_THRESHOLD = 0.5     # +0.5% or more → UP
DOWN_THRESHOLD = -0.5  # -0.5% or more → DOWN


def _get_price(symbol: str) -> float | None:
    try:
        ticker = yf.Ticker(f"{symbol}.NS")
        hist = ticker.history(period="1d", interval="1m")
        if hist.empty:
            return None
        return float(hist["Close"].iloc[-1])
    except Exception as e:
        logger.warning(f"Labeling price fetch failed for {symbol}: {e}")
        return None


def _compute_label(price_before: float, price_after: float) -> str:
    pct_change = ((price_after - price_before) / price_before) * 100
    if pct_change >= UP_THRESHOLD:
        return "UP"
    elif pct_change <= DOWN_THRESHOLD:
        return "DOWN"
    else:
        return "STABLE"


async def run_labeling(db: AsyncIOMotorDatabase) -> dict:
    """Find unlabeled articles old enough, label them, move to labeled_news."""
    label_cutoff = datetime.now(timezone.utc) - timedelta(hours=settings.label_delay_hours)

    # Find articles that need labeling
    cursor = db.raw_news.find(
        {
            "labeled": False,
            "collected_at": {"$lte": label_cutoff.isoformat()},
            "price_at_collection": {"$ne": None},
        }
    )
    to_label: list[dict] = await cursor.to_list(length=1000)

    if not to_label:
        logger.info("No articles to label this cycle")
        return {"labeled": 0}

    # Fetch current prices for all unique symbols at once
    symbols = list({doc["symbol"] for doc in to_label})
    loop = asyncio.get_event_loop()
    prices = await asyncio.gather(*[
        loop.run_in_executor(None, _get_price, sym) for sym in symbols
    ])
    price_now: dict[str, float | None] = dict(zip(symbols, prices))

    labeled_count = 0
    failed_count = 0

    for doc in to_label:
        sym = doc["symbol"]
        current_price = price_now.get(sym)
        price_before = doc.get("price_at_collection")

        if current_price is None or price_before is None or price_before == 0:
            failed_count += 1
            continue

        label = _compute_label(price_before, current_price)
        pct_change = ((current_price - price_before) / price_before) * 100

        # Build labeled training document
        labeled_doc = {
            # Features
            "symbol": sym,
            "sentiment_score": doc.get("sentiment", {}).get("score", 0.0),
            "vader_compound": doc.get("sentiment", {}).get("vader_compound", 0.0),
            "credibility_score": doc.get("credibility_score", 0.5),
            "bullish_hits": len(doc.get("sentiment", {}).get("bullish_hits", [])),
            "bearish_hits": len(doc.get("sentiment", {}).get("bearish_hits", [])),
            "fake_risk_score": doc.get("sentiment", {}).get("fake_risk_score", 0.0),
            "sentiment_positive": 1 if doc.get("sentiment", {}).get("label") == "POSITIVE" else 0,
            "sentiment_negative": 1 if doc.get("sentiment", {}).get("label") == "NEGATIVE" else 0,
            "strength_strong": 1 if doc.get("sentiment", {}).get("strength") == "STRONG" else 0,
            "strength_moderate": 1 if doc.get("sentiment", {}).get("strength") == "MODERATE" else 0,
            # Target
            "label": label,
            "pct_change": round(pct_change, 4),
            # Metadata
            "title": doc.get("title", ""),
            "source": doc.get("source", ""),
            "published_at": doc.get("published_at"),
            "collected_at": doc.get("collected_at"),
            "labeled_at": datetime.now(timezone.utc).isoformat(),
            "price_at_collection": price_before,
            "price_at_label": current_price,
            "raw_news_id": str(doc["_id"]),
        }

        try:
            await db.labeled_news.insert_one(labeled_doc)
            # Mark original as labeled
            await db.raw_news.update_one(
                {"_id": doc["_id"]},
                {
                    "$set": {
                        "labeled": True,
                        "label": label,
                        "price_at_label": current_price,
                        "pct_change": round(pct_change, 4),
                    }
                },
            )
            labeled_count += 1
        except Exception as e:
            logger.error(f"Failed to label doc {doc['_id']}: {e}")
            failed_count += 1

    summary = {
        "labeled": labeled_count,
        "failed": failed_count,
        "total_found": len(to_label),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    logger.info(f"Labeling cycle complete: {summary}")
    return summary