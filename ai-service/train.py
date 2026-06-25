import os
import sys
import subprocess
import urllib.request
import logging
import numpy as np
import pandas as pd
from PIL import Image

# Configurar logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Rutas de archivos
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_RAW_DIR = os.path.join(BASE_DIR, "dataset_raw")
MODELS_DIR = os.path.join(BASE_DIR, "models")
CSV_PATH = os.path.join(MODELS_DIR, "face_shape_dataset.csv")
MODEL_PATH = os.path.join(MODELS_DIR, "face_shape_classifier.joblib")
LANDMARKER_PATH = os.path.join(MODELS_DIR, "face_landmarker.task")

LANDMARKER_URL = (
    "https://storage.googleapis.com/mediapipe-models/"
    "face_landmarker/face_landmarker/float16/latest/face_landmarker.task"
)

# Constantes de MediaPipe
_LM_FOREHEAD_TOP  = 10
_LM_CHIN_BOTTOM   = 152
_LM_CHEEK_LEFT    = 234
_LM_CHEEK_RIGHT   = 454
_LM_TEMPLE_LEFT   = 162
_LM_TEMPLE_RIGHT  = 389
_LM_JAW_LEFT      = 172
_LM_JAW_RIGHT     = 397


def ensure_environment():
    """Asegura que existan las carpetas y los recursos descargados."""
    os.makedirs(MODELS_DIR, exist_ok=True)
    
    # 1. Descargar MediaPipe face landmarker si no existe
    if not os.path.exists(LANDMARKER_PATH):
        logger.info("Descargando modelo de MediaPipe face_landmarker.task (~1.3 MB)...")
        urllib.request.urlretrieve(LANDMARKER_URL, LANDMARKER_PATH)
        logger.info("Modelo de MediaPipe descargado correctamente.")

    # 2. Clonar dataset de rostros si no existe
    if not os.path.exists(DATASET_RAW_DIR):
        logger.info("Clonando dataset de rostros (dsmlr/faceshape) desde GitHub...")
        try:
            subprocess.run(
                ["git", "clone", "https://github.com/dsmlr/faceshape.git", DATASET_RAW_DIR],
                check=True
            )
            logger.info("Dataset clonado correctamente.")
        except Exception as e:
            logger.error(f"Error al clonar el dataset: {e}")
            logger.error("Por favor, asegúrate de tener Git instalado y accesible en la terminal.")
            sys.exit(1)


def extract_features():
    """Procesa el dataset real dsmlr/faceshape con MediaPipe para generar el CSV."""
    import mediapipe as mp
    from mediapipe.tasks import python as mp_python
    from mediapipe.tasks.python import vision as mp_vision

    if os.path.exists(CSV_PATH):
        logger.info(f"El dataset preprocesado ya existe en {CSV_PATH}. Saltando extracción.")
        return pd.read_csv(CSV_PATH)

    logger.info("Iniciando la extracción de características reales del dataset de GitHub...")
    options = mp_vision.FaceLandmarkerOptions(
        base_options=mp_python.BaseOptions(model_asset_path=LANDMARKER_PATH),
        num_faces=1,
        min_face_detection_confidence=0.4,
    )

    categories = ["heart", "oblong", "oval", "round", "square"]
    data_rows = []

    with mp_vision.FaceLandmarker.create_from_options(options) as landmarker:
        for category in categories:
            cat_dir = os.path.join(DATASET_RAW_DIR, "published_dataset", category)
            if not os.path.exists(cat_dir):
                logger.warning(f"La carpeta {cat_dir} no existe.")
                continue

            files = [f for f in os.listdir(cat_dir) if f.lower().endswith((".jpg", ".jpeg", ".png"))]
            logger.info(f"Procesando {len(files)} imágenes reales para: {category}...")

            for filename in files:
                img_path = os.path.join(cat_dir, filename)
                try:
                    image = Image.open(img_path).convert("RGB")
                    img_array = np.array(image, dtype=np.uint8)
                    h, w = img_array.shape[:2]

                    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=img_array)
                    result = landmarker.detect(mp_image)

                    if not result.face_landmarks:
                        continue

                    lms = result.face_landmarks[0]

                    def lm(idx):
                        p = lms[idx]
                        return np.array([p.x * w, p.y * h])

                    def _dist(a, b):
                        return float(np.linalg.norm(a - b))

                    forehead_w = _dist(lm(_LM_TEMPLE_LEFT), lm(_LM_TEMPLE_RIGHT))
                    cheek_w    = _dist(lm(_LM_CHEEK_LEFT),  lm(_LM_CHEEK_RIGHT))
                    jaw_w      = _dist(lm(_LM_JAW_LEFT),     lm(_LM_JAW_RIGHT))
                    face_h     = _dist(lm(_LM_FOREHEAD_TOP), lm(_LM_CHIN_BOTTOM))

                    if cheek_w == 0:
                        continue

                    data_rows.append({
                        "label": category,
                        "height_ratio": face_h / cheek_w,
                        "jaw_ratio": jaw_w / cheek_w,
                        "forehead_ratio": forehead_w / cheek_w
                    })

                except Exception as e:
                    logger.debug(f"Error procesando {img_path}: {e}")

    df = pd.DataFrame(data_rows)
    df.to_csv(CSV_PATH, index=False)
    logger.info(f"Dataset real preprocesado y guardado en {CSV_PATH}. Muestras válidas: {len(df)}")
    return df


