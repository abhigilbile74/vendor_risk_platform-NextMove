"""
jobs/scheduler.py
APScheduler configuration.
Runs:
  - collect_news every 30 minutes
  - label_data every 30 minutes (offset by 5 min)
  - retrain ML model once daily (midnight)
"""
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.interval import IntervalTrigger
from loguru import logger

from config.settings import get_settings
from utils.database import get_db

settings = get_settings()

_scheduler: AsyncIOScheduler | None = None


async def _job_collect():
    from jobs.collect_news import run_collection
    db = get_db()
    try:
        result = await run_collection(db)
        logger.info(f"[SCHEDULER] collect_news: {result}")
    except Exception as e:
        logger.error(f"[SCHEDULER] collect_news failed: {e}")


async def _job_label():
    from jobs.label_data import run_labeling
    db = get_db()
    try:
        result = await run_labeling(db)
        logger.info(f"[SCHEDULER] label_data: {result}")
    except Exception as e:
        logger.error(f"[SCHEDULER] label_data failed: {e}")


async def _job_retrain():
    from ml.trainer import run_training
    db = get_db()
    try:
        result = await run_training(db)
        logger.info(f"[SCHEDULER] retrain: {result}")
    except Exception as e:
        logger.error(f"[SCHEDULER] retrain failed: {e}")


def start_scheduler():
    global _scheduler
    _scheduler = AsyncIOScheduler(timezone="Asia/Kolkata")

    interval = settings.collect_interval_minutes

    # Collection: every N minutes
    _scheduler.add_job(
        _job_collect,
        trigger=IntervalTrigger(minutes=interval),
        id="collect_news",
        replace_existing=True,
        max_instances=1,
    )

    # Labeling: every N minutes, offset by 5 minutes
    _scheduler.add_job(
        _job_label,
        trigger=IntervalTrigger(minutes=interval, start_date="2000-01-01 00:05:00"),
        id="label_data",
        replace_existing=True,
        max_instances=1,
    )

    # Retrain: once daily at midnight IST
    _scheduler.add_job(
        _job_retrain,
        trigger=CronTrigger(hour=0, minute=0, timezone="Asia/Kolkata"),
        id="retrain_model",
        replace_existing=True,
        max_instances=1,
    )

    _scheduler.start()
    logger.info(
        f"Scheduler started. Collect every {interval}min, Label every {interval}min, Retrain daily at midnight IST"
    )


def stop_scheduler():
    global _scheduler
    if _scheduler and _scheduler.running:
        _scheduler.shutdown()
        logger.info("Scheduler stopped")