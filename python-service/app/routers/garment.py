"""
POST /garment/analyze
  - Classifies a garment image using CLIP zero-shot classification.
  - Detects the dominant color.
  - Returns a CLIP embedding for the garment (storable for similarity search).
"""

import logging
from fastapi import APIRouter, File, UploadFile, HTTPException

from app.services import clip_service, color_service

logger = logging.getLogger(__name__)
router = APIRouter()

# ── Category definitions ───────────────────────────────────────────────────────
# Each entry: (internal_key, text_prompt_for_CLIP, spanish_label)
_CATEGORIES = [
    ("top",        "a t-shirt, blouse, polo shirt or casual top",               "Camiseta / Blusa"),
    ("shirt",      "a formal button-up dress shirt",                             "Camisa"),
    ("dress",      "a dress, gown or jumpsuit",                                  "Vestido / Mono"),
    ("pants",      "pants, jeans, trousers or chinos",                           "Pantalón / Jeans"),
    ("skirt",      "a skirt, mini skirt or maxi skirt",                          "Falda"),
    ("outerwear",  "a jacket, coat, blazer, hoodie or sweatshirt",               "Abrigo / Chaqueta"),
    ("shorts",     "shorts or bermuda shorts",                                   "Shorts"),
    ("footwear",   "shoes, boots, sneakers, heels or sandals",                   "Calzado"),
    ("accessory",  "a bag, handbag, hat, belt, scarf, sunglasses or jewelry",    "Accesorio"),
    ("sportswear", "sportswear, activewear, gym clothes or athletic outfit",      "Ropa deportiva"),
    ("swimwear",   "swimwear, bikini, swimsuit or bathing suit",                  "Ropa de baño"),
]

# ── Style definitions ──────────────────────────────────────────────────────────
_STYLES = [
    ("casual",     "casual everyday clothing, relaxed and comfortable",          "Casual"),
    ("formal",     "formal business professional or office clothing",             "Formal"),
    ("elegant",    "elegant evening or cocktail clothing, sophisticated",         "Elegante"),
    ("sporty",     "sporty athletic or activewear clothing",                      "Deportivo"),
    ("streetwear", "streetwear urban trendy hip-hop influenced clothing",         "Streetwear"),
    ("bohemian",   "bohemian vintage boho floral or free-spirited clothing",      "Bohemio"),
    ("minimalist", "minimalist simple clean neutral colored clothing",            "Minimalista"),
]

# Pre-compute text embeddings once (filled on first request)
_category_embeddings: list[list[float]] | None = None
_style_embeddings:    list[list[float]] | None = None


def _get_category_embeddings() -> list[list[float]]:
    global _category_embeddings
    if _category_embeddings is None:
        _category_embeddings = [clip_service.embed_text(p) for _, p, _ in _CATEGORIES]
    return _category_embeddings


def _get_style_embeddings() -> list[list[float]]:
    global _style_embeddings
    if _style_embeddings is None:
        _style_embeddings = [clip_service.embed_text(p) for _, p, _ in _STYLES]
    return _style_embeddings


@router.post("/analyze")
async def analyze_garment(file: UploadFile = File(...)):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="El archivo debe ser una imagen (jpg/png/webp).")

    image_bytes = await file.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="La imagen no puede superar 10 MB.")

    # 1. CLIP image embedding
    try:
        image_emb = clip_service.embed_image(image_bytes)
    except Exception as e:
        logger.error(f"CLIP embedding failed: {e}")
        raise HTTPException(status_code=500, detail="Error al procesar la imagen con CLIP.")

    # 2. Zero-shot category classification
    cat_embs   = _get_category_embeddings()
    cat_scores = [clip_service.cosine_similarity(image_emb, ce) for ce in cat_embs]
    best_cat_i = cat_scores.index(max(cat_scores))
    cat_key, _, cat_label = _CATEGORIES[best_cat_i]

    # 3. Zero-shot style classification
    sty_embs   = _get_style_embeddings()
    sty_scores = [clip_service.cosine_similarity(image_emb, se) for se in sty_embs]
    best_sty_i = sty_scores.index(max(sty_scores))
    sty_key, _, sty_label = _STYLES[best_sty_i]

    # 4. Dominant color
    try:
        dominant_color = color_service.get_dominant_color(image_bytes)
    except Exception as e:
        logger.warning(f"Color detection failed: {e}")
        dominant_color = None

    return {
        "category":       cat_key,
        "category_label": cat_label,
        "style":          sty_key,
        "style_label":    sty_label,
        "dominant_color": dominant_color,
        "embedding":      image_emb,
        "confidence": {
            "category": round(max(cat_scores), 4),
            "style":    round(max(sty_scores), 4),
        },
    }
