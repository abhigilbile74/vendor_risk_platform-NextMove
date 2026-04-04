# 📊 News Intelligence Backend — v2.0

Real-time NSE stock news aggregation, sentiment analysis, ML-based signal generation, and Bloomberg-style sector heatmap.

---

## Architecture

```
news_backend/
├── main.py                    # FastAPI app entry point
├── config/
│   ├── settings.py            # Pydantic Settings (loads .env)
│   └── sectors.py             # Sector map, source credibility scores
├── services/
│   ├── news_fetcher.py        # NewsAPI + RSS multi-source fetcher
│   ├── sentiment_service.py   # VADER + keyword boosting (multi-layer)
│   ├── fake_news_service.py   # Credibility scoring + cross-verification
│   ├── prediction_service.py  # ML model or rule-based fallback
│   ├── sector_logic.py        # Sector heatmap aggregation
│   ├── ai_engine.py           # Central analysis coordinator
│   └── intelligence.py       # Terminal card builder + market context
├── jobs/
│   ├── collect_news.py        # Fetches news + prices every 30 min
│   ├── label_data.py          # Labels articles 2h later by price change
│   └── scheduler.py           # APScheduler (collect / label / retrain)
├── ml/
│   ├── trainer.py             # XGBoost + SMOTE + cross-validation
│   └── saved_models/          # Persisted model files (auto-created)
├── api/
│   ├── news.py                # GET /api/news/feed
│   ├── signals.py             # GET /api/signals/heatmap, /company/{sym}
│   ├── analysis.py            # POST /api/analysis/analyze (on-demand)
│   ├── terminal.py            # GET /api/terminal/card/{sym}, /summary
│   └── admin.py               # POST /api/admin/collect|label|retrain
└── utils/
    ├── database.py            # Async MongoDB (Motor)
    └── cache.py               # Redis async cache
```

---

## Data Pipeline

```
Every 30 minutes:
  ┌─────────────────┐
  │  collect_news   │  → NewsAPI + 5 RSS feeds
  │  (job)          │  → Sentiment analysis
  └────────┬────────┘  → Price snapshot (yfinance)
           │            → Save to raw_news + predictions
           ▼
  ┌─────────────────┐
  │   label_data    │  → Finds articles > 2h old
  │   (job)         │  → Fetches current price
  └────────┬────────┘  → Computes UP/DOWN/STABLE label
           │            → Saves to labeled_news (training data)
           ▼
  ┌─────────────────┐
  │  retrain (daily)│  → Loads all labeled_news
  │  XGBoost        │  → SMOTE balancing
  └─────────────────┘  → 5-fold CV + saves model
```

**Labeling rule:**
- Price up ≥ 0.5% in 2h → **UP** (→ BUY)  
- Price down ≥ 0.5% in 2h → **DOWN** (→ SELL)  
- Within ±0.5% → **STABLE** (→ NEUTRAL)

---

## Sentiment Engine (Multi-layer)

| Layer | What it does |
|---|---|
| VADER | NLP compound score (-1 to +1) |
| Keyword booster | +0.05 per bullish keyword, -0.05 per bearish |
| Credibility weight | Score × (0.5 + credibility × 0.5) |
| Fake risk | Pattern matching + source credibility inversion |
| Final score | Capped at [-1, +1] with label + strength |

---

## ML Model

- **Algorithm:** XGBoost Classifier
- **Balancing:** SMOTE (handles UP/DOWN/STABLE imbalance)
- **Validation:** Stratified 5-fold cross-validation (F1-macro)
- **Minimum samples to train:** 200 (configurable)
- **Features:** 10 numeric features per article
- **Fallback:** Rule-based heuristics until model is trained

**Features used:**
1. `sentiment_score` — final weighted score
2. `vader_compound` — raw VADER score
3. `credibility_score` — source credibility (0–1)
4. `bullish_hits` — count of bullish keywords
5. `bearish_hits` — count of bearish keywords
6. `fake_risk_score` — fake news probability
7. `sentiment_positive` — binary flag
8. `sentiment_negative` — binary flag
9. `strength_strong` — binary flag
10. `strength_moderate` — binary flag

---

## Setup

### Prerequisites
- Python 3.11+
- MongoDB 7+ (local or Atlas)
- Redis 7+ (optional but recommended)
- NewsAPI key (free at newsapi.org)

### 1. Install

```bash
git clone <your-repo>
cd news_backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure

```bash
cp .env.example .env
# Edit .env and set NEWSAPI_KEY, MONGODB_URI, etc.
```

### 3. Run locally

```bash
# Start MongoDB + Redis
# (or use docker-compose up mongo redis)

python main.py
# API at http://localhost:8000
# Docs at http://localhost:8000/docs
```

### 4. Docker (recommended)

```bash
cp .env.example .env    # fill in NEWSAPI_KEY
docker-compose up -d
```

---

## API Endpoints

### News Feed
```
GET  /api/news/feed?hours=6&symbol=TCS&limit=50
GET  /api/news/article/{article_hash}
```

### Signals
```
GET  /api/signals/heatmap?hours=6
GET  /api/signals/company/{symbol}?hours=6
GET  /api/signals/watchlist?hours=6
```

### On-demand Analysis
```
POST /api/analysis/analyze
Body: { "symbol": "TCS", "title": "...", "description": "...", "source_url": "..." }

POST /api/analysis/batch
Body: [ { ...same fields... }, ... ]  (max 20)
```

### Terminal (Bloomberg UI)
```
GET  /api/terminal/card/{symbol}
GET  /api/terminal/summary?hours=6
GET  /api/terminal/market-status
```

### Admin
```
POST /api/admin/collect     → trigger news collection now
POST /api/admin/label       → trigger labeling now
POST /api/admin/retrain     → trigger ML training now
GET  /api/admin/stats       → dataset + model metrics
GET  /api/admin/model-history
```

---

## Training Data Timeline

| Day | Labeled Samples | Status |
|---|---|---|
| Day 1 | ~50 | Collecting — rule-based mode |
| Day 2-3 | ~150 | Still collecting |
| Day 4+ | 200+ | **Auto-trains XGBoost** |
| Week 2 | 500+ | High-quality model |

Tip: You can run `POST /api/admin/collect` manually to accelerate collection.

---

## Source Credibility

| Source | Score |
|---|---|
| Reuters, Bloomberg | 1.0 |
| WSJ, FT | 0.95 |
| Business Standard, Livemint | 0.85–0.87 |
| Economic Times | 0.85 |
| Moneycontrol | 0.82 |
| NDTV, Zee Biz | 0.70–0.75 |
| Unknown blog | 0.50 |

---

## Watchlist (default)

`TCS, INFY, WIPRO, HCLTECH, RELIANCE, HDFC, ICICIBANK, AXISBANK, SBIN, ONGC, NTPC, POWERGRID, MARUTI, TATAMOTORS, BAJFINANCE, KOTAKBANK`

Change via `WATCHLIST=` in `.env`.

---

## MongoDB Collections

| Collection | Purpose |
|---|---|
| `raw_news` | Every fetched article + sentiment + price |
| `labeled_news` | Training dataset (features + UP/DOWN/STABLE) |
| `predictions` | Per-symbol signals per collection cycle |
| `model_metrics` | Training run history (F1, accuracy, etc.) |

---

## Notes

- **Not financial advice.** This system generates sentiment-based signals, not trading recommendations.  
- The model accuracy improves significantly after 500+ labeled samples (roughly 5–7 days of operation).  
- NSE prices via `yfinance` may have a 15-minute delay on free tier.