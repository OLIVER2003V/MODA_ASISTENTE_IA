"""
Generates synthetic outfit compatibility training data.
Uses programmatic labeling (weak supervision) based on fashion rules:
  - Compatible (label=1): same style family, harmonious colors, appropriate category mix
  - Incompatible (label=0): style clash, clashing colors, or invalid category combinations
"""

import random
from itertools import product
from typing import List, Dict, Tuple

random.seed(42)

# ── Color compatibility rules (from fashion-rules.json logic) ─────────────────
COLOR_COMPATIBILITY: Dict[str, Dict[str, List[str]]] = {
    "navy":       {"allows": ["white", "cream", "light_blue", "grey", "beige"], "avoids": ["brown", "orange"]},
    "black":      {"allows": ["white", "red", "grey", "beige", "cream", "silver"], "avoids": ["brown"]},
    "white":      {"allows": ["navy", "black", "beige", "grey", "blue", "red", "burgundy", "olive"], "avoids": []},
    "grey":       {"allows": ["black", "white", "navy", "burgundy", "blue"], "avoids": []},
    "beige":      {"allows": ["white", "navy", "brown", "olive", "burgundy", "cream"], "avoids": ["orange"]},
    "olive":      {"allows": ["beige", "brown", "white", "black", "khaki"], "avoids": []},
    "burgundy":   {"allows": ["white", "grey", "beige", "navy", "black"], "avoids": ["orange", "red"]},
    "brown":      {"allows": ["beige", "white", "olive", "cream", "khaki"], "avoids": ["black", "navy"]},
    "blue":       {"allows": ["white", "grey", "beige", "navy"], "avoids": ["orange"]},
    "red":        {"allows": ["white", "black", "grey"], "avoids": ["orange", "pink"]},
    "orange":     {"allows": ["white", "black"], "avoids": ["red", "pink", "navy", "blue"]},
    "green":      {"allows": ["white", "beige", "brown", "khaki"], "avoids": ["red"]},
    "light_blue": {"allows": ["white", "navy", "grey", "beige"], "avoids": []},
    "cream":      {"allows": ["navy", "black", "beige", "brown", "burgundy"], "avoids": []},
    "khaki":      {"allows": ["white", "navy", "olive", "brown", "beige"], "avoids": []},
    "silver":     {"allows": ["black", "white", "grey", "navy"], "avoids": []},
    "pink":       {"allows": ["white", "grey", "navy", "beige"], "avoids": ["orange", "red"]},
    "neutral":    {"allows": [], "avoids": []},
}

