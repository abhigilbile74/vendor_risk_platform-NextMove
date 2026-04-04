"""
services/fake_news_service.py
Standalone fake news / credibility scoring service.
Cross-references a story across multiple trusted sources to verify it.
"""
import asyncio
import re
from dataclasses import dataclass

import httpx
from loguru import logger

from config.sectors import get_credibility, SOURCE_CREDIBILITY


@dataclass
class CredibilityReport:
    fake_risk_score: float          # 0.0 (legit) → 1.0 (likely fake)
    credibility_score: float        # source credibility
    verified_by: list[str]          # trusted sources that have the same story
    red_flags: list[str]            # specific issues found
    verdict: str                    # VERIFIED | UNVERIFIED | SUSPICIOUS | FAKE


FAKE_PATTERNS = [
    (r"\bbreaking\b.*\bunconfirmed\b", "Unconfirmed breaking news"),
    (r"\bguaranteed\b.*\breturns?\b", "Guaranteed returns claim"),
    (r"\binsider\b.*\btip\b", "Insider tip language"),
    (r"\bwhisper\b.*\bnumber\b", "Whisper number speculation"),
    (r"\bsecret\b.*\bdeal\b", "Secret deal claim"),
    (r"\bexclusive\b.*\bleak\b", "Exclusive leak claim"),
    (r"\b100%\b.*\bsure\b", "100% certainty claim"),
    (r"\bpump\b.*\bdump\b", "Pump and dump language"),
]


def score_text(text: str, source_url: str) -> CredibilityReport:
    """
    Score a piece of text for fake news risk.
    Fast, synchronous — no external calls.
    """
    lower = text.lower()
    red_flags: list[str] = []

    # Pattern matching
    for pattern, label in FAKE_PATTERNS:
        if re.search(pattern, lower):
            red_flags.append(label)

    # Excessive superlatives
    superlatives = ["massive", "explosive", "shocking", "unbelievable", "jaw-dropping"]
    found = [w for w in superlatives if w in lower]
    if len(found) >= 2:
        red_flags.append(f"Excessive sensationalism: {', '.join(found)}")

    # ALL CAPS words (clickbait signal)
    caps_words = re.findall(r'\b[A-Z]{4,}\b', text)
    if len(caps_words) >= 3:
        red_flags.append(f"Excessive caps ({len(caps_words)} words)")

    credibility = get_credibility(source_url)
    flag_score = min(len(red_flags) * 0.15, 0.6)
    cred_penalty = 1.0 - credibility
    fake_risk = round((flag_score * 0.6) + (cred_penalty * 0.4), 3)

    if fake_risk < 0.2:
        verdict = "VERIFIED"
    elif fake_risk < 0.4:
        verdict = "UNVERIFIED"
    elif fake_risk < 0.65:
        verdict = "SUSPICIOUS"
    else:
        verdict = "FAKE"

    return CredibilityReport(
        fake_risk_score=fake_risk,
        credibility_score=credibility,
        verified_by=[],
        red_flags=red_flags,
        verdict=verdict,
    )


async def cross_verify(title: str, symbol: str, source_url: str) -> CredibilityReport:
    """
    Check if a story appears in multiple trusted sources (NewsAPI search).
    Upgrades or downgrades the verdict based on corroboration.
    """
    base_report = score_text(title, source_url)

    # Search NewsAPI for corroborating stories
    try:
        from config.settings import get_settings
        settings = get_settings()
        if not settings.newsapi_key:
            return base_report

        # Extract key phrase (first 5 words of title)
        words = title.split()[:5]
        query = " ".join(words)

        async with httpx.AsyncClient(timeout=8.0) as client:
            resp = await client.get(
                "https://newsapi.org/v2/everything",
                params={
                    "q": query,
                    "language": "en",
                    "pageSize": 5,
                    "apiKey": settings.newsapi_key,
                },
            )
            articles = resp.json().get("articles", [])

        trusted_sources = [
            domain for domain in SOURCE_CREDIBILITY
            if SOURCE_CREDIBILITY[domain] >= 0.85 and domain != "default"
        ]

        verified_by = []
        for article in articles:
            article_url = article.get("url", "")
            for trusted in trusted_sources:
                if trusted in article_url and article_url != source_url:
                    verified_by.append(article.get("source", {}).get("name", trusted))
                    break

        base_report.verified_by = verified_by

        # Adjust score based on corroboration
        if len(verified_by) >= 2:
            base_report.fake_risk_score = max(0.0, base_report.fake_risk_score - 0.25)
            base_report.verdict = "VERIFIED"
        elif len(verified_by) == 1:
            base_report.fake_risk_score = max(0.0, base_report.fake_risk_score - 0.1)

    except Exception as e:
        logger.warning(f"Cross-verification failed: {e}")

    return base_report