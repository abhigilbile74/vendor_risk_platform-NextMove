"""
jobs/collect_news.py
Scheduled job: runs every 30 minutes.
  1. Fetches news from all sources
  2. Gets current stock price for each article's symbol
  3. Runs sentiment + prediction
  4. Saves to MongoDB (raw_news + predictions collections)
"""
import asyncio
from datetime import datetime, timezone

import yfinance as yf
from loguru import logger
from motor.motor_asyncio import AsyncIOMotorDatabase

from config.settings import get_settings
from services.news_fetcher import NewsFetcher, NewsItem
from services.sentiment_service import analyze_article
from services.prediction_service import get_prediction_service

settings = get_settings()


def _get_nse_price(symbol: str) -> float | None:
    """Fetch current NSE price via yfinance. Returns None if unavailable."""
    try:
        ticker_sym = f"{symbol}.NS"
        ticker = yf.Ticker(ticker_sym)
        hist = ticker.history(period="1d", interval="1m")
        if hist.empty:
            return None
        return float(hist["Close"].iloc[-1])
    except Exception as e:
        logger.warning(f"Price fetch failed for {symbol}: {e}")
        return None


async def _get_price_async(symbol: str) -> float | None:
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(None, _get_nse_price, symbol)


async def run_collection(db: AsyncIOMotorDatabase) -> dict:
    """Main collection routine. Returns summary stats."""
    watchlist = settings.watchlist_symbols
    fetcher = NewsFetcher()
    prediction_svc = get_prediction_service()

    try:
        news_items: list[NewsItem] = await fetcher.fetch_all(watchlist)
    finally:
        await fetcher.close()

    if not news_items:
        logger.warning("No news items fetched this cycle")
        return {"fetched": 0, "saved": 0, "skipped": 0}

    # Fetch prices concurrently for all unique symbols
    symbols_needed = list({item.symbol for item in news_items})
    prices_list = await asyncio.gather(*[_get_price_async(s) for s in symbols_needed])
    price_map: dict[str, float | None] = dict(zip(symbols_needed, prices_list))

    saved = 0
    skipped = 0
    prediction_docs: list[dict] = []

    # Process each news item
    symbol_latest: dict[str, dict] = {}  # symbol → latest prediction for this cycle

    for item in news_items:
        # Run sentiment analysis
        sentiment = analyze_article(item.title, item.description, item.credibility_score)

        # Run prediction
        prediction = prediction_svc.predict(item.symbol, sentiment, item.credibility_score)

        # Prepare raw_news document
        raw_doc = item.to_dict()
        raw_doc["price_at_collection"] = price_map.get(item.symbol)
        raw_doc["sentiment"] = {
            "score": sentiment.score,
            "label": sentiment.label,
            "strength": sentiment.strength,
            "vader_compound": sentiment.vader_compound,
            "bullish_hits": sentiment.bullish_hits,
            "bearish_hits": sentiment.bearish_hits,
            "fake_risk_score": sentiment.fake_risk_score,
        }

        # Insert into raw_news (skip duplicates by URL)
        try:
            await db.raw_news.insert_one(raw_doc)
            saved += 1
        except Exception:
            skipped += 1
            continue

        # Track latest headline per symbol for prediction doc
        sym = item.symbol
        if sym not in symbol_latest or item.published_at > datetime.fromisoformat(
            symbol_latest[sym].get("published_at", "2000-01-01T00:00:00+00:00")
        ):
            symbol_latest[sym] = {
                "latest_headline": item.title,
                "published_at": item.published_at.isoformat(),
            }

    # Build aggregated prediction per symbol (one doc per symbol per cycle)
    for sym in symbols_needed:
        sym_items = [it for it in news_items if it.symbol == sym]
        if not sym_items:
            continue

        # Use the item with highest credibility for the primary prediction
        best_item = max(sym_items, key=lambda x: x.credibility_score)
        best_sentiment = analyze_article(
            best_item.title, best_item.description, best_item.credibility_score
        )
        pred = prediction_svc.predict(sym, best_sentiment, best_item.credibility_score)

        prediction_docs.append(
            {
                "symbol": sym,
                "signal": pred.signal,
                "confidence": pred.confidence,
                "sentiment_score": pred.sentiment_score,
                "sentiment_label": pred.sentiment_label,
                "sentiment_strength": pred.sentiment_strength,
                "fake_risk_score": pred.fake_risk_score,
                "credibility_score": pred.credibility_score,
                "model_used": pred.model_used,
                "reasoning": pred.reasoning,
                "latest_headline": symbol_latest.get(sym, {}).get("latest_headline", ""),
                "article_count": len(sym_items),
                "price_at_collection": price_map.get(sym),
                "created_at": datetime.now(timezone.utc).isoformat(),
            }
        )

    if prediction_docs:
        await db.predictions.insert_many(prediction_docs)
        logger.info(f"Inserted {len(prediction_docs)} prediction documents")

    summary = {
        "fetched": len(news_items),
        "saved": saved,
        "skipped": skipped,
        "symbols_processed": len(prediction_docs),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    logger.info(f"Collection cycle complete: {summary}")
    return summary