# ── Garment templates ─────────────────────────────────────────────────────────
# Each garment: description (str), color (str), style (str), formality (0-5 int)
GARMENT_TEMPLATES: Dict[str, List[Dict]] = {
    "TOP": [
        # Formal
        {"desc": "A crisp white cotton button-down dress shirt with a pointed collar and slim fit, French cuffs with silver cufflinks", "color": "white", "style": "formal", "formality": 4},
        {"desc": "A light blue Oxford button-down shirt with fine woven texture, spread collar and a regular straight fit", "color": "light_blue", "style": "formal", "formality": 4},
        {"desc": "A navy blue striped dress shirt with a spread collar, French cuffs and a slim tailored fit", "color": "navy", "style": "formal", "formality": 5},
        {"desc": "A pale pink cotton dress shirt with mother-of-pearl buttons, barrel cuffs and a regular fit", "color": "pink", "style": "formal", "formality": 4},
        # Elegant
        {"desc": "A silk ivory blouse with a draped cowl neckline, long sleeves and a flowy relaxed silhouette", "color": "cream", "style": "elegant", "formality": 4},
        {"desc": "A burgundy velvet wrap top with long sleeves, deep V-neckline and a front tie closure", "color": "burgundy", "style": "elegant", "formality": 4},
        {"desc": "A black satin camisole top with spaghetti straps, a lace trim neckline and a slip-style cut", "color": "black", "style": "elegant", "formality": 4},
        # Casual
        {"desc": "A plain white cotton crew-neck t-shirt with short sleeves and a classic relaxed fit", "color": "white", "style": "casual", "formality": 1},
        {"desc": "A black graphic print jersey t-shirt with a round neckline and an oversized boxy fit", "color": "black", "style": "casual", "formality": 1},
        {"desc": "A grey marl pullover hoodie with a front kangaroo pocket, drawstring hood and ribbed cuffs", "color": "grey", "style": "casual", "formality": 1},
        {"desc": "A navy blue long-sleeve Henley shirt with a three-button placket and a slim regular fit", "color": "navy", "style": "casual", "formality": 2},
        {"desc": "A beige linen short-sleeve shirt with a camp collar, chest pockets and a loose relaxed fit", "color": "beige", "style": "casual", "formality": 2},
        {"desc": "A rust orange casual flannel shirt with a chest pocket, button front and a regular fit", "color": "orange", "style": "casual", "formality": 1},
        # Sport
        {"desc": "A black moisture-wicking athletic tank top with mesh side panels and a racerback design for running", "color": "black", "style": "sport", "formality": 0},
        {"desc": "A fluorescent orange compression running shirt with flatlock seams, reflective strips and short sleeves", "color": "orange", "style": "sport", "formality": 0},
        {"desc": "A grey polyester quarter-zip pullover with thumb holes, side pockets and a performance fit for training", "color": "grey", "style": "sport", "formality": 1},
    ],
    "BOTTOM": [
        # Formal
        {"desc": "Navy blue tailored dress trousers in a wool blend with a pressed centre crease, flat front and belt loops", "color": "navy", "style": "formal", "formality": 4},
        {"desc": "Charcoal grey straight-leg suit trousers in a fine wool blend with a flat front and side pockets", "color": "grey", "style": "formal", "formality": 5},
        {"desc": "Black slim-fit dress pants in a ponte fabric with a flat front, zip fly and no visible pockets", "color": "black", "style": "formal", "formality": 5},
        {"desc": "Beige herringbone chino trousers in a cotton twill with a flat front, slim taper and cuffed hem", "color": "beige", "style": "formal", "formality": 3},
        # Elegant
        {"desc": "A champagne gold satin midi skirt with a wrap front, a slight flare and a self-tie waist", "color": "cream", "style": "elegant", "formality": 4},
        {"desc": "A black high-waisted pencil skirt in ponte fabric with a back kick pleat and an invisible zip", "color": "black", "style": "elegant", "formality": 4},
        {"desc": "A burgundy pleated midi skirt in a lightweight crepe with a flowy A-line silhouette", "color": "burgundy", "style": "elegant", "formality": 4},
        # Casual
        {"desc": "Blue slim-fit denim jeans with a straight leg, five-pocket design and a medium wash finish", "color": "blue", "style": "casual", "formality": 2},
        {"desc": "Khaki cotton chino trousers with a relaxed straight fit, side pockets and a cuffed hem", "color": "khaki", "style": "casual", "formality": 2},
        {"desc": "Olive green cotton cargo trousers with multiple pockets, a relaxed fit and tapered ankle", "color": "olive", "style": "casual", "formality": 1},
        {"desc": "Black ripped skinny jeans in a stretch denim with distressed details, raw hem and ankle zip", "color": "black", "style": "casual", "formality": 1},
        {"desc": "Light wash straight-leg jeans with a high rise, five pockets and subtle fading at the thighs", "color": "blue", "style": "casual", "formality": 2},
        # Sport
        {"desc": "Grey marl athletic jogger pants with an elastic waistband, side stripe detail and tapered leg", "color": "grey", "style": "sport", "formality": 0},
        {"desc": "Black polyester training shorts with an elastic waistband, side pockets and a four-way stretch fabric", "color": "black", "style": "sport", "formality": 0},
        {"desc": "Navy blue compression cycling tights with a high-rise waist, flat seams and a moisture-wicking finish", "color": "navy", "style": "sport", "formality": 0},
    ],
    "OUTERWEAR": [
        # Formal
        {"desc": "A charcoal grey single-breasted wool blazer with notch lapels, two-button front and welt pockets", "color": "grey", "style": "formal", "formality": 4},
        {"desc": "A navy blue double-breasted suit jacket with peak lapels, six-button front and a tailored fit", "color": "navy", "style": "formal", "formality": 5},
        {"desc": "A black tailored wool blend overcoat with a notch collar, single-breasted front and a belted back", "color": "black", "style": "formal", "formality": 4},
        {"desc": "A camel coloured single-breasted woollen coat with a notch lapel, two-button closure and patch pockets", "color": "beige", "style": "formal", "formality": 4},
        # Elegant
        {"desc": "A deep burgundy velvet blazer with a shawl lapel, one-button front and a slim fitted silhouette", "color": "burgundy", "style": "elegant", "formality": 4},
        # Casual
        {"desc": "A dark indigo denim jacket with a button front, chest flap pockets and a classic trucker style", "color": "blue", "style": "casual", "formality": 2},
        {"desc": "A khaki cotton trench coat with a double-breasted front, epaulettes, storm flap and a self-tie belt", "color": "khaki", "style": "casual", "formality": 3},
        {"desc": "A black leather bomber jacket with a zip front, ribbed cuffs and hem, and two side pockets", "color": "black", "style": "casual", "formality": 2},
        {"desc": "An olive green quilted gilet with a zip front, side pockets and a slightly fitted silhouette", "color": "olive", "style": "casual", "formality": 2},
        # Sport
        {"desc": "A bright orange windbreaker jacket with a full zip, mesh lining, reflective details and packable hood", "color": "orange", "style": "sport", "formality": 0},
        {"desc": "A grey fleece zip-up hoodie with a kangaroo pocket, ribbed hem and an athletic regular fit", "color": "grey", "style": "sport", "formality": 1},
    ],
    "FOOTWEAR": [
        # Formal
        {"desc": "Brown full-grain leather Oxford lace-up shoes with a cap-toe, Goodyear welt construction and leather sole", "color": "brown", "style": "formal", "formality": 5},
        {"desc": "Black polished leather Derby shoes with a round toe, Goodyear welt and a leather and rubber sole", "color": "black", "style": "formal", "formality": 5},
        {"desc": "Dark brown leather Chelsea boots with an elastic side panel, almond toe and a stacked heel", "color": "brown", "style": "formal", "formality": 4},
        {"desc": "Tan suede tassel loafers with a penny strap, cushioned insole and a leather sole", "color": "beige", "style": "formal", "formality": 4},
        # Elegant
        {"desc": "Black patent leather pointed-toe stiletto heels with an ankle strap and a slender stiletto heel", "color": "black", "style": "elegant", "formality": 5},
        {"desc": "Nude satin kitten heels with a d'Orsay cut, a pointed toe and a delicate ankle strap detail", "color": "cream", "style": "elegant", "formality": 4},
        {"desc": "Burgundy suede block-heel ankle boots with a side zip and a comfortable square toe", "color": "burgundy", "style": "elegant", "formality": 4},
        # Casual
        {"desc": "White canvas low-top sneakers with a rubber cupsole, a round toe and a minimalist clean design", "color": "white", "style": "casual", "formality": 2},
        {"desc": "Beige suede desert boots with a crepe rubber sole, a round toe and speed-hook lace closure", "color": "beige", "style": "casual", "formality": 3},
        {"desc": "Black leather loafers with a penny strap, a classic round toe and a flexible rubber sole", "color": "black", "style": "casual", "formality": 3},
        {"desc": "Navy blue canvas slip-on espadrilles with a jute-wrapped platform sole and a round toe", "color": "navy", "style": "casual", "formality": 2},
        # Sport
        {"desc": "Fluorescent green lightweight running shoes with a foam midsole, mesh upper and reflective heel tab", "color": "green", "style": "sport", "formality": 0},
        {"desc": "Black and white high-top basketball sneakers with ankle support, padded collar and thick rubber sole", "color": "black", "style": "sport", "formality": 1},
        {"desc": "Grey trail running shoes with a grippy rubber outsole, mesh upper and a cushioned EVA midsole", "color": "grey", "style": "sport", "formality": 0},
    ],
    "ACCESSORY": [
        {"desc": "A slim navy blue silk tie with a small diamond-pattern and a seven-fold construction", "color": "navy", "style": "formal", "formality": 4},
        {"desc": "A brown leather dress belt with a polished silver pin buckle and stitched edge detailing", "color": "brown", "style": "formal", "formality": 4},
        {"desc": "A grey herringbone wool pocket square with a white satin border and a hand-rolled edge", "color": "grey", "style": "formal", "formality": 4},
        {"desc": "A burgundy striped silk pocket square with hand-rolled edges for a formal occasion", "color": "burgundy", "style": "formal", "formality": 4},
        {"desc": "A black leather casual belt with a matte gunmetal buckle and a slightly distressed finish", "color": "black", "style": "casual", "formality": 2},
        {"desc": "A red sports cap with a structured brim, mesh back panel and an adjustable snapback strap", "color": "red", "style": "sport", "formality": 0},
        {"desc": "A beige canvas tote bag with brown leather handles, a magnetic snap closure and interior pockets", "color": "beige", "style": "casual", "formality": 2},
    ],
}

