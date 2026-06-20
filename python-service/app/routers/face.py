"""
POST /face/analyze
  - Detects face shape using MediaPipe landmarks.
  - Also returns the CLIP embedding of the face image so callers can
    do their own similarity comparisons if needed.
"""

import logging
from fastapi import APIRouter, File, UploadFile, HTTPException

from app.services import face_shape as face_svc
from app.services import clip_service

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/analyze")
async def analyze_face(file: UploadFile = File(...)):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="El archivo debe ser una imagen (jpg/png/webp).")

    image_bytes = await file.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="La imagen no puede superar 10 MB.")

    # 1. Detect face shape
    face_result = face_svc.analyze_face(image_bytes)

    # 2. CLIP embedding of the raw face photo (callers may store/compare it)
    try:
        embedding = clip_service.embed_image(image_bytes)
    except Exception as e:
        logger.warning(f"CLIP embedding failed for face image: {e}")
        embedding = None

    return {
        **face_result,
        "embedding": embedding,
    }
