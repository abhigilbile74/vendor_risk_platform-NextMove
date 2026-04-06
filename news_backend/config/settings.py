"""
config/settings.py
Central settings loaded from .env via pydantic-settings.
"""
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Server
    app_host: str = "0.0.0.0"
    app_port: int = 8001
    app_env: str = "development"
    debug: bool = True

    # MongoDB
    mongodb_uri: str = "mongodb://localhost:27017"
    mongodb_db: str = "news_intelligence"

    # Redis
    redis_url: str = "redis://localhost:6379"
    cache_ttl_seconds: int = 300

    # News APIs
    newsapi_key: str = ""

    # ML
    model_dir: str = "ml/saved_models"
    retrain_threshold: int = 200
    min_confidence: float = 0.55

    # Scheduler
    collect_interval_minutes: int = 30
    label_delay_hours: int = 2

    # Watchlist
    watchlist: str = "TCS,INFY,WIPRO,HCLTECH,RELIANCE,HDFC,ICICIBANK,AXISBANK,SBIN,ONGC,NTPC,POWERGRID,MARUTI,TATAMOTORS,BAJFINANCE,KOTAKBANK"

    @property
    def watchlist_symbols(self) -> list[str]:
        return [s.strip() for s in self.watchlist.split(",")]


@lru_cache
def get_settings() -> Settings:
    return Settings()