# ── Style compatibility matrix ────────────────────────────────────────────────
COMPATIBLE_STYLE_PAIRS = {
    ("formal", "formal"), ("formal", "elegant"),
    ("elegant", "elegant"), ("elegant", "formal"),
    ("casual", "casual"),
    ("sport", "sport"),
}

INCOMPATIBLE_STYLE_PAIRS = [
    ("formal", "sport"), ("sport", "formal"),
    ("elegant", "sport"), ("sport", "elegant"),
    ("formal", "casual"), ("casual", "formal"),
    ("elegant", "casual"), ("casual", "elegant"),
]


def _color_harmony_score(color_a: str, color_b: str) -> float:
    """Returns 1.0 = harmonious, 0.5 = neutral, 0.0 = clashing."""
    if color_a == color_b:
        return 0.85  # same color = ok but slightly boring
    compat = COLOR_COMPATIBILITY.get(color_a, {"allows": [], "avoids": []})
    if color_b in compat["allows"]:
        return 1.0
    if color_b in compat["avoids"]:
        return 0.0
    return 0.5


def _is_color_clash(colors: List[str]) -> bool:
    for i in range(len(colors)):
        for j in range(i + 1, len(colors)):
            if _color_harmony_score(colors[i], colors[j]) == 0.0:
                return True
    return False


