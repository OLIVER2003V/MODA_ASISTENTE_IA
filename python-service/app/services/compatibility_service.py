"""
Outfit compatibility scoring service.
Loads the trained GradientBoostingClassifier at startup and exposes score_outfit().
"""

import os
import logging
from typing import List, Dict, Optional

import numpy as np

logger = logging.getLogger(__name__)

_model = None
_MODELS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "models")
_MODEL_PATH = os.path.join(_MODELS_DIR, "compatibility_model.joblib")


def load_model() -> None:
    """Load the compatibility model at app startup. Fails silently if not trained yet."""
    global _model
    if not os.path.exists(_MODEL_PATH):
        logger.warning(
            "Compatibility model not found at %s. "
            "Run 'python -m training.train' to generate it. "
            "Scoring endpoint will return neutral scores until then.",
            _MODEL_PATH,
        )
        return
    try:
        import joblib
        _model = joblib.load(_MODEL_PATH)
        logger.info("Outfit compatibility model loaded from %s", _MODEL_PATH)
    except Exception as exc:
        logger.error("Failed to load compatibility model: %s", exc)
        _model = None


def is_model_loaded() -> bool:
    return _model is not None


def score_outfit(
    garments: List[Dict],
    event: str = "",
) -> Dict:
    """
    Score the compatibility of a set of garments.

    Args:
        garments: list of dicts with at least 'category' and 'description'.
                  Optional: 'color', 'style', 'formality' for faster/more accurate scoring.
        event:    context string (e.g. "trabajo", "gym") — used for future features.

    Returns:
        dict with keys: score, label, details, warnings
    """
    from training.feature_extractor import (
        extract_features,
        infer_color, infer_style, infer_formality,
        _pairwise_color_harmony, _style_consistency,
        _formality_variance_inv, _category_balance,
    )

    if not garments:
        return {"score": 0.5, "label": "neutral", "details": {}, "warnings": ["No garments provided"]}

    # Extract individual features for the details breakdown
    enriched = []
    for g in garments:
        desc      = g.get("description", "")
        color     = g.get("color") or infer_color(desc)
        style     = g.get("style") or infer_style(desc)
        formality = g.get("formality") if g.get("formality") is not None else infer_formality(style)
        enriched.append({
            "color": color, "style": style,
            "formality": formality, "description": desc,
            "category": g.get("category", "TOP"),
        })

    styles      = [g["style"] for g in enriched]
    colors      = [g["color"] for g in enriched]
    formalities = [g["formality"] for g in enriched]
    categories  = [g["category"] for g in enriched]
    descriptions = [g["description"] for g in enriched if g["description"]]

    details = {
        "style_consistency":       round(_style_consistency(styles), 4),
        "color_harmony":           round(_pairwise_color_harmony(colors), 4),
        "formality_variance_inv":  round(_formality_variance_inv(formalities), 4),
        "clip_text_similarity":    0.5,  # computed below
        "category_balance":        round(_category_balance(categories), 4),
    }

    # Try CLIP similarity
    try:
        from app.services.clip_service import embed_text, cosine_similarity
        if len(descriptions) >= 2:
            embeddings = [embed_text(d) for d in descriptions]
            sim_scores = []
            for i in range(len(embeddings)):
                for j in range(i + 1, len(embeddings)):
                    if embeddings[i] and embeddings[j]:
                        sim_scores.append(float(cosine_similarity(embeddings[i], embeddings[j])))
            if sim_scores:
                details["clip_text_similarity"] = round(float(np.mean(sim_scores)), 4)
    except Exception:
        pass

    # Assemble feature vector in the same order used during training
    features = np.array([
        details["style_consistency"],
        details["color_harmony"],
        details["formality_variance_inv"],
        details["clip_text_similarity"],
        details["category_balance"],
    ], dtype=np.float32).reshape(1, -1)

    warnings: List[str] = []

    if _model is not None:
        try:
            score = float(_model.predict_proba(features)[0][1])
        except Exception as exc:
            logger.warning("Model prediction failed: %s", exc)
            score = float(np.mean(list(details.values())))
    else:
        # Model not trained yet — use weighted average of rule-based features
        score = float(
            0.30 * details["style_consistency"]
            + 0.30 * details["color_harmony"]
            + 0.20 * details["formality_variance_inv"]
            + 0.10 * details["clip_text_similarity"]
            + 0.10 * details["category_balance"]
        )
        warnings.append("Model not trained yet — using rule-based fallback score")

    # Build human-readable warnings
    if details["color_harmony"] < 0.3:
        warnings.append("Color clash detected between garments")
    if details["style_consistency"] < 0.5:
        warnings.append("Style mismatch: garments belong to different style families")
    if details["formality_variance_inv"] < 0.5:
        warnings.append("Formality mismatch: mixing formal and casual/sport pieces")
    if details["category_balance"] < 0.4:
        warnings.append("Category combination is unusual or incomplete")

    label = "compatible" if score >= 0.50 else "incompatible"

    return {
        "score":   round(score, 4),
        "label":   label,
        "details": details,
        "warnings": warnings,
    }
