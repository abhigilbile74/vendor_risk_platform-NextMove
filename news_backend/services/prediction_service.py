import os
import joblib
import numpy as np
from dataclasses import dataclass
from datetime import datetime, timezone
from loguru import logger
from config.settings import get_settings

settings = get_settings()


@dataclass
class PredictionResult:
    symbol: str
    signal: str
    confidence: float
    sentiment_score: float
    sentiment_label: str
    sentiment_strength: str
    fake_risk_score: float
    credibility_score: float
    model_used: str
    reasoning: list
    created_at: str


class PredictionService:
    def __init__(self):
        self._model = None
        self._model_loaded = False

    def load_model(self):
        model_path = os.path.join(settings.model_dir, 'xgb_model.joblib')
        if os.path.exists(model_path):
            try:
                self._model = joblib.load(model_path)
                self._model_loaded = True
                logger.info('ML model loaded successfully')
            except Exception as e:
                logger.warning(f'Failed to load ML model: {e}')
                self._model_loaded = False
        else:
            logger.info('No trained model found — using rule-based predictions')
            self._model_loaded = False

    def _rule_based_predict(self, sentiment, credibility):
        reasoning = []
        score = sentiment.score
        effective_score = score * (0.5 + credibility * 0.5)

        if sentiment.fake_risk_score > 0.6:
            reasoning.append(f'High fake-news risk ({sentiment.fake_risk_score:.0%}) -> dampened signal')
            effective_score *= 0.3

        if credibility < 0.6:
            reasoning.append(f'Low source credibility ({credibility:.0%}) -> score reduced')

        for kw in sentiment.bullish_hits[:3]:
            reasoning.append(f'Bullish keyword: {kw}')
        for kw in sentiment.bearish_hits[:3]:
            reasoning.append(f'Bearish keyword: {kw}')

        if effective_score >= 0.15:
            signal = 'BUY'
            confidence = min(0.5 + effective_score * 0.4, 0.88)
        elif effective_score <= -0.15:
            signal = 'SELL'
            confidence = min(0.5 + abs(effective_score) * 0.4, 0.88)
        else:
            signal = 'NEUTRAL'
            confidence = 0.5

        if not reasoning:
            reasoning.append(f'Sentiment score {score:+.3f} -> {signal}')

        return signal, round(confidence, 3), reasoning

    def _ml_predict(self, sentiment, credibility):
        features = [[
            sentiment.score,
            sentiment.vader_compound,
            credibility,
            len(sentiment.bullish_hits),
            len(sentiment.bearish_hits),
            sentiment.fake_risk_score,
            1.0 if sentiment.label == 'POSITIVE' else 0.0,
            1.0 if sentiment.label == 'NEGATIVE' else 0.0,
            1.0 if sentiment.strength == 'STRONG' else 0.0,
            1.0 if sentiment.strength == 'MODERATE' else 0.0,
        ]]
        proba = self._model.predict_proba(features)[0]
        classes = self._model.classes_
        idx = int(np.argmax(proba))
        signal = classes[idx]
        confidence = float(proba[idx])
        reasoning = [
            f'ML model confidence: {confidence:.0%}',
            f'Sentiment: {sentiment.label} ({sentiment.score:+.3f})',
            f'Source credibility: {credibility:.0%}',
        ]
        return signal, round(confidence, 3), reasoning

    def predict(self, symbol, sentiment, credibility):
        if not self._model_loaded:
            self.load_model()

        if self._model_loaded:
            signal, confidence, reasoning = self._ml_predict(sentiment, credibility)
            model_used = 'ml_model'
        else:
            signal, confidence, reasoning = self._rule_based_predict(sentiment, credibility)
            model_used = 'rule_based'

        if confidence < settings.min_confidence and signal != 'NEUTRAL':
            reasoning.append(f'Confidence {confidence:.0%} below threshold -> NEUTRAL')
            signal = 'NEUTRAL'

        return PredictionResult(
            symbol=symbol,
            signal=signal,
            confidence=confidence,
            sentiment_score=sentiment.score,
            sentiment_label=sentiment.label,
            sentiment_strength=sentiment.strength,
            fake_risk_score=sentiment.fake_risk_score,
            credibility_score=credibility,
            model_used=model_used,
            reasoning=reasoning,
            created_at=datetime.now(timezone.utc).isoformat(),
        )


_prediction_service = None


def get_prediction_service():
    global _prediction_service
    if _prediction_service is None:
        _prediction_service = PredictionService()
    return _prediction_service