def _are_styles_compatible(styles: List[str]) -> bool:
    unique = list(set(styles))
    if len(unique) == 1:
        return True
    for i in range(len(unique)):
        for j in range(i + 1, len(unique)):
            if (unique[i], unique[j]) not in COMPATIBLE_STYLE_PAIRS:
                return False
    return True


def _formality_range(garments: List[Dict]) -> int:
    formalities = [g["formality"] for g in garments]
    return max(formalities) - min(formalities)


# ── Compatible outfit generator ───────────────────────────────────────────────

def generate_compatible_outfits(n: int) -> List[Tuple[List[Dict], int]]:
    """Generate n compatible outfit examples (label=1)."""
    results = []
    attempts = 0
    max_attempts = n * 20

    while len(results) < n and attempts < max_attempts:
        attempts += 1
        style = random.choice(["formal", "casual", "sport", "elegant"])

        tops = [g for g in GARMENT_TEMPLATES["TOP"] if g["style"] == style]
        bottoms = [g for g in GARMENT_TEMPLATES["BOTTOM"] if g["style"] == style]
        shoes = [g for g in GARMENT_TEMPLATES["FOOTWEAR"]
                 if g["style"] == style or abs(g["formality"] - (tops[0]["formality"] if tops else 2)) <= 1]

        if not tops or not bottoms or not shoes:
            continue

        top = {**random.choice(tops), "category": "TOP"}
        bottom = {**random.choice(bottoms), "category": "BOTTOM"}
        shoe = {**random.choice(shoes), "category": "FOOTWEAR"}
        outfit = [top, bottom, shoe]

        # Optionally add outerwear (60% chance)
        if random.random() < 0.6:
            outers = [g for g in GARMENT_TEMPLATES["OUTERWEAR"]
                      if g["style"] == style or abs(g["formality"] - top["formality"]) <= 1]
            if outers:
                outfit.append({**random.choice(outers), "category": "OUTERWEAR"})

        colors = [g["color"] for g in outfit]
        if _is_color_clash(colors):
            continue
        if _formality_range(outfit) > 1:
            continue

        results.append((outfit, 1))

    return results


