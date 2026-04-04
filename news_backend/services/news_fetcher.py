"""
services/news_fetcher.py
Fetches news from NewsAPI + Indian financial RSS feeds.
Returns structured NewsItem objects ready for DB insertion.
"""
import asyncio
import hashlib
import re
from datetime import datetime, timezone
from dataclasses import dataclass, field, asdict

import feedparser
import httpx
from loguru import logger
from tenacity import retry, stop_after_attempt, wait_exponential

from config.settings import get_settings
from config.sectors import get_credibility

settings = get_settings()

# ── Indian financial RSS feeds ─────────────────────────────────────────────────
RSS_FEEDS = [
    "https://economictimes.indiatimes.com/markets/stocks/rss.cms",
    "https://www.moneycontrol.com/rss/business.xml",
    "https://www.livemint.com/rss/markets",
    "https://www.business-standard.com/rss/markets-106.rss",
    "https://feeds.feedburner.com/ndtvprofit-latest",
]

# Company name → symbol mapping (for NER-lite matching)
COMPANY_ALIASES: dict[str, str] = {
    "tata consultancy": "TCS",
    "tcs": "TCS",
    "infosys": "INFY",
    "wipro": "WIPRO",
    "hcl tech": "HCLTECH",
    "hcl technologies": "HCLTECH",
    "reliance": "RELIANCE",
    "hdfc bank": "HDFC",
    "hdfc": "HDFC",
    "icici bank": "ICICIBANK",
    "icici": "ICICIBANK",
    "axis bank": "AXISBANK",
    "state bank": "SBIN",
    "sbi": "SBIN",
    "ongc": "ONGC",
    "ntpc": "NTPC",
    "power grid": "POWERGRID",
    "maruti": "MARUTI",
    "maruti suzuki": "MARUTI",
    "tata motors": "TATAMOTORS",
    "bajaj finance": "BAJFINANCE",
    "kotak mahindra": "KOTAKBANK",
    "kotak bank": "KOTAKBANK",
}


@dataclass
class NewsItem:
    title: str
    description: str
    url: str
    source: str
    published_at: datetime
    symbol: str
    credibility_score: float
    collected_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    labeled: bool = False
    price_at_collection: float | None = None
    price_at_label: float | None = None
    label: str | None = None   # UP | DOWN | STABLE
    article_hash: str = ""

    def __post_init__(self):
        self.article_hash = hashlib.md5(self.url.encode()).hexdigest()

    def to_dict(self) -> dict:
        d = asdict(self)
        d["published_at"] = self.published_at.isoformat()
        d["collected_at"] = self.collected_at.isoformat()
        return d


def extract_symbol(text: str) -> str | None:
    """Lightweight NER: find a company mention in headline/description."""
    lower = text.lower()
    for alias, sym in COMPANY_ALIASES.items():
        if alias in lower:
            return sym
    return None


def _clean_text(text: str) -> str:
    text = re.sub(r"<[^>]+>", "", text)      # strip HTML tags
    text = re.sub(r"\s+", " ", text).strip()
    return text


class NewsFetcher:
    def __init__(self):
        self.client = httpx.AsyncClient(timeout=15.0, follow_redirects=True)

    async def close(self):
        await self.client.aclose()

    # ── NewsAPI ────────────────────────────────────────────────────────────────
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=2, max=10))
    async def fetch_newsapi(self, symbol: str, company_name: str) -> list[NewsItem]:
        if not settings.newsapi_key:
            return []
        try:
            resp = await self.client.get(
                "https://newsapi.org/v2/everything",
                params={
                    "q": f'"{company_name}" stock OR earnings OR results',
                    "language": "en",
                    "sortBy": "publishedAt",
                    "pageSize": 20,
                    "apiKey": settings.newsapi_key,
                },
            )
            resp.raise_for_status()
            articles = resp.json().get("articles", [])
            items = []
            for a in articles:
                if not a.get("title") or not a.get("url"):
                    continue
                pub = a.get("publishedAt", "")
                try:
                    published = datetime.fromisoformat(pub.replace("Z", "+00:00"))
                except Exception:
                    published = datetime.now(timezone.utc)
                source_url = a.get("url", "")
                items.append(
                    NewsItem(
                        title=_clean_text(a.get("title", "")),
                        description=_clean_text(a.get("description") or ""),
                        url=source_url,
                        source=a.get("source", {}).get("name", "NewsAPI"),
                        published_at=published,
                        symbol=symbol,
                        credibility_score=get_credibility(source_url),
                    )
                )
            return items
        except Exception as e:
            logger.warning(f"NewsAPI fetch failed for {symbol}: {e}")
            return []

    # ── RSS feeds ──────────────────────────────────────────────────────────────
    async def fetch_rss(self, watchlist: list[str]) -> list[NewsItem]:
        items: list[NewsItem] = []
        loop = asyncio.get_event_loop()

        async def _parse_feed(url: str):
            try:
                feed = await loop.run_in_executor(None, feedparser.parse, url)
                for entry in feed.entries[:30]:
                    title = _clean_text(getattr(entry, "title", ""))
                    desc = _clean_text(getattr(entry, "summary", ""))
                    combined = f"{title} {desc}"
                    symbol = extract_symbol(combined)
                    if not symbol or symbol not in watchlist:
                        continue
                    link = getattr(entry, "link", "")
                    pub_parsed = getattr(entry, "published_parsed", None)
                    if pub_parsed:
                        import time
                        published = datetime.fromtimestamp(time.mktime(pub_parsed), tz=timezone.utc)
                    else:
                        published = datetime.now(timezone.utc)
                    items.append(
                        NewsItem(
                            title=title,
                            description=desc[:500],
                            url=link,
                            source=feed.feed.get("title", url),
                            published_at=published,
                            symbol=symbol,
                            credibility_score=get_credibility(link),
                        )
                    )
            except Exception as e:
                logger.warning(f"RSS parse failed for {url}: {e}")

        await asyncio.gather(*[_parse_feed(u) for u in RSS_FEEDS])
        return items

    # ── Combined fetch ─────────────────────────────────────────────────────────
    async def fetch_all(self, watchlist: list[str]) -> list[NewsItem]:
        """Fetch from all sources and deduplicate by URL."""
        COMPANY_NAMES = {
            "TCS": "Tata Consultancy Services",
            "INFY": "Infosys",
            "WIPRO": "Wipro",
            "HCLTECH": "HCL Technologies",
            "RELIANCE": "Reliance Industries",
            "HDFC": "HDFC Bank",
            "ICICIBANK": "ICICI Bank",
            "AXISBANK": "Axis Bank",
            "SBIN": "State Bank of India",
            "ONGC": "ONGC",
            "NTPC": "NTPC",
            "POWERGRID": "Power Grid Corporation",
            "MARUTI": "Maruti Suzuki",
            "TATAMOTORS": "Tata Motors",
            "BAJFINANCE": "Bajaj Finance",
            "KOTAKBANK": "Kotak Mahindra Bank",
        }

        tasks = [
            self.fetch_newsapi(sym, COMPANY_NAMES.get(sym, sym))
            for sym in watchlist
        ]
        api_results = await asyncio.gather(*tasks)

        all_items: list[NewsItem] = []
        for result in api_results:
            all_items.extend(result)

        rss_items = await self.fetch_rss(watchlist)
        all_items.extend(rss_items)

        # Deduplicate by URL
        seen: set[str] = set()
        unique: list[NewsItem] = []
        for item in all_items:
            if item.url not in seen and item.url:
                seen.add(item.url)
                unique.append(item)

        logger.info(f"Fetched {len(unique)} unique news items")
        return unique