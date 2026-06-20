"""
Face shape detection using MediaPipe Face Landmarker (Tasks API).

Compatible with mediapipe >= 0.10.14 which removed the legacy mp.solutions API.

On first use, downloads the face_landmarker.task model (~1.3 MB) from Google's
MediaPipe CDN and caches it in python-service/models/.
"""

import io
import os
import logging
import threading
import urllib.request
from typing import Optional, TypedDict

import numpy as np
from PIL import Image

logger = logging.getLogger(__name__)

# ── Model download ─────────────────────────────────────────────────────────────
_MODEL_DIR  = os.path.join(os.path.dirname(__file__), '..', '..', 'models')
_MODEL_PATH = os.path.join(_MODEL_DIR, 'face_landmarker.task')
_MODEL_URL  = (
    "https://storage.googleapis.com/mediapipe-models/"
    "face_landmarker/face_landmarker/float16/latest/face_landmarker.task"
)
_download_lock = threading.Lock()


def _ensure_model() -> None:
    if os.path.exists(_MODEL_PATH):
        return
    with _download_lock:
        if os.path.exists(_MODEL_PATH):
            return
        os.makedirs(_MODEL_DIR, exist_ok=True)
        logger.info("Downloading face_landmarker.task (~1.3 MB)…")
        urllib.request.urlretrieve(_MODEL_URL, _MODEL_PATH)
        logger.info("face_landmarker.task downloaded and cached.")


# ── Landmark indices (same in Tasks API as in legacy solutions API) ────────────
_LM_FOREHEAD_TOP  = 10
_LM_CHIN_BOTTOM   = 152
_LM_CHEEK_LEFT    = 234
_LM_CHEEK_RIGHT   = 454
_LM_TEMPLE_LEFT   = 162
_LM_TEMPLE_RIGHT  = 389
_LM_JAW_LEFT      = 172
_LM_JAW_RIGHT     = 397


# ── Face shape notes / queries ─────────────────────────────────────────────────
FACE_SHAPE_NOTES = {
    "ovalado":  "El rostro ovalado es versátil — la mayoría de peinados le quedan bien.",
    "redondo":  "Los peinados que añaden altura y alargan el rostro favorecen más.",
    "cuadrado": "Los peinados suaves con capas y ondas suavizan la mandíbula cuadrada.",
    "corazon":  "Los bobs a la altura del mentón y los flequillos laterales equilibran la frente.",
    "oblongo":  "El volumen en los laterales y los cortes medios equilibran el rostro alargado.",
}

FACE_SHAPE_QUERIES = {
    "ovalado":  "elegant versatile hairstyle flattering for any face shape, balanced proportions",
    "redondo":  "hairstyle with volume on top, height at crown, asymmetric cut that elongates a round face",
    "cuadrado": "soft layered waves hairstyle that softens a square jaw, romantic loose curls side swept bangs",
    "corazon":  "hairstyle with volume at chin level, chin length bob, side swept bangs for heart shaped face",
    "oblongo":  "hairstyle with volume at the sides, curtain bangs, medium length cut for long rectangular face",
}

# Gender-specific queries — CLIP biases toward the right image style
FACE_SHAPE_QUERIES_MALE = {
    "ovalado":  "men's haircut versatile short hairstyle for man any face shape",
    "redondo":  "men's haircut high fade volume on top that elongates round face for man",
    "cuadrado": "men's textured haircut soft layers that soften square jaw for man",
    "corazon":  "men's undercut or side part hairstyle for man with heart shaped face",
    "oblongo":  "men's haircut with volume at sides curtain bangs for man with oblong rectangular face",
}

FACE_SHAPE_QUERIES_FEMALE = {
    "ovalado":  "women's elegant hairstyle versatile for any face shape",
    "redondo":  "women's hairstyle volume on top height at crown that elongates round face",
    "cuadrado": "women's soft layered waves romantic curls that soften square jaw",
    "corazon":  "women's chin length bob side swept bangs for heart shaped face",
    "oblongo":  "women's hairstyle volume at sides curtain bangs medium length for oblong face",
}


