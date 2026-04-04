"""
services/ai_engine.py
The central intelligence coordinator.
Exposes a single analyze_news() method used by both the scheduler and
the REST API for on-demand analysis of arbitrary text.
"""
from dataclasses import dataclass, asdict
from datetime import datetime, timezone

from services.sentiment_service import analyze_article, SentimentResult
from services.prediction_service import get_prediction_service, PredictionResult
from config.sectors import get_sector, get_credibility


@dataclass
class AnalysisResult:
    symbol: str
    sector: str
    sentiment: dict
    prediction: dict
    analysis_timestamp: str

    def to_dict(self) -> dict:
        return asdict(self)


def analyze_news(
    symbol: str,
    title: str,
    description: str = "",
    source_url: str = "",
) -> AnalysisResult:
    """
    Full analysis pipeline for a single news item.
    1. Resolve credibility from source URL
    2. Run multi-layer sentiment analysis
    3. Run ML/rule-based prediction
    4. Return structured AnalysisResult
    """
    credibility = get_credibility(source_url)
    sentiment: SentimentResult = analyze_article(title, description, credibility)
    prediction_svc = get_prediction_service()
    prediction: PredictionResult = prediction_svc.predict(symbol, sentiment, credibility)
    sector = get_sector(symbol)

    return AnalysisResult(
        symbol=symbol,
        sector=sector,
        sentiment={
            "score": sentiment.score,
            "label": sentiment.label,
            "strength": sentiment.strength,
            "vader_compound": sentiment.vader_compound,
            "bullish_hits": sentiment.bullish_hits,
            "bearish_hits": sentiment.bearish_hits,
            "fake_risk_score": sentiment.fake_risk_score,
            "credibility_score": credibility,
        },
        prediction={
            "signal": prediction.signal,
            "confidence": prediction.confidence,
            "model_used": prediction.model_used,
            "reasoning": prediction.reasoning,
        },
        analysis_timestamp=datetime.now(timezone.utc).isoformat(),
    )