"""
api/admin.py
Admin endpoints: trigger collection, labeling, retraining manually.
Also exposes model metrics and system health.
"""
from fastapi import APIRouter, BackgroundTasks, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase

from utils.database import get_db

router = APIRouter(prefix="/api/admin", tags=["Admin"])


@router.post("/collect")
async def trigger_collection(
    background_tasks: BackgroundTasks,
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    """Manually trigger a news collection cycle."""
    from jobs.collect_news import run_collection
    background_tasks.add_task(run_collection, db)
    return {"status": "triggered", "message": "Collection started in background"}


@router.post("/label")
async def trigger_labeling(
    background_tasks: BackgroundTasks,
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    """Manually trigger a labeling cycle."""
    from jobs.label_data import run_labeling
    background_tasks.add_task(run_labeling, db)
    return {"status": "triggered", "message": "Labeling started in background"}


@router.post("/retrain")
async def trigger_retrain(
    background_tasks: BackgroundTasks,
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    """Manually trigger ML model retraining."""
    from ml.trainer import run_training
    background_tasks.add_task(run_training, db)
    return {"status": "triggered", "message": "Retraining started in background"}


@router.get("/stats")
async def get_system_stats(db: AsyncIOMotorDatabase = Depends(get_db)):
    """Returns dataset stats, model status, scheduler status."""
    total_raw = await db.raw_news.count_documents({})
    labeled = await db.raw_news.count_documents({"labeled": True})
    unlabeled = await db.raw_news.count_documents({"labeled": False})
    total_predictions = await db.predictions.count_documents({})
    total_labeled_training = await db.labeled_news.count_documents({})

    # Label distribution
    pipeline = [
        {"$match": {"label": {"$exists": True}}},
        {"$group": {"_id": "$label", "count": {"$sum": 1}}},
    ]
    dist_cursor = db.labeled_news.aggregate(pipeline)
    label_dist_raw = await dist_cursor.to_list(length=10)
    label_dist = {d["_id"]: d["count"] for d in label_dist_raw}

    # Latest model metrics
    latest_model = await db.model_metrics.find_one(
        sort=[("trained_at", -1)],
        projection={"cv_f1_macro_mean": 1, "train_accuracy": 1, "n_samples": 1, "trained_at": 1},
    )
    if latest_model:
        latest_model["_id"] = str(latest_model["_id"])

    from config.settings import get_settings
    settings = get_settings()

    return {
        "raw_news": {"total": total_raw, "labeled": labeled, "unlabeled": unlabeled},
        "labeled_training": {
            "total": total_labeled_training,
            "distribution": label_dist,
            "threshold_to_train": settings.retrain_threshold,
            "ready_to_train": total_labeled_training >= settings.retrain_threshold,
        },
        "predictions": {"total": total_predictions},
        "latest_model": latest_model,
    }


@router.get("/model-history")
async def get_model_history(
    limit: int = 10,
    db: AsyncIOMotorDatabase = Depends(get_db),
):
    """Returns last N training runs with metrics."""
    cursor = db.model_metrics.find(
        sort=[("trained_at", -1)],
        limit=limit,
        projection={
            "cv_f1_macro_mean": 1,
            "cv_f1_macro_std": 1,
            "train_accuracy": 1,
            "n_samples": 1,
            "label_distribution": 1,
            "trained_at": 1,
        },
    )
    docs = await cursor.to_list(length=limit)
    for d in docs:
        d["_id"] = str(d["_id"])
    return {"history": docs}