# ── Incompatible outfit generator ─────────────────────────────────────────────

def generate_incompatible_outfits(n: int) -> List[Tuple[List[Dict], int]]:
    """Generate n incompatible outfit examples (label=0)."""
    results = []
    attempts = 0
    max_attempts = n * 20

    all_tops = GARMENT_TEMPLATES["TOP"]
    all_bottoms = GARMENT_TEMPLATES["BOTTOM"]
    all_shoes = GARMENT_TEMPLATES["FOOTWEAR"]
    all_outers = GARMENT_TEMPLATES["OUTERWEAR"]

    while len(results) < n and attempts < max_attempts:
        attempts += 1
        mode = random.choice(["style_clash", "color_clash", "formality_clash"])

        if mode == "style_clash":
            style_a, style_b = random.choice(INCOMPATIBLE_STYLE_PAIRS)
            style_c = random.choice([style_a, style_b, random.choice(["casual", "sport"])])

            top_pool = [g for g in all_tops if g["style"] == style_a]
            bot_pool = [g for g in all_bottoms if g["style"] == style_b]
            shoe_pool = [g for g in all_shoes if g["style"] == style_c]

            if not top_pool or not bot_pool or not shoe_pool:
                continue

            outfit = [
                {**random.choice(top_pool), "category": "TOP"},
                {**random.choice(bot_pool), "category": "BOTTOM"},
                {**random.choice(shoe_pool), "category": "FOOTWEAR"},
            ]

        elif mode == "color_clash":
            # Find a pair with known color clash
            clash_pairs = [
                ("navy", "brown"), ("navy", "orange"),
                ("black", "brown"), ("burgundy", "orange"),
                ("beige", "orange"), ("blue", "orange"),
                ("brown", "black"), ("red", "orange"),
                ("brown", "navy"),
            ]
            clash_top_color, clash_bot_color = random.choice(clash_pairs)
            top_pool = [g for g in all_tops if g["color"] == clash_top_color]
            bot_pool = [g for g in all_bottoms if g["color"] == clash_bot_color]

            if not top_pool or not bot_pool:
                continue

            top = {**random.choice(top_pool), "category": "TOP"}
            bottom = {**random.choice(bot_pool), "category": "BOTTOM"}
            shoe = {**random.choice(all_shoes), "category": "FOOTWEAR"}
            outfit = [top, bottom, shoe]

        else:  # formality_clash
            top = {**random.choice(all_tops), "category": "TOP"}
            # Pick a bottom with formality difference >= 3
            bot_pool = [g for g in all_bottoms
                        if abs(g["formality"] - top["formality"]) >= 3]
            if not bot_pool:
                continue
            bottom = {**random.choice(bot_pool), "category": "BOTTOM"}

            # Add a mismatching outerwear (optional but amplifies clash)
            shoe = {**random.choice(all_shoes), "category": "FOOTWEAR"}
            outfit = [top, bottom, shoe]

            if random.random() < 0.5:
                outer_pool = [g for g in all_outers
                              if abs(g["formality"] - top["formality"]) >= 2]
                if outer_pool:
                    outfit.append({**random.choice(outer_pool), "category": "OUTERWEAR"})

        # Verify it's actually incompatible (avoid accidental compatible outfits)
        styles = [g["style"] for g in outfit]
        colors = [g["color"] for g in outfit]
        formality_diff = _formality_range(outfit)

        is_incompat = (
            not _are_styles_compatible(styles)
            or _is_color_clash(colors)
            or formality_diff >= 3
        )
        if not is_incompat:
            continue

        results.append((outfit, 0))

    return results


def build_dataset(n_compatible: int = 1200, n_incompatible: int = 1200) -> List[Tuple[List[Dict], int]]:
    """Build a balanced dataset of outfit examples."""
    compatible = generate_compatible_outfits(n_compatible)
    incompatible = generate_incompatible_outfits(n_incompatible)
    dataset = compatible + incompatible
    random.shuffle(dataset)
    print(f"Dataset generado: {len(compatible)} compatibles + {len(incompatible)} incompatibles = {len(dataset)} total")
    return dataset
