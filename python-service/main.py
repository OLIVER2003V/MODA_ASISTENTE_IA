from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import face, garment, hairstyle, outfit
from app.routers.training_router import router as training_router
from app.services.clip_service import preload_model
from app.services.compatibility_service import load_model as load_compat_model


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Preload CLIP model at startup so the first request isn't slow
    preload_model()
    # Load outfit compatibility classifier (silent no-op if not trained yet)
    load_compat_model()
    yield


app = FastAPI(
    title="AI Vision Microservice",
    version="1.0.0",
    description="Face shape detection, garment classification, hairstyle recommendation and outfit compatibility scoring using local ML models.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(face.router,      prefix="/face",      tags=["Face Analysis"])
app.include_router(garment.router,   prefix="/garment",   tags=["Garment Analysis"])
app.include_router(hairstyle.router, prefix="/hairstyle", tags=["Hairstyle"])
app.include_router(outfit.router,      prefix="/outfit",    tags=["Outfit Compatibility"])
app.include_router(training_router,    prefix="/training",  tags=["Training"])


@app.get("/health", tags=["Health"])
def health():
    from app.services.clip_service import is_model_loaded
    from app.services.compatibility_service import is_model_loaded as is_compat_loaded
    return {
        "status": "ok",
        "service": "AI Vision Microservice",
        "clip_model_loaded": is_model_loaded(),
        "compatibility_model_loaded": is_compat_loaded(),
    }
