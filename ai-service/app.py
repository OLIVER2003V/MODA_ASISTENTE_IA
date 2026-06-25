import os
import io
import logging
from typing import Optional
import numpy as np
from PIL import Image
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import joblib

# Configurar logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Rutas de archivos
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, "models")
MODEL_PATH = os.path.join(MODELS_DIR, "face_shape_classifier.joblib")
LANDMARKER_PATH = os.path.join(MODELS_DIR, "face_landmarker.task")

# Mapeos y Explicaciones (en español)
FACE_SHAPE_TRANSLATION = {
    "heart": "corazon",
    "oblong": "oblongo",
    "oval": "ovalado",
    "round": "redondo",
    "square": "cuadrado"
}

FACE_SHAPE_NOTES = {
    "ovalado":  "El rostro ovalado es versátil — la mayoría de peinados le quedan bien.",
    "redondo":  "Los peinados que añaden altura y alargan el rostro favorecen más.",
    "cuadrado": "Los peinados suaves con capas y ondas suavizan la mandíbula cuadrada.",
    "corazon":  "Los bobs a la altura del mentón y los flequillos laterales equilibran la frente.",
    "oblongo":  "El volumen en los laterales y los cortes medios equilibran el rostro alargado.",
}

# Constantes de MediaPipe
_LM_FOREHEAD_TOP  = 10
_LM_CHIN_BOTTOM   = 152
_LM_CHEEK_LEFT    = 234
_LM_CHEEK_RIGHT   = 454
_LM_TEMPLE_LEFT   = 162
_LM_TEMPLE_RIGHT  = 389
_LM_JAW_LEFT      = 172
_LM_JAW_RIGHT     = 397

app = FastAPI(
    title="Custom Face Shape ML Service",
    description="Servicio alternativo de Machine Learning para clasificar tipos de rostro entrenado con dsmlr/faceshape.",
    version="1.0.0"
)

# Permitir CORS para desarrollo local
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_clf():
    """Carga y retorna el clasificador de Random Forest guardado."""
    if not os.path.exists(MODEL_PATH):
        raise HTTPException(
            status_code=503,
            detail=f"El modelo entrenado no se encuentra en {MODEL_PATH}. "
                   "Por favor, ejecuta el script de entrenamiento 'python train.py' primero."
        )
    try:
        return joblib.load(MODEL_PATH)
    except Exception as e:
        logger.error(f"Error al cargar el modelo: {e}")
        raise HTTPException(status_code=500, detail="Error interno al cargar el modelo entrenado.")


@app.get("/")
def health():
    model_loaded = os.path.exists(MODEL_PATH)
    return {
        "status": "ok",
        "service": "Custom Face Shape ML Service",
        "model_trained": model_loaded,
        "api_documentation": "/docs"
    }


@app.post("/face/analyze-ml")
async def analyze_face_ml(file: UploadFile = File(...)):
    # 1. Validar que sea una imagen
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="El archivo debe ser una imagen (jpg/png/webp).")

    image_bytes = await file.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="La imagen no puede superar los 10 MB.")

    # 2. Cargar dependencias de MediaPipe dinámicamente
    try:
        import mediapipe as mp
        from mediapipe.tasks import python as mp_python
        from mediapipe.tasks.python import vision as mp_vision
    except ImportError:
        raise HTTPException(
            status_code=500,
            detail="Error de dependencias: 'mediapipe' no está instalado en este entorno virtual."
        )

    # 3. Validar modelo de MediaPipe
    if not os.path.exists(LANDMARKER_PATH):
        raise HTTPException(
            status_code=500,
            detail=f"Modelo de MediaPipe no encontrado en {LANDMARKER_PATH}. "
                   "Ejecuta 'python train.py' primero para descargarlo."
        )

    # 4. Extraer características geométricas con MediaPipe
    try:
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        img_array = np.array(image, dtype=np.uint8)
        h, w = img_array.shape[:2]

        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=img_array)

        options = mp_vision.FaceLandmarkerOptions(
            base_options=mp_python.BaseOptions(model_asset_path=LANDMARKER_PATH),
            num_faces=1,
            min_face_detection_confidence=0.4,
        )

        with mp_vision.FaceLandmarker.create_from_options(options) as landmarker:
            result = landmarker.detect(mp_image)

        if not result.face_landmarks:
            return {
                "detected": False,
                "face_shape": None,
                "face_shape_note": None,
                "measurements": None,
                "confidence_probabilities": None
            }

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
            raise HTTPException(status_code=400, detail="Error al calcular dimensiones faciales.")

        height_ratio   = face_h / cheek_w
        jaw_ratio      = jaw_w / cheek_w
        forehead_ratio = forehead_w / cheek_w

    except Exception as e:
        logger.exception("MediaPipe extraction failed")
        raise HTTPException(status_code=500, detail=f"Error en la extracción geométrica facial: {str(e)}")

    # 5. Cargar el Clasificador ML y predecir
    clf = get_clf()
    features = [[height_ratio, jaw_ratio, forehead_ratio]]

    try:
        # Predicción de clase
        raw_pred = clf.predict(features)[0]
        
        # Probabilidades por clase
        probabilities = clf.predict_proba(features)[0]
        classes = clf.classes_
        
        confidence_dict = {
            FACE_SHAPE_TRANSLATION.get(c, c): round(float(prob), 4)
            for c, prob in zip(classes, probabilities)
        }

        # Traducir predicción al español
        shape_es = FACE_SHAPE_TRANSLATION.get(raw_pred, raw_pred)
        note = FACE_SHAPE_NOTES.get(shape_es, "Forma de rostro detectada.")

        return {
            "detected": True,
            "face_shape": shape_es,
            "face_shape_note": note,
            "measurements": {
                "face_height":      round(face_h, 1),
                "cheekbone_width":  round(cheek_w, 1),
                "jaw_width":        round(jaw_w, 1),
                "forehead_width":   round(forehead_w, 1),
                "height_ratio":     round(height_ratio, 3),
                "jaw_ratio":        round(jaw_ratio, 3),
                "forehead_ratio":   round(forehead_ratio, 3),
            },
            "confidence_probabilities": confidence_dict
        }

    except Exception as e:
        logger.error(f"Error en predicción con el modelo ML: {e}")
        raise HTTPException(status_code=500, detail=f"Error al clasificar con el modelo entrenado: {str(e)}")
