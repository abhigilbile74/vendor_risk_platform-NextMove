"""
api/analysis.py
On-demand analysis endpoints — analyze any headline instantly.
"""
from fastapi import APIRouter, Body
from pydantic import BaseModel, Field

from services.ai_engine import analyze_news

router = APIRouter(prefix="/api/analysis", tags=["Analysis"])


class AnalyzeRequest(BaseModel):
    symbol: str = Field(..., example="TCS")
    title: str = Field(..., example="TCS beats Q4 earnings estimates, raises FY26 guidance")
    description: str = Field("", example="Tata Consultancy Services reported a 12% rise in net profit...")
    source_url: str = Field("", example="https://economictimes.indiatimes.com/...")


@router.post("/analyze")
async def analyze_headline(body: AnalyzeRequest = Body(...)):
    """
    Instantly analyze any headline + description for a given stock symbol.
    Returns full sentiment breakdown and BUY/SELL/NEUTRAL signal.
    No DB write — pure in-memory analysis.
    """
    result = analyze_news(
        symbol=body.symbol.upper(),
        title=body.title,
        description=body.description,
        source_url=body.source_url,
    )
    return result.to_dict()


@router.post("/batch")
async def analyze_batch(items: list[AnalyzeRequest] = Body(...)):
    """Analyze up to 20 headlines in one request."""
    if len(items) > 20:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="Max 20 items per batch")
    results = [
        analyze_news(
            symbol=item.symbol.upper(),
            title=item.title,
            description=item.description,
            source_url=item.source_url,
        ).to_dict()
        for item in items
    ]
    return {"count": len(results), "results": results}