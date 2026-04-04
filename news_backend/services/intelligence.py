"""
services/intelligence.py
Higher-order intelligence layer.
Provides market context, signal strength explanations,
and generates human-readable summaries for the Bloomberg terminal UI.
"""
from datetime import datetime, timezone


SIGNAL_EXPLANATIONS = {
    "BUY": {
        "STRONG": "Multiple high-credibility sources report strongly positive developments. Sentiment indicators well above threshold.",
        "MODERATE": "Moderately positive news flow from reliable sources. Signal is above threshold but not decisive.",
        "WEAK": "Slight positive bias in recent news. Low conviction — treat as noise until confirmed.",
    },
    "SELL": {
        "STRONG": "Multiple credible sources report material negative events. High-confidence downside signal.",
        "MODERATE": "Negative sentiment from reliable sources. Signal warrants attention but not panic.",
        "WEAK": "Mild negative tone detected. Watch for follow-through before acting.",
    },
    "NEUTRAL": {
        "STRONG": "Conflicting signals cancel out — equal bullish and bearish pressure.",
        "MODERATE": "News flow is mixed or low-conviction. No clear directional bias.",
        "WEAK": "Minimal news activity. Signal below confidence threshold.",
    },
}


def get_signal_explanation(signal: str, strength: str) -> str:
    return SIGNAL_EXPLANATIONS.get(signal, {}).get(strength, "Insufficient data for analysis.")


def build_terminal_summary(
    symbol: str,
    signal: str,
    confidence: float,
    sentiment_score: float,
    reasoning: list[str],
    headlines: list[dict],
    sector: str,
) -> dict:
    """
    Builds the structured data payload for the Bloomberg terminal card.
    """
    strength = (
        "STRONG" if confidence >= 0.75
        else "MODERATE" if confidence >= 0.60
        else "WEAK"
    )

    explanation = get_signal_explanation(signal, strength)
    timestamp = datetime.now(timezone.utc).strftime("%H:%M IST")

    signal_colors = {"BUY": "#00ff88", "SELL": "#ff4444", "NEUTRAL": "#ffaa00"}
    color = signal_colors.get(signal, "#888888")

    return {
        "symbol": symbol,
        "sector": sector,
        "signal": signal,
        "signal_color": color,
        "confidence_pct": round(confidence * 100, 1),
        "strength": strength,
        "sentiment_score": sentiment_score,
        "explanation": explanation,
        "reasoning": reasoning,
        "top_headlines": [
            {
                "title": h.get("title", ""),
                "source": h.get("source", ""),
                "url": h.get("url", ""),
                "sentiment": h.get("sentiment", {}).get("label", "NEUTRAL"),
            }
            for h in headlines[:3]
        ],
        "generated_at": timestamp,
        "disclaimer": "For informational purposes only. Not financial advice.",
    }


def market_session_status() -> dict:
    """Returns current NSE market session info."""
    now = datetime.now(timezone.utc)
    # NSE: 9:15 AM – 3:30 PM IST = 3:45 AM – 10:00 AM UTC
    hour_utc = now.hour
    minute = now.minute
    weekday = now.weekday()  # 0=Monday

    is_weekday = weekday < 5
    market_open_utc = (3, 45)
    market_close_utc = (10, 0)

    current_minutes = hour_utc * 60 + minute
    open_minutes = market_open_utc[0] * 60 + market_open_utc[1]
    close_minutes = market_close_utc[0] * 60 + market_close_utc[1]

    is_open = is_weekday and open_minutes <= current_minutes <= close_minutes

    return {
        "is_open": is_open,
        "session": "LIVE" if is_open else "CLOSED",
        "exchange": "NSE",
        "timezone": "IST (UTC+5:30)",
        "trading_hours": "09:15 – 15:30 IST",
    }