import os
from dotenv import load_dotenv

load_dotenv()

PORT              = int(os.getenv("PORT", 8000))
CLIP_MODEL        = os.getenv("CLIP_MODEL", "clip-ViT-B-32")
IMAGE_FETCH_TIMEOUT = int(os.getenv("IMAGE_FETCH_TIMEOUT", 15))
