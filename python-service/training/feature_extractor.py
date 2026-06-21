"""
Feature extraction for outfit compatibility.
Works in two modes:
  - Training mode: garment dicts have explicit 'color', 'style', 'formality' keys
  - Inference mode: only 'category' and 'description' are available; metadata is inferred
"""

import sys
import os
import re
import numpy as np
from typing import List, Dict, Optional

# Allow importing from parent directory (python-service/app/services/)
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from training.dataset_generator import COLOR_COMPATIBILITY

# ── Text-based inference helpers ─────────────────────────────────────────────

_COLOR_KEYWORDS = [
    "navy", "black", "white", "grey", "gray", "beige", "blue", "red", "brown",
    "olive", "burgundy", "orange", "green", "light_blue", "cream", "khaki",
    "silver", "pink", "charcoal", "camel", "tan", "rust", "fluorescent",
]

_FORMAL_KEYWORDS = [
    "button-down", "dress shirt", "oxford", "blazer", "suit", "trousers",
    "tuxedo", "waistcoat", "cufflinks", "wingtip", "derby", "loafer",
    "notch lapel", "peak lapel", "french cuff", "tie", "pocket square",
    "tailored", "wool blend", "ponte", "slim-fit dress",
]

_SPORT_KEYWORDS = [
    "moisture-wicking", "athletic", "compression", "running", "training",
    "mesh panel", "reflective", "jogging", "jogger", "eva midsole",
    "trail", "basketball", "cycling", "performance", "four-way stretch",
    "racerback", "packable",
]

_ELEGANT_KEYWORDS = [
    "silk", "satin", "velvet", "patent leather", "lace", "chiffon",
    "stiletto", "kitten heel", "draped", "cowl", "d'orsay",
    "hand-rolled", "seven-fold", "slip dress",
]

_FORMALITY_BY_STYLE = {"sport": 0, "casual": 2, "formal": 4, "elegant": 4}


def infer_color(description: str) -> str:
    desc = description.lower()
    # Specific multi-word colours first
    if "light blue" in desc or "light_blue" in desc:
        return "light_blue"
    if "charcoal" in desc:
        return "grey"
    if "camel" in desc or "tan " in desc:
        return "beige"
    if "cream" in desc or "ivory" in desc or "champagne" in desc or "nude" in desc:
        return "cream"
    if "khaki" in desc:
        return "khaki"
    if "fluorescent" in desc or "neon" in desc:
        return "orange"
    for color in _COLOR_KEYWORDS:
        if color in desc:
            return color.replace("gray", "grey")
    return "neutral"


def infer_style(description: str) -> str:
    desc = description.lower()
    elegant_hits = sum(1 for k in _ELEGANT_KEYWORDS if k in desc)
    formal_hits = sum(1 for k in _FORMAL_KEYWORDS if k in desc)
    sport_hits = sum(1 for k in _SPORT_KEYWORDS if k in desc)

    if elegant_hits >= 2:
        return "elegant"
    if elegant_hits == 1 and formal_hits >= 1:
        return "elegant"
    if formal_hits >= 2:
        return "formal"
    if sport_hits >= 2:
        return "sport"
    if sport_hits >= 1:
        return "sport"
    if formal_hits == 1:
        return "formal"
    return "casual"


def infer_formality(style: str) -> int:
    return _FORMALITY_BY_STYLE.get(style, 2)


# ── Feature computation ───────────────────────────────────────────────────────

def _pairwise_color_harmony(colors: List[str]) -> float:
    if len(colors) < 2:
        return 1.0
    scores = []
    for i in range(len(colors)):
        for j in range(i + 1, len(colors)):
            ca, cb = colors[i], colors[j]
            if ca == cb or ca == "neutral" or cb == "neutral":
                scores.append(0.75)
                continue
            compat = COLOR_COMPATIBILITY.get(ca, {"allows": [], "avoids": []})
            if cb in compat["allows"]:
                scores.append(1.0)
            elif cb in compat["avoids"]:
                scores.append(0.05)
            else:
                scores.append(0.55)
    return float(np.mean(scores)) if scores else 0.75


