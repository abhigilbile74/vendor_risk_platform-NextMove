"""
services/sentiment_service.py
Multi-layer sentiment analysis:
  1. VADER (fast, finance-tuned keywords)
  2. Financial keyword boosting (earnings beat, profit warning, etc.)
  3. Returns compound score + label + strength
"""
import re
from dataclasses import dataclass

from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

_analyzer = SentimentIntensityAnalyzer()

# ── Finance-specific keyword boosters ─────────────────────────────────────────
BULLISH_KEYWORDS = [
    "beat", "beats", "exceeded", "record high", "outperform", "upgrade",
    "buy rating", "strong buy", "profit surge", "revenue growth", "expansion",
    "acquisition", "merger synergy", "dividend", "buyback", "order win",
    "contract win", "partnership", "deal signed", "guidance raised", "ipo",
    "strong results", "robust", "bullish", "rally", "surge", "jumps",
    "quarterly profit", "net profit up", "revenue up", "ebitda growth",
    "market share gain", "new product", "launch", "approval",
]

BEARISH_KEYWORDS = [
    "miss", "missed", "below expectations", "profit warning", "downgrade",
    "sell rating", "guidance cut", "revenue decline", "loss", "write-off",
    "layoffs", "job cuts", "restructuring", "investigation", "fraud",
    "regulatory action", "sebi notice", "npa", "bad loans", "default",
    "debt", "recall", "fine", "penalty", "bearish", "crash", "plunge",
    "drops", "falls", "slump", "weak", "disappointing", "quarterly loss",
    "net loss", "revenue down", "margin pressure", "cost overrun",
]

FAKE_NEWS_RED_FLAGS = [
    "rumor", "rumour", "unverified", "allegedly", "sources claim",
    "anonymous tip", "insider trading tip", "guaranteed returns",
    "secret deal", "leaked", "whistleblower claims", "exclusive tip",
    "breaking: unconfirmed",
]


@dataclass
class SentimentResult:
    score: float            # -1.0 to +1.0
    label: str              # POSITIVE | NEGATIVE | NEUTRAL
    strength: str           # STRONG | MODERATE | WEAK
    vader_compound: float
    bullish_hits: list[str]
    bearish_hits: list[str]
    fake_flag_hits: list[str]
    fake_risk_score: float  # 0.0 → 1.0


def _keyword_boost(text: str) -> tuple[float, list[str], list[str]]:
    """Returns (boost, bullish_hits, bearish_hits)."""
    lower = text.lower()
    bull = [kw for kw in BULLISH_KEYWORDS if kw in lower]
    bear = [kw for kw in BEARISH_KEYWORDS if kw in lower]
    boost = (len(bull) * 0.05) - (len(bear) * 0.05)
    boost = max(-0.4, min(0.4, boost))  # cap at ±0.4
    return boost, bull, bear


def _fake_risk(text: str, credibility: float) -> tuple[float, list[str]]:
    """Returns (fake_risk_score 0-1, matched_flags)."""
    lower = text.lower()
    hits = [f for f in FAKE_NEWS_RED_FLAGS if f in lower]
    # Base: inverted credibility + flag hits
    flag_score = min(len(hits) * 0.15, 0.6)
    cred_score = 1.0 - credibility          # low credibility → higher risk
    combined = (flag_score * 0.6) + (cred_score * 0.4)
    return round(min(combined, 1.0), 3), hits


def analyze(text: str, credibility: float = 0.5) -> SentimentResult:
    """Full sentiment + fake-risk analysis of a piece of text."""
    clean = re.sub(r"\s+", " ", text).strip()

    vader_scores = _analyzer.polarity_scores(clean)
    compound = vader_scores["compound"]   # -1 to +1

    boost, bull_hits, bear_hits = _keyword_boost(clean)
    final_score = max(-1.0, min(1.0, compound + boost))

    # Label
    if final_score >= 0.05:
        label = "POSITIVE"
    elif final_score <= -0.05:
        label = "NEGATIVE"
    else:
        label = "NEUTRAL"

    # Strength
    abs_score = abs(final_score)
    if abs_score >= 0.5:
        strength = "STRONG"
    elif abs_score >= 0.2:
        strength = "MODERATE"
    else:
        strength = "WEAK"

    fake_risk, fake_hits = _fake_risk(clean, credibility)

    return SentimentResult(
        score=round(final_score, 4),
        label=label,
        strength=strength,
        vader_compound=round(compound, 4),
        bullish_hits=bull_hits[:5],
        bearish_hits=bear_hits[:5],
        fake_flag_hits=fake_hits,
        fake_risk_score=fake_risk,
    )


def analyze_article(title: str, description: str, credibility: float = 0.5) -> SentimentResult:
    """Analyze title + description together, title weighted 2x."""
    combined = f"{title} {title} {description}"   # double title weight
    return analyze(combined, credibility)