def get_ideal_query(face_shape: str, gender: str | None = None) -> str:
    """Return the CLIP text query for a given face shape and optional gender."""
    shape = face_shape or "ovalado"
    if gender == "MALE":
        return FACE_SHAPE_QUERIES_MALE.get(shape, FACE_SHAPE_QUERIES_MALE["ovalado"])
    if gender == "FEMALE":
        return FACE_SHAPE_QUERIES_FEMALE.get(shape, FACE_SHAPE_QUERIES_FEMALE["ovalado"])
    return FACE_SHAPE_QUERIES.get(shape, FACE_SHAPE_QUERIES["ovalado"])


class FaceAnalysisResult(TypedDict):
    detected:        bool
    face_shape:      Optional[str]
    face_shape_note: Optional[str]
    measurements:    Optional[dict]
    ideal_query:     Optional[str]


def _dist(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.linalg.norm(a - b))


def _classify(forehead_w: float, cheek_w: float, jaw_w: float, face_h: float) -> str:
    height_ratio   = face_h    / cheek_w if cheek_w > 0 else 1.3
    jaw_ratio      = jaw_w     / cheek_w if cheek_w > 0 else 0.8
    forehead_ratio = forehead_w / cheek_w if cheek_w > 0 else 0.85

    if height_ratio > 1.55:
        return "oblongo"
    if jaw_ratio >= 0.82:
        return "cuadrado"
    if jaw_ratio < 0.70 and forehead_ratio >= 0.85:
        return "corazon"
    if height_ratio < 1.20 and jaw_ratio >= 0.68:
        return "redondo"
    return "ovalado"


def analyze_face(image_bytes: bytes) -> FaceAnalysisResult:
    _null: FaceAnalysisResult = {
        "detected": False, "face_shape": None,
        "face_shape_note": None, "measurements": None, "ideal_query": None,
    }

    try:
        import mediapipe as mp
        from mediapipe.tasks import python as mp_python
        from mediapipe.tasks.python import vision as mp_vision
    except ImportError:
        logger.error("mediapipe is not installed.")
        return _null

    try:
        _ensure_model()
    except Exception:
        logger.exception("Could not download face landmarker model.")
        return _null

    try:
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        img_array = np.array(image, dtype=np.uint8)
        h, w = img_array.shape[:2]

        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=img_array)

        options = mp_vision.FaceLandmarkerOptions(
            base_options=mp_python.BaseOptions(model_asset_path=_MODEL_PATH),
            num_faces=1,
            min_face_detection_confidence=0.45,
            min_face_presence_confidence=0.45,
            min_tracking_confidence=0.45,
            output_face_blendshapes=False,
            output_facial_transformation_matrixes=False,
        )

        with mp_vision.FaceLandmarker.create_from_options(options) as landmarker:
            result = landmarker.detect(mp_image)

        if not result.face_landmarks:
            logger.info("No face detected.")
            return _null

        lms = result.face_landmarks[0]

        def lm(idx: int) -> np.ndarray:
            p = lms[idx]
            return np.array([p.x * w, p.y * h])

        forehead_w = _dist(lm(_LM_TEMPLE_LEFT),  lm(_LM_TEMPLE_RIGHT))
        cheek_w    = _dist(lm(_LM_CHEEK_LEFT),   lm(_LM_CHEEK_RIGHT))
        jaw_w      = _dist(lm(_LM_JAW_LEFT),      lm(_LM_JAW_RIGHT))
        face_h     = _dist(lm(_LM_FOREHEAD_TOP),  lm(_LM_CHIN_BOTTOM))

        shape = _classify(forehead_w, cheek_w, jaw_w, face_h)

        return {
            "detected":        True,
            "face_shape":      shape,
            "face_shape_note": FACE_SHAPE_NOTES[shape],
            "ideal_query":     FACE_SHAPE_QUERIES[shape],
            "measurements": {
                "face_height":     round(face_h, 1),
                "cheekbone_width": round(cheek_w, 1),
                "jaw_width":       round(jaw_w, 1),
                "forehead_width":  round(forehead_w, 1),
                "height_ratio":    round(face_h / cheek_w, 3) if cheek_w else None,
                "jaw_ratio":       round(jaw_w  / cheek_w, 3) if cheek_w else None,
                "forehead_ratio":  round(forehead_w / cheek_w, 3) if cheek_w else None,
            },
        }

    except Exception:
        logger.exception("Face analysis failed.")
        return _null
