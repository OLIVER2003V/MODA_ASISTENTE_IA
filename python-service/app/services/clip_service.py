"""
CLIP embedding service using sentence-transformers.

The model is loaded lazily on first use (or eagerly at startup via preload_model()).
It runs on CPU — no GPU required.

On first run it downloads ~350 MB from HuggingFace to ~/.cache/huggingface/.
Subsequent runs use the local cache.
"""

import io
import threading
import logging
from typing import Optional

import numpy as np
from PIL import Image

from app.config import CLIP_MODEL

logger = logging.getLogger(__name__)

_model = None
_lock  = threading.Lock()


def preload_model() -> None:
    """Called at startup to load the model before the first request."""
    get_model()


def is_model_loaded() -> bool:
    return _model is not None


def get_model():
    global _model
    if _model is None:
        with _lock:
            if _model is None:
                logger.info(f"Loading CLIP model '{CLIP_MODEL}' — this may take a moment on first run...")
                from sentence_transformers import SentenceTransformer
                _model = SentenceTransformer(CLIP_MODEL)
                logger.info("CLIP model loaded successfully.")
    return _model


def embed_image(image_bytes: bytes) -> list[float]:
    """Return a normalized CLIP embedding for the given image bytes."""
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    model = get_model()
    embedding: np.ndarray = model.encode(image, normalize_embeddings=True)
    return embedding.tolist()


def embed_text(text: str) -> list[float]:
    """Return a normalized CLIP embedding for the given text string."""
    model = get_model()
    embedding: np.ndarray = model.encode(text, normalize_embeddings=True)
    return embedding.tolist()


def cosine_similarity(a: list[float], b: list[float]) -> float:
    """Cosine similarity between two already-normalized vectors (just a dot product)."""
    va = np.array(a, dtype=np.float32)
    vb = np.array(b, dtype=np.float32)
    norm_a = np.linalg.norm(va)
    norm_b = np.linalg.norm(vb)
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return float(np.dot(va, vb) / (norm_a * norm_b))
