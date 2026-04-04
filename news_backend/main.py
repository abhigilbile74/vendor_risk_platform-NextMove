import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

"""
main.py
FastAPI application entry point.
Wires up: DB, Cache, Scheduler, CORS, Routers.
"""
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from config.settings import get_settings
from utils.database import connect_db, close_db
from utils.cache import connect_cache, close_cache
from Jobs.scheduler import start_scheduler, stop_scheduler
from API.news import router as news_router
from API.signals import router as signals_router
from API.admin import router as admin_router
from API.analysis import router as analysis_router
from API.terminal import router as terminal_router

settings = get_settings()

# â”€â”€ Logging â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
logger.remove()
logger.add(sys.stderr, level="INFO" if not settings.debug else "DEBUG")
logger.add(
    "logs/app.log",
    rotation="50 MB",
    retention="7 days",
    level="INFO",
    enqueue=True,
)


# â”€â”€ Lifespan â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("ðŸš€ Starting News Intelligence Backend...")
    await connect_db()
    await connect_cache()
    start_scheduler()
    # Immediately run one collection on startup
    from Jobs.collect_news import run_collection
    from utils.database import get_db
    try:
        await run_collection(get_db())
    except Exception as e:
        logger.warning(f"Startup collection failed (non-fatal): {e}")
    logger.info("âœ… All systems ready")
    yield
    logger.info("ðŸ›‘ Shutting down...")
    stop_scheduler()
    await close_cache()
    await close_db()


app = FastAPI(
    title="News Intelligence API",
    description="Real-time news sentiment + market signal engine for NSE stocks",
    version="2.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # tighten in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

#  Routers 
app.include_router(news_router)
app.include_router(signals_router)
app.include_router(admin_router)
app.include_router(analysis_router)
app.include_router(terminal_router)


@app.get("/", tags=["Health"])
async def root():
    return {
        "service": "News Intelligence API",
        "version": "2.0.0",
        "status": "running",
        "docs": "/docs",
    }


@app.get("/health", tags=["Health"])
async def health():
    from utils.database import get_db
    from utils.cache import get_cached
    db_ok = False
    cache_ok = False
    try:
        await get_db().command("ping")
        db_ok = True
    except Exception:
        pass
    try:
        await get_cached("ping")
        cache_ok = True
    except Exception:
        cache_ok = True   # Redis is optional
    return {
        "database": "ok" if db_ok else "error",
        "cache": "ok" if cache_ok else "unavailable",
        "status": "healthy" if db_ok else "degraded",
    }


# â”€â”€ Dev runner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.app_host,
        port=settings.app_port,
        reload=settings.debug,
        log_level="debug" if settings.debug else "info",
    )