def train_and_evaluate(df):
    """Entrena sobre el dataset real y evalúa usando split 80/20."""
    from sklearn.model_selection import train_test_split
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.metrics import classification_report, accuracy_score, confusion_matrix
    import joblib

    logger.info("Iniciando el entrenamiento del modelo de Machine Learning con datos reales...")

    # Características y etiquetas
    X = df[["height_ratio", "jaw_ratio", "forehead_ratio"]]
    y = df["label"]

    # Separación 80% entrenamiento / 20% prueba
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )

    # Entrenar clasificador RandomForest regularizado para evitar overfitting
    clf = RandomForestClassifier(n_estimators=100, max_depth=5, min_samples_split=4, random_state=42)
    clf.fit(X_train, y_train)

    # Predicciones
    y_pred_train = clf.predict(X_train)
    y_pred_test = clf.predict(X_test)

    # Métricas
    train_acc = accuracy_score(y_train, y_pred_train)
    test_acc = accuracy_score(y_test, y_pred_test)

    print("\n" + "="*50)
    print("           REPORTE DE ENTRENAMIENTO (M.L.)")
    print("="*50)
    print(f"Total de muestras válidas:        {len(df)}")
    print(f"Muestras de entrenamiento (80%): {len(X_train)}")
    print(f"Muestras de prueba (20%):        {len(X_test)}")
    print(f"Precisión en Entrenamiento (Train Acc): {train_acc * 100:.2f}%")
    print(f"Precisión en Prueba (Test Acc):        {test_acc * 100:.2f}%")
    print("\nReporte detallado en conjunto de prueba:")
    print(classification_report(y_test, y_pred_test))
    
    print("Matriz de Confusión en conjunto de prueba:")
    labels = sorted(df["label"].unique())
    cm = confusion_matrix(y_test, y_pred_test, labels=labels)
    cm_df = pd.DataFrame(cm, index=[f"Real {l}" for l in labels], columns=[f"Pred {l}" for l in labels])
    print(cm_df.to_string())
    print("="*50 + "\n")

    # Guardar modelo
    joblib.dump(clf, MODEL_PATH)
    logger.info(f"Modelo guardado exitosamente en: {MODEL_PATH}")


if __name__ == "__main__":
    logger.info("--- INICIANDO PIPELINE DE ENTRENAMIENTO ---")
    ensure_environment()
    df_features = extract_features()
    if len(df_features) == 0:
        logger.error("No se pudieron extraer características de ninguna imagen. Abortando.")
        sys.exit(1)
    train_and_evaluate(df_features)
    logger.info("--- PIPELINE FINALIZADO CON ÉXITO ---")
