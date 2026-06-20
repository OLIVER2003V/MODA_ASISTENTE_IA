from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import face, garment, hairstyle
from app.services.clip_service import preload_model


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Preload CLIP model at startup so the first request isn't slow
    preload_model()
    yield


app = FastAPI(
    title="AI Vision Microservice",
    version="1.0.0",
    description="Face shape detection, garment classification and hairstyle recommendation using local ML models.",
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


@app.get("/health", tags=["Health"])
def health():
    from app.services.clip_service import is_model_loaded
    return {
        "status": "ok",
        "service": "AI Vision Microservice",
        "clip_model_loaded": is_model_loaded(),
    }
