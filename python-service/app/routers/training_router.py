"""
POST /training/run — triggers model retraining and reloads it in-place.
"""

import io
import sys
import json
import os
import contextlib

from fastapi import APIRouter, HTTPException

router = APIRouter()

METRICS_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
    "models", "compatibility_metrics.json",
)


@contextlib.contextmanager
def _suppress_stdout():
    old = sys.stdout
    sys.stdout = io.StringIO()
    try:
        yield
    finally:
        sys.stdout = old


@router.post("/run")
def run_training():
    """Retrain the outfit compatibility classifier and reload it in-place."""
    try:
        with _suppress_stdout():
            from training.train import main as train_main
            train_main()
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Training failed: {exc}") from exc

    # Reload the model so the running service uses the new weights immediately
    try:
        from app.services.compatibility_service import load_model
        load_model()
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Model reload failed: {exc}") from exc

    # Return the saved metrics
    try:
        with open(METRICS_PATH, encoding="utf-8") as f:
            metrics = json.load(f)
    except FileNotFoundError:
        raise HTTPException(status_code=500, detail="Metrics file not found after training")

    return {
        "status": "completed",
        "metrics": metrics,
        "message": "Modelo reentrenado y recargado correctamente",
    }
