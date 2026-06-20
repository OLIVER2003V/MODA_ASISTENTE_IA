"""
Dominant color detection for garment images.

Strategy:
  1. Center-crop the image (ignore background edges).
  2. Use ColorThief to find the dominant color cluster.
  3. Match the resulting RGB value to the nearest color in a fashion palette.
"""

import io
import math
import logging
from PIL import Image

logger = logging.getLogger(__name__)

# ── Fashion color palette (RGB) ───────────────────────────────────────────────
_PALETTE: dict[str, tuple[int, int, int]] = {
    "negro":          (15,  15,  15),
    "blanco":         (245, 245, 245),
    "gris":           (128, 128, 128),
    "gris claro":     (200, 200, 200),
    "gris oscuro":    (60,  60,  60),
    "rojo":           (220, 30,  30),
    "rojo oscuro":    (139, 0,   0),
    "coral":          (255, 100, 80),
    "naranja":        (255, 140, 0),
    "amarillo":       (255, 215, 0),
    "mostaza":        (210, 170, 20),
    "verde":          (34,  139, 34),
    "verde oscuro":   (0,   90,  0),
    "verde menta":    (120, 200, 140),
    "oliva":          (107, 142, 35),
    "turquesa":       (64,  224, 208),
    "celeste":        (135, 206, 235),
    "azul":           (30,  100, 220),
    "azul marino":    (0,   0,   128),
    "morado":         (128, 0,   128),
    "violeta":        (148, 0,   211),
    "lavanda":        (180, 140, 230),
    "rosa":           (255, 100, 160),
    "rosa claro":     (255, 180, 200),
    "lila":           (200, 160, 200),
    "vino":           (114, 47,  55),
    "terracota":      (200, 80,  70),
    "beige":          (245, 225, 195),
    "crema":          (255, 250, 210),
    "marrón":         (130, 82,  45),
    "marrón claro":   (196, 160, 120),
    "camel":          (193, 154, 107),
    "khaki":          (180, 175, 100),
    "dorado":         (218, 165, 32),
    "plateado":       (180, 180, 195),
}


def _color_distance(r1: int, g1: int, b1: int, r2: int, g2: int, b2: int) -> float:
    return math.sqrt((r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2)


def nearest_color_name(r: int, g: int, b: int) -> str:
    best_name = "gris"
    best_dist = float("inf")
    for name, (pr, pg, pb) in _PALETTE.items():
        d = _color_distance(r, g, b, pr, pg, pb)
        if d < best_dist:
            best_dist = d
            best_name = name
    return best_name


def get_dominant_color(image_bytes: bytes) -> str:
    """
    Extract the dominant color name from an image.
    Crops the center 60% to avoid capturing background.
    """
    try:
        from colorthief import ColorThief
    except ImportError:
        logger.warning("colorthief not installed. Falling back to average color.")
        return _average_color_fallback(image_bytes)

    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    iw, ih = image.size

    # Center crop: 20% margin on sides, 15% margin top/bottom
    left   = int(iw * 0.20)
    top    = int(ih * 0.15)
    right  = int(iw * 0.80)
    bottom = int(ih * 0.85)
    cropped = image.crop((left, top, right, bottom))

    buf = io.BytesIO()
    cropped.save(buf, format="JPEG", quality=85)
    buf.seek(0)

    try:
        ct = ColorThief(buf)
        r, g, b = ct.get_color(quality=1)
        return nearest_color_name(r, g, b)
    except Exception as e:
        logger.warning(f"ColorThief failed: {e}. Using average color.")
        return _average_color_fallback(image_bytes)


def _average_color_fallback(image_bytes: bytes) -> str:
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB").resize((50, 50))
    pixels = list(image.getdata())
    r = sum(p[0] for p in pixels) // len(pixels)
    g = sum(p[1] for p in pixels) // len(pixels)
    b = sum(p[2] for p in pixels) // len(pixels)
    return nearest_color_name(r, g, b)
