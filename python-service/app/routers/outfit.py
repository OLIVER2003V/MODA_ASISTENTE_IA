"""
POST /outfit/score  — score the compatibility of a proposed outfit.
"""

from typing import List, Optional
from fastapi import APIRouter
from pydantic import BaseModel, Field

router = APIRouter()


class GarmentInput(BaseModel):
    category:    str = Field(..., description="TOP | BOTTOM | DRESS | OUTERWEAR | FOOTWEAR | ACCESSORY")
    description: str = Field(..., description="AI-generated garment description")
    color:       Optional[str] = Field(None, description="Dominant color (optional, inferred if absent)")
    style:       Optional[str] = Field(None, description="Style family (optional, inferred if absent)")


class OutfitScoreRequest(BaseModel):
    garments: List[GarmentInput] = Field(..., min_length=1, description="Garments in the outfit")
    event:    Optional[str]      = Field("", description="Event context (e.g. 'trabajo', 'gym')")


class OutfitScoreResponse(BaseModel):
    score:    float
    label:    str
    details:  dict
    warnings: List[str]
    model_active: bool


@router.post("/score", response_model=OutfitScoreResponse, summary="Score outfit compatibility")
def score_outfit(request: OutfitScoreRequest) -> OutfitScoreResponse:
    """
    Scores a proposed outfit using the trained GradientBoosting compatibility model.

    - **score**: 0.0 (incompatible) → 1.0 (fully compatible)
    - **label**: "compatible" or "incompatible"
    - **details**: individual feature scores that explain the rating
    - **warnings**: human-readable compatibility issues detected
    - **model_active**: false if the model hasn't been trained yet (uses rule-based fallback)
    """
    from app.services.compatibility_service import score_outfit as _score, is_model_loaded

    garments = [g.model_dump() for g in request.garments]
    result   = _score(garments, event=request.event or "")

    return OutfitScoreResponse(
        score=result["score"],
        label=result["label"],
        details=result["details"],
        warnings=result["warnings"],
        model_active=is_model_loaded(),
    )
