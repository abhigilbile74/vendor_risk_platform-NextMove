"""
services/sector_logic.py
Aggregates company-level predictions into sector-level signals.
Powers the Bloomberg-style heatmap endpoint.
"""
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any

from loguru import logger

from config.sectors import SECTOR_TO_SYMBOLS, get_sector


@dataclass
class CompanySignal:
    symbol: str
    signal: str
    confidence: float
    sentiment_score: float
    fake_risk_score: float
    latest_headline: str
    article_count: int


@dataclass
class SectorSignal:
    sector: str
    signal: str               # BUY | SELL | NEUTRAL
    strength: float           # -1.0 to +1.0 (weighted average)
    confidence: float
    company_signals: list[CompanySignal]
    article_count: int
    top_headline: str


SIGNAL_MAP = {"BUY": 1, "NEUTRAL": 0, "SELL": -1}
SIGNAL_REVERSE = {1: "BUY", 0: "NEUTRAL", -1: "SELL"}


def _weighted_strength(signals: list[CompanySignal]) -> tuple[str, float, float]:
    """
    Compute sector-level signal from company signals.
    Weights: confidence × (1 - fake_risk).
    """
    total_weight = 0.0
    weighted_score = 0.0
    total_confidence = 0.0

    for cs in signals:
        weight = cs.confidence * (1.0 - cs.fake_risk_score)
        numeric = SIGNAL_MAP.get(cs.signal, 0) * cs.sentiment_score
        weighted_score += numeric * weight
        total_confidence += cs.confidence * weight
        total_weight += weight

    if total_weight == 0:
        return "NEUTRAL", 0.0, 0.5

    strength = weighted_score / total_weight
    avg_confidence = total_confidence / total_weight

    if strength >= 0.1:
        signal = "BUY"
    elif strength <= -0.1:
        signal = "SELL"
    else:
        signal = "NEUTRAL"

    return signal, round(strength, 4), round(avg_confidence, 3)


async def build_sector_heatmap(db, hours_back: int = 6) -> list[dict[str, Any]]:
    """
    Read recent predictions from DB and aggregate by sector.
    Returns list of SectorSignal dicts.
    """
    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours_back)

    cursor = db.predictions.find(
        {"created_at": {"$gte": cutoff.isoformat()}},
        sort=[("created_at", -1)],
    )
    recent: list[dict] = await cursor.to_list(length=5000)

    # Group by symbol, keep most recent prediction per symbol
    by_symbol: dict[str, dict] = {}
    for doc in recent:
        sym = doc["symbol"]
        if sym not in by_symbol:
            by_symbol[sym] = doc

    # Group symbols into sectors
    sector_map: dict[str, list[CompanySignal]] = {}
    headlines: dict[str, str] = {}

    for sym, doc in by_symbol.items():
        sector = get_sector(sym)
        cs = CompanySignal(
            symbol=sym,
            signal=doc.get("signal", "NEUTRAL"),
            confidence=doc.get("confidence", 0.5),
            sentiment_score=doc.get("sentiment_score", 0.0),
            fake_risk_score=doc.get("fake_risk_score", 0.0),
            latest_headline=doc.get("latest_headline", ""),
            article_count=doc.get("article_count", 1),
        )
        sector_map.setdefault(sector, []).append(cs)
        if doc.get("latest_headline"):
            headlines[sector] = doc["latest_headline"]

    results: list[dict] = []
    for sector, company_signals in sector_map.items():
        signal, strength, confidence = _weighted_strength(company_signals)
        total_articles = sum(cs.article_count for cs in company_signals)
        top_headline = headlines.get(sector, "")

        results.append(
            {
                "sector": sector,
                "signal": signal,
                "strength": strength,
                "confidence": confidence,
                "company_count": len(company_signals),
                "article_count": total_articles,
                "top_headline": top_headline,
                "companies": [
                    {
                        "symbol": cs.symbol,
                        "signal": cs.signal,
                        "confidence": cs.confidence,
                        "sentiment_score": cs.sentiment_score,
                    }
                    for cs in company_signals
                ],
            }
        )

    # Sort: strongest signals first
    results.sort(key=lambda x: abs(x["strength"]), reverse=True)
    logger.info(f"Sector heatmap built: {len(results)} sectors")
    return results