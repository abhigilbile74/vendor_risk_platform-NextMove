def impact_score(sentiment, authenticity):
    score = sentiment * 50

    if authenticity == "LIKELY TRUE":
        score += 30
    elif authenticity == "UNVERIFIED":
        score += 10
    else:
        score -= 10

    return score


def market_prediction(score):
    if score < -20:
        return "STRONG SELL"
    elif score < 0:
        return "SELL"
    elif score < 20:
        return "HOLD"
    else:
        return "BUY"


def final_decision(sentiment, authenticity):
    if authenticity == "LIKELY TRUE" and sentiment < 0:
        return "REAL IMPACT - SELL"

    elif authenticity != "LIKELY TRUE" and sentiment < 0:
        return "TEMP DIP - HOLD"

    return "NO MAJOR IMPACT"