"""
POST /hairstyle/embed   — CLIP embedding for a catalog hairstyle image.
POST /hairstyle/recommend — Face-shape + gender aware ranking of catalog hairstyles.
"""

import json
import logging
from typing import Optional

import httpx
from fastapi import APIRouter, File, Form, UploadFile, HTTPException

from app.services import clip_service, face_shape as face_svc
from app.config import IMAGE_FETCH_TIMEOUT

logger = logging.getLogger(__name__)
router = APIRouter()

# Hairstyles of the wrong gender get their score multiplied by this factor.
_GENDER_MISMATCH_PENALTY = 0.25


# ─── helpers ──────────────────────────────────────────────────────────────────

def _parse_embedding(raw) -> Optional[list[float]]:
    """Decode a stored embedding (JSON string or list) into a float list."""
    if raw is None:
        return None
    try:
        return json.loads(raw) if isinstance(raw, str) else list(raw)
    except (json.JSONDecodeError, TypeError):
        return None


async def _fetch_embedding(client: httpx.AsyncClient, hid: str, url: str,
                           warnings: list[str]) -> Optional[list[float]]:
    """Download a hairstyle image and compute its CLIP embedding on-the-fly."""
    try:
        resp = await client.get(url)
        if resp.status_code == 200:
            return clip_service.embed_image(resp.content)
        warnings.append(f"Peinado {hid}: HTTP {resp.status_code} al descargar imagen.")
    except Exception:
        logger.exception("Error descargando imagen del peinado %s", hid)
        warnings.append(f"Peinado {hid}: error de red al descargar imagen.")
    return None


def _gender_matches(hairstyle_gender: Optional[str], user_gender: Optional[str]) -> bool:
    """True when the hairstyle is compatible with the user's gender."""
    if not user_gender or not hairstyle_gender or hairstyle_gender == "UNISEX":
        return True
    return hairstyle_gender == user_gender


def _apply_gender_penalty(score: float, hairstyle_gender: Optional[str],
                          user_gender: Optional[str]) -> float:
    """Multiply score by penalty when genders don't match."""
    if _gender_matches(hairstyle_gender, user_gender):
        return score
    return score * _GENDER_MISMATCH_PENALTY


async def _score_item(h: dict, query_emb: list[float], gender: Optional[str],
                      client: httpx.AsyncClient, warnings: list[str]) -> Optional[dict]:
    """Score a single catalog hairstyle against the query embedding."""
    hid = h.get("id")
    if not hid:
        return None
    emb = _parse_embedding(h.get("embedding"))
    if emb is None and h.get("imageUrl"):
        emb = await _fetch_embedding(client, hid, h["imageUrl"], warnings)
    if emb is None:
        warnings.append(f"Peinado {hid} omitido: sin embedding ni URL.")
        return None
    raw   = clip_service.cosine_similarity(query_emb, emb)
    final = _apply_gender_penalty(raw, h.get("gender"), gender)
    return {"id": hid, "score": round(final, 6), "raw_score": round(raw, 6)}


async def _score_catalog(catalog: list[dict], query_emb: list[float],
                         gender: Optional[str], warnings: list[str]) -> list[dict]:
    """Score all catalog hairstyles and return only the ones with valid scores."""
    results: list[dict] = []
    async with httpx.AsyncClient(timeout=IMAGE_FETCH_TIMEOUT) as client:
        for h in catalog:
            item = await _score_item(h, query_emb, gender, client, warnings)
            if item:
                results.append(item)
    return results


# ─── /hairstyle/embed ─────────────────────────────────────────────────────────

@router.post("/embed")
async def embed_hairstyle(file: UploadFile = File(...)):
    """Return the CLIP embedding for a hairstyle catalog image."""
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="El archivo debe ser una imagen.")

    image_bytes = await file.read()
    try:
        embedding = clip_service.embed_image(image_bytes)
    except Exception:
        logger.exception("CLIP embed_image failed.")
        raise HTTPException(status_code=500, detail="Error al calcular el embedding.")

    return {"embedding": embedding}


# ─── /hairstyle/recommend ─────────────────────────────────────────────────────

@router.post("/recommend")
async def recommend_hairstyles(
    file:        UploadFile = File(...),
    hairstyles:  str        = Form(...),    # JSON: [{id, embedding?, imageUrl?, gender?}]
    user_gender: str        = Form(""),     # "MALE" | "FEMALE" | "" (unknown)
):
    """
    Rank catalog hairstyles for a face photo using face shape + gender.

    Gender logic (two layers):
      1. The CLIP text query is gender-specific ("men's fade haircut…" vs "women's bob…").
      2. Hairstyles of the wrong gender receive a 75% score penalty so they
         fall to the bottom even if visually similar.
    """
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="El archivo debe ser una imagen.")

    image_bytes = await file.read()
    gender = user_gender.strip().upper() if user_gender else None

    # 1. Parse catalog
    try:
        catalog: list[dict] = json.loads(hairstyles)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="'hairstyles' debe ser un JSON válido.")
    if not catalog:
        raise HTTPException(status_code=400, detail="El catálogo de peinados está vacío.")

    # 2. Detect face shape
    face_result   = face_svc.analyze_face(image_bytes)
    face_shape    = face_result.get("face_shape") or "ovalado"
    face_detected = bool(face_result.get("detected"))

    # 3. Gender-aware CLIP text query
    ideal_query = face_svc.get_ideal_query(face_shape, gender)
    logger.info("Face shape: %s | Gender: %s | Query: %s", face_shape, gender, ideal_query)

    # 4. Encode query with CLIP
    try:
        query_emb = clip_service.embed_text(ideal_query)
    except Exception:
        logger.exception("CLIP embed_text failed.")
        raise HTTPException(status_code=500, detail="Error al procesar el modelo CLIP.")

    # 5. Score each hairstyle
    warnings: list[str] = []
    scored = await _score_catalog(catalog, query_emb, gender, warnings)

    if not scored:
        raise HTTPException(status_code=422,
                            detail="No se pudo calcular similitud para ningún peinado.")

    scored.sort(key=lambda x: x["score"], reverse=True)
    for i, item in enumerate(scored):
        item["rank"] = i + 1

    return {
        "detected":        face_detected,
        "face_shape":      face_shape,
        "face_shape_note": face_svc.FACE_SHAPE_NOTES.get(face_shape),
        "ideal_query":     ideal_query,
        "user_gender":     gender,
        "ranked":          scored,
        "warnings":        warnings,
    }
