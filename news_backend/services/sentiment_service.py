from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

analyzer = SentimentIntensityAnalyzer()

def get_sentiment(text):
    score = analyzer.polarity_scores(text)["compound"]
    return score

def sentiment_label(score):
    if score <= -0.5:
        return "HIGH NEGATIVE"
    elif score < 0:
        return "LOW NEGATIVE"
    elif score == 0:
        return "NEUTRAL"
    else:
        return "POSITIVE"