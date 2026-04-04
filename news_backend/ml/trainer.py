"""
ml/trainer.py
Trains an XGBoost classifier on labeled news data from MongoDB.
Saves model + scaler to disk. Records metrics to DB.
Only runs when enough labeled samples exist.
"""
import os
import asyncio
from datetime import datetime, timezone

import joblib
import numpy as np
import pandas as pd
from loguru import logger
from sklearn.model_selection import StratifiedKFold, cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report, confusion_matrix
from imblearn.over_sampling import SMOTE
from xgboost import XGBClassifier

from config.settings import get_settings

settings = get_settings()

FEATURE_COLS = [
    "sentiment_score",
    "vader_compound",
    "credibility_score",
    "bullish_hits",
    "bearish_hits",
    "fake_risk_score",
    "sentiment_positive",
    "sentiment_negative",
    "strength_strong",
    "strength_moderate",
]

# Map string labels to int (XGBoost needs int classes)
LABEL_MAP = {"UP": 2, "STABLE": 1, "DOWN": 0}
LABEL_REVERSE = {v: k for k, v in LABEL_MAP.items()}

# For prediction_service compatibility we remap to BUY/NEUTRAL/SELL
SIGNAL_MAP = {"UP": "BUY", "STABLE": "NEUTRAL", "DOWN": "SELL"}


async def load_training_data(db) -> pd.DataFrame:
    cursor = db.labeled_news.find(
        {"label": {"$in": ["UP", "DOWN", "STABLE"]}},
        {col: 1 for col in FEATURE_COLS + ["label"]},
    )
    docs = await cursor.to_list(length=50000)
    return pd.DataFrame(docs)


def train(df: pd.DataFrame) -> dict:
    """
    Train XGBoost model and return metrics dict.
    """
    logger.info(f"Training on {len(df)} samples")
    label_dist = df["label"].value_counts().to_dict()
    logger.info(f"Label distribution: {label_dist}")

    X = df[FEATURE_COLS].values
    y = df["label"].map(LABEL_MAP).values

    # SMOTE to handle class imbalance
    try:
        sm = SMOTE(random_state=42, k_neighbors=min(5, min(label_dist.values()) - 1))
        X_res, y_res = sm.fit_resample(X, y)
        logger.info(f"After SMOTE: {len(X_res)} samples")
    except Exception as e:
        logger.warning(f"SMOTE failed ({e}), using raw data")
        X_res, y_res = X, y

    xgb = XGBClassifier(
        n_estimators=300,
        max_depth=5,
        learning_rate=0.05,
        subsample=0.8,
        colsample_bytree=0.8,
        use_label_encoder=False,
        eval_metric="mlogloss",
        random_state=42,
        n_jobs=-1,
    )

    scaler = StandardScaler()
    pipeline = Pipeline([("scaler", scaler), ("clf", xgb)])

    # Cross-validation
    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
    cv_scores = cross_val_score(pipeline, X_res, y_res, cv=cv, scoring="f1_macro", n_jobs=-1)
    logger.info(f"CV F1-macro: {cv_scores.mean():.4f} ± {cv_scores.std():.4f}")

    # Final fit on all data
    pipeline.fit(X_res, y_res)
    y_pred = pipeline.predict(X_res)

    # Convert numeric predictions to signal labels for the model classes_ attribute
    # We store predictions as BUY/NEUTRAL/SELL
    class_labels = np.array(["SELL", "NEUTRAL", "BUY"])  # matches 0,1,2
    pipeline.classes_ = class_labels

    # Replace the clf's predict to output string labels
    report = classification_report(
        y_res,
        y_pred,
        target_names=["DOWN", "STABLE", "UP"],
        output_dict=True,
    )
    cm = confusion_matrix(y_res, y_pred).tolist()

    metrics = {
        "cv_f1_macro_mean": float(cv_scores.mean()),
        "cv_f1_macro_std": float(cv_scores.std()),
        "train_accuracy": float(report["accuracy"]),
        "classification_report": report,
        "confusion_matrix": cm,
        "n_samples": len(df),
        "label_distribution": label_dist,
        "feature_cols": FEATURE_COLS,
        "trained_at": datetime.now(timezone.utc).isoformat(),
    }

    return pipeline, metrics


async def run_training(db) -> dict:
    """Full training pipeline: load data → train → save → record metrics."""
    df = await load_training_data(db)

    if len(df) < settings.retrain_threshold:
        msg = (
            f"Only {len(df)} labeled samples — need {settings.retrain_threshold} to train. "
            f"Keep collecting!"
        )
        logger.warning(msg)
        return {"status": "skipped", "reason": msg, "n_samples": len(df)}

    pipeline, metrics = train(df)

    # Save model
    os.makedirs(settings.model_dir, exist_ok=True)
    model_path = os.path.join(settings.model_dir, "xgb_model.joblib")
    joblib.dump(pipeline, model_path)
    logger.info(f"Model saved to {model_path}")

    # Save feature list for future compatibility checks
    meta_path = os.path.join(settings.model_dir, "feature_cols.joblib")
    joblib.dump(FEATURE_COLS, meta_path)

    # Record metrics in DB
    await db.model_metrics.insert_one({**metrics, "model_path": model_path})

    # Reload the singleton prediction service model
    from services.prediction_service import get_prediction_service
    svc = get_prediction_service()
    svc.load_model()

    logger.success(
        f"Training complete. CV F1-macro: {metrics['cv_f1_macro_mean']:.4f}, "
        f"Accuracy: {metrics['train_accuracy']:.4f}"
    )
    return {"status": "success", **metrics}