import requests
from config import NEWS_API_KEY

def fetch_news(company):
    url = f"https://newsapi.org/v2/everything?q={company}&apiKey={NEWS_API_KEY}&pageSize=5"

    response = requests.get(url).json()

    articles = []

    for a in response.get("articles", []):
        articles.append({
            "title": a.get("title", ""),
            "description": a.get("description", ""),
            "source": a.get("source", {}).get("name", "")
        })

    return articles