"""
Standalone evaluation script — re-evaluates the saved model on a fresh test set.

Run from python-service/ directory:
    python -m training.evaluate
"""

import sys
import os
import json
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import joblib
from sklearn.metrics import (
    accuracy_score, classification_report,
    confusion_matrix, roc_auc_score,
    precision_score, recall_score, f1_score,
)
from sklearn.model_selection import train_test_split

from training.dataset_generator import build_dataset
from training.feature_extractor import extract_features

MODELS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "models")


def main():
    model_path = os.path.join(MODELS_DIR, "compatibility_model.joblib")
    if not os.path.exists(model_path):
        print(f"ERROR: Modelo no encontrado en {model_path}")
        print("Ejecutá primero: python -m training.train")
        sys.exit(1)

    print("=" * 60)
    print("  Outfit Compatibility Classifier — Evaluación")
    print("=" * 60)

    model = joblib.load(model_path)
    print(f"\nModelo cargado: {model_path}")

    print("\nGenerando dataset de evaluación (400 ejemplos fresh)...")
    dataset = build_dataset(n_compatible=200, n_incompatible=200)

    try:
        from app.services.clip_service import preload_model
        preload_model()
        use_clip = True
    except Exception:
        use_clip = False
        print("CLIP no disponible — usando feature f4=0.5")

    X_list, y_list = [], []
    for garments, label in dataset:
        feats = extract_features(garments, use_clip=use_clip)
        X_list.append(feats)
        y_list.append(label)

    X = np.array(X_list)
    y = np.array(y_list)

    y_pred  = model.predict(X)
    y_proba = model.predict_proba(X)[:, 1]

    accuracy  = accuracy_score(y, y_pred)
    precision = precision_score(y, y_pred)
    recall    = recall_score(y, y_pred)
    f1        = f1_score(y, y_pred)
    auc       = roc_auc_score(y, y_proba)

    print("\n── Métricas en evaluación fresh ──────────────────────────")
    print(f"  Accuracy  : {accuracy:.4f}  ({accuracy*100:.2f}%)")
    print(f"  Precision : {precision:.4f}")
    print(f"  Recall    : {recall:.4f}")
    print(f"  F1-Score  : {f1:.4f}")
    print(f"  AUC-ROC   : {auc:.4f}")

    print("\n── Reporte por clase ──────────────────────────────────────")
    print(classification_report(y, y_pred, target_names=["incompatible", "compatible"]))

    cm = confusion_matrix(y, y_pred)
    print("── Matriz de confusión ────────────────────────────────────")
    print(f"                 Pred: 0   Pred: 1")
    print(f"  Real: 0 (incompat)   {cm[0][0]:4d}      {cm[0][1]:4d}")
    print(f"  Real: 1 (compat  )   {cm[1][0]:4d}      {cm[1][1]:4d}")

    # Sample predictions
    print("\n── Ejemplos del dataset ───────────────────────────────────")
    for i in range(min(5, len(dataset))):
        garments, true_label = dataset[i]
        pred_label = int(y_pred[i])
        score = float(y_proba[i])
        cats = [g.get("category", "?") for g in garments]
        styles = [g.get("style", "?") for g in garments]
        marker = "✔" if pred_label == true_label else "✗"
        print(f"  {marker}  [{', '.join(cats)}] estilo=[{', '.join(styles)}]")
        print(f"     real={true_label} pred={pred_label} score={score:.3f}")

    print("=" * 60)


if __name__ == "__main__":
    main()
