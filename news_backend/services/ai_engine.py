from transformers import BertTokenizer, BertForSequenceClassification
from scipy.special import softmax
import torch

# Load the FinBERT Model (The "Brain")
model_name = "yiyanghkust/finbert-tone"
tokenizer = BertTokenizer.from_pretrained(model_name)
model = BertForSequenceClassification.from_pretrained(model_name)

def analyze_market_impact(headline):
    # 1. Tokenize the news
    inputs = tokenizer(headline, return_tensors="pt", padding=True, truncation=True, max_length=512)
    
    # 2. Predict Sentiment
    with torch.no_grad():
        outputs = model(**inputs)
    
    # 3. Process Scores
    scores = outputs.logits.detach().numpy()[0]
    scores = softmax(scores) # Converts to percentages
    
    # FinBERT labels: 0: Neutral, 1: Positive, 2: Negative
    sentiment_map = {0: "Neutral", 1: "Positive", 2: "Negative"}
    max_idx = scores.argmax()
    sentiment = sentiment_map[max_idx]
    confidence = scores[max_idx]

    # 4. Market Impact Logic (The "Learning" Part)
    impact = "HOLD"
    severity = "LOW"

    if sentiment == "Negative":
        impact = "SELL"
        severity = "HIGH" if confidence > 0.8 else "MEDIUM"
    elif sentiment == "Positive":
        impact = "BUY"
        severity = "HIGH" if confidence > 0.8 else "MEDIUM"

    return {
        "sentiment": sentiment,
        "confidence": float(confidence),
        "severity": severity,
        "suggested_action": impact
    }

# --- QUICK TEST ---
if __name__ == "__main__":
    test_news = "Reliance shares plunge 5% after massive fraud investigation begins"
    print(analyze_market_impact(test_news))