def _style_consistency(styles: List[str]) -> float:
    if not styles:
        return 1.0
    from collections import Counter
    counts = Counter(styles)
    majority = counts.most_common(1)[0][1]
    return majority / len(styles)


def _formality_variance_inv(formalities: List[int]) -> float:
    if len(formalities) < 2:
        return 1.0
    var = float(np.var(formalities))
    max_var = 6.25  # var([0,5]) = 6.25
    return max(0.0, 1.0 - var / max_var)


def _category_balance(categories: List[str]) -> float:
    from collections import Counter
    cat_count = Counter(categories)
    score = 0.4

    # Has at least 2 distinct categories
    if len(cat_count) >= 2:
        score += 0.1

    # Has FOOTWEAR (complete outfit)
    if "FOOTWEAR" in cat_count:
        score += 0.25

    # Has TOP+BOTTOM or DRESS (valid base combination)
    if ("TOP" in cat_count and "BOTTOM" in cat_count):
        score += 0.15
    elif "DRESS" in cat_count:
        score += 0.15

    # DRESS + TOP or DRESS + BOTTOM = invalid combination
    if "DRESS" in cat_count and ("TOP" in cat_count or "BOTTOM" in cat_count):
        score -= 0.4

    # Duplicate main categories are invalid
    for cat in ["TOP", "BOTTOM", "DRESS", "FOOTWEAR", "OUTERWEAR"]:
        if cat_count.get(cat, 0) > 1:
            score -= 0.2

    return max(0.0, min(1.0, score))


def _clip_text_similarity(descriptions: List[str]) -> float:
    """Average pairwise cosine similarity of CLIP embeddings. Falls back to 0.5."""
    if len(descriptions) < 2:
        return 0.5
    try:
        from app.services.clip_service import embed_text, cosine_similarity
        embeddings = [embed_text(d) for d in descriptions]
        scores = []
        for i in range(len(embeddings)):
            for j in range(i + 1, len(embeddings)):
                if embeddings[i] and embeddings[j]:
                    sim = cosine_similarity(embeddings[i], embeddings[j])
                    scores.append(float(sim))
        return float(np.mean(scores)) if scores else 0.5
    except Exception:
        return 0.5


def extract_features(garments: List[Dict], use_clip: bool = True) -> np.ndarray:
    """
    Extract 5 compatibility features from a list of garment dicts.

    Each garment may have:
      - 'color', 'style', 'formality' (explicit — fast path used in training)
      - 'description', 'category' (inference path used at runtime)

    Returns np.ndarray of shape (5,):
      [style_consistency, color_harmony, formality_variance_inv, clip_similarity, category_balance]
    """
    enriched = []
    for g in garments:
        color     = g.get("color")
        style     = g.get("style")
        formality = g.get("formality")
        desc      = g.get("description", "")
        category  = g.get("category", "TOP")

        if color is None:
            color = infer_color(desc)
        if style is None:
            style = infer_style(desc)
        if formality is None:
            formality = infer_formality(style)

        enriched.append({
            "color": color,
            "style": style,
            "formality": formality,
            "description": desc,
            "category": category,
        })

    styles      = [g["style"] for g in enriched]
    colors      = [g["color"] for g in enriched]
    formalities = [g["formality"] for g in enriched]
    categories  = [g["category"] for g in enriched]
    descriptions = [g["description"] for g in enriched if g["description"]]

    f1 = _style_consistency(styles)
    f2 = _pairwise_color_harmony(colors)
    f3 = _formality_variance_inv(formalities)
    f4 = _clip_text_similarity(descriptions) if use_clip else 0.5
    f5 = _category_balance(categories)

    return np.array([f1, f2, f3, f4, f5], dtype=np.float32)
