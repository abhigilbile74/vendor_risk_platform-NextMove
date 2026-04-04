"""
config/sectors.py
Maps NSE ticker symbols → sectors for heatmap aggregation.
"""

SECTOR_MAP: dict[str, str] = {
    # IT
    "TCS": "IT",
    "INFY": "IT",
    "WIPRO": "IT",
    "HCLTECH": "IT",
    "TECHM": "IT",
    "MPHASIS": "IT",
    "LTIM": "IT",

    # Banking
    "HDFC": "Banking",
    "ICICIBANK": "Banking",
    "AXISBANK": "Banking",
    "SBIN": "Banking",
    "KOTAKBANK": "Banking",
    "INDUSINDBK": "Banking",
    "BANDHANBNK": "Banking",

    # Energy
    "ONGC": "Energy",
    "NTPC": "Energy",
    "POWERGRID": "Energy",
    "ADANIGREEN": "Energy",
    "TATAPOWER": "Energy",
    "BPCL": "Energy",
    "IOC": "Energy",

    # Auto
    "MARUTI": "Auto",
    "TATAMOTORS": "Auto",
    "BAJAJ-AUTO": "Auto",
    "HEROMOTOCO": "Auto",
    "M&M": "Auto",
    "EICHERMOT": "Auto",

    # Finance / NBFC
    "BAJFINANCE": "Finance",
    "BAJAJFINSV": "Finance",
    "HDFCLIFE": "Finance",
    "SBILIFE": "Finance",
    "ICICIPRULI": "Finance",
    "CHOLAFIN": "Finance",

    # Pharma
    "SUNPHARMA": "Pharma",
    "DRREDDY": "Pharma",
    "CIPLA": "Pharma",
    "DIVISLAB": "Pharma",
    "BIOCON": "Pharma",

    # FMCG
    "HINDUNILVR": "FMCG",
    "ITC": "FMCG",
    "NESTLEIND": "FMCG",
    "BRITANNIA": "FMCG",
    "DABUR": "FMCG",

    # Metals
    "TATASTEEL": "Metals",
    "JSWSTEEL": "Metals",
    "HINDALCO": "Metals",
    "VEDL": "Metals",

    # Telecom
    "BHARTIARTL": "Telecom",
    "IDEA": "Telecom",
}

# Reverse map: sector → list of symbols
SECTOR_TO_SYMBOLS: dict[str, list[str]] = {}
for sym, sec in SECTOR_MAP.items():
    SECTOR_TO_SYMBOLS.setdefault(sec, []).append(sym)

# Source credibility scores (0.0 → 1.0)
SOURCE_CREDIBILITY: dict[str, float] = {
    "reuters.com": 1.0,
    "bloomberg.com": 1.0,
    "wsj.com": 0.95,
    "ft.com": 0.95,
    "economictimes.indiatimes.com": 0.85,
    "moneycontrol.com": 0.82,
    "livemint.com": 0.85,
    "businessstandard.com": 0.87,
    "financialexpress.com": 0.83,
    "ndtv.com": 0.75,
    "thehindu.com": 0.80,
    "hindustantimes.com": 0.75,
    "zeebiz.com": 0.70,
    "cnbctv18.com": 0.80,
    "business-standard.com": 0.87,
    "default": 0.50,   # unknown source
}


def get_credibility(source_url: str) -> float:
    """Return credibility score for a given source domain."""
    for domain, score in SOURCE_CREDIBILITY.items():
        if domain in source_url:
            return score
    return SOURCE_CREDIBILITY["default"]


def get_sector(symbol: str) -> str:
    return SECTOR_MAP.get(symbol.upper(), "Others")