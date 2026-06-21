"""
Trains the outfit compatibility classifier.

Run from python-service/ directory:
    python -m training.train

Output:
    models/compatibility_model.joblib   — trained GradientBoostingClassifier
    models/compatibility_metrics.json   — evaluation metrics on test set (80/20 split)
"""

import sys
import os
import json
import time
import numpy as np

# Ensure we can import from python-service/
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sklearn.ensemble import GradientBoostingClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score, classification_report,
    confusion_matrix, roc_auc_score, f1_score,
)
import joblib

from training.dataset_generator import build_dataset
from training.feature_extractor import extract_features

MODELS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "models")


def main():
    print("=" * 60)
    print("  Outfit Compatibility Classifier - Training")
    print("=" * 60)

    # ── 1. Generate dataset ───────────────────────────────────────────
    print("\n[1/5] Generando dataset sintético...")
    t0 = time.time()
    dataset = build_dataset(n_compatible=1200, n_incompatible=1200)
    print(f"      {len(dataset)} ejemplos generados en {time.time()-t0:.1f}s")

    # ── 2. Extract features ───────────────────────────────────────────
    print("\n[2/5] Extrayendo features (incluye embeddings CLIP)...")
    print("      Inicializando modelo CLIP - puede tardar la primera vez...")
    try:
        from app.services.clip_service import preload_model
        preload_model()
        use_clip = True
        print("      CLIP cargado correctamente.")
    except Exception as e:
        print(f"      CLIP no disponible ({e}). Feature f4 = 0.5 (neutral).")
        use_clip = False

    t0 = time.time()
    X_list, y_list = [], []
    for i, (garments, label) in enumerate(dataset):
        if i % 200 == 0:
            print(f"      Procesando ejemplo {i}/{len(dataset)}...", end="\r")
        feats = extract_features(garments, use_clip=use_clip)
        X_list.append(feats)
        y_list.append(label)

    X = np.array(X_list)
    y = np.array(y_list)
    print(f"\n      Features extraídas en {time.time()-t0:.1f}s")
    print(f"      X shape: {X.shape}  |  Positivos: {y.sum()}  |  Negativos: {(1-y).sum()}")

    # ── 3. Train / test split (80/20 estratificado) ───────────────────
    print("\n[3/5] Dividiendo dataset (80% train / 20% test)...")
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, stratify=y, random_state=42
    )
    print(f"      Train: {len(X_train)} ejemplos  |  Test: {len(X_test)} ejemplos")

    # ── 4. Train model ────────────────────────────────────────────────
    print("\n[4/5] Entrenando GradientBoostingClassifier (n=150)...")
    t0 = time.time()
    model = GradientBoostingClassifier(
        n_estimators=150,
        learning_rate=0.05,
        max_depth=3,
        subsample=0.8,
        random_state=42,
    )
    model.fit(X_train, y_train)
    print(f"      Entrenado en {time.time()-t0:.1f}s")

    # Feature importance
    feature_names = [
        "style_consistency", "color_harmony",
        "formality_variance_inv", "clip_text_similarity", "category_balance",
    ]
    print("\n      Importancia de features:")
    for name, imp in zip(feature_names, model.feature_importances_):
        bar = "#" * int(imp * 40)
        print(f"      {name:<28} {imp:.4f}  {bar}")

    # ── 5. Evaluate on test set ───────────────────────────────────────
    print("\n[5/5] Evaluando en el test set (20%)...")
    y_pred  = model.predict(X_test)
    y_proba = model.predict_proba(X_test)[:, 1]

    accuracy  = float(accuracy_score(y_test, y_pred))
    f1        = float(f1_score(y_test, y_pred))
    auc       = float(roc_auc_score(y_test, y_proba))
    cm        = confusion_matrix(y_test, y_pred).tolist()
    report    = classification_report(y_test, y_pred,
                                       target_names=["incompatible", "compatible"])

    print(f"\n  Accuracy : {accuracy:.4f}  ({accuracy*100:.2f}%)")
    print(f"  F1-Score : {f1:.4f}")
    print(f"  AUC-ROC  : {auc:.4f}")
    print("\n  Reporte por clase:")
    print(report)
    print(f"  Matriz de confusión:\n  {cm}")

    # ── Save model & metrics ──────────────────────────────────────────
    os.makedirs(MODELS_DIR, exist_ok=True)
    model_path   = os.path.join(MODELS_DIR, "compatibility_model.joblib")
    metrics_path = os.path.join(MODELS_DIR, "compatibility_metrics.json")

    joblib.dump(model, model_path)
    metrics = {
        "accuracy":  accuracy,
        "f1_score":  f1,
        "auc_roc":   auc,
        "confusion_matrix": cm,
        "n_train":   int(len(X_train)),
        "n_test":    int(len(X_test)),
        "features":  feature_names,
        "clip_used": use_clip,
        "model":     "GradientBoostingClassifier(n=150, lr=0.05, depth=3)",
        "split":     "80/20 stratified",
    }
    with open(metrics_path, "w", encoding="utf-8") as f:
        json.dump(metrics, f, indent=2, ensure_ascii=False)

    print(f"\n[OK] Modelo guardado en:  {model_path}")
    print(f"[OK] Metricas guardadas en: {metrics_path}")
    print("=" * 60)


if __name__ == "__main__":
    main()
