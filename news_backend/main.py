from fastapi import FastAPI
from services.news_service import fetch_news
from services.sentiment_service import get_sentiment, sentiment_label
from services.fake_news_service import authenticity
from services.prediction_service import impact_score, market_prediction, final_decision
from ml.trainer import train_model
from ml.model import predict_ml

app = FastAPI()

model = train_model()


@app.get("/")
def home():
    return {"message": "NextMove News Engine Running 🚀"}


@app.get("/analyze/{company}")
def analyze(company: str):
    news_list = fetch_news(company)

    results = []

    for news in news_list:
        text = (news["title"] or "") + " " + (news["description"] or "")

        sentiment = get_sentiment(text)
        sentiment_type = sentiment_label(sentiment)

        auth_text = authenticity(text, news["source"])
        auth_val = 1 if auth_text == "LIKELY TRUE" else 0

        impact = impact_score(sentiment, auth_text)
        rule_prediction = market_prediction(impact)

        ml_prediction = predict_ml(model, sentiment, auth_val)

        results.append({
            "news": news["title"],
    "symbol": news.get("symbol", "N/A"), # Added symbol for context
    "sentiment": sentiment_type,
    "authenticity": auth_text,
    "ml_trend": "UP 📈" if ml_prediction == 1 else "DOWN 📉",
    "decision": final_decision(sentiment, auth_text)
        })

    return {
        "company": company,
        "analysis": results
    }