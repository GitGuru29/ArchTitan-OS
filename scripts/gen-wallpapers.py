#!/usr/bin/env python3
"""ArchTitan wallpaper generator — TDL palette "gradient field" artwork.

Renders premium abstract wallpapers (deep Catppuccin surfaces + soft accent
glows + film grain + vignette) straight from the Titan Design Language
palette. Deterministic per variant via fixed seeds, so re-running produces
byte-stable assets — no downloads, no licensing questions.

Usage:
    python3 scripts/gen-wallpapers.py [output_dir]

Output defaults to airootfs/usr/share/backgrounds/archtitan/.
Reused by M2 (titan-theme) to render per-theme wallpaper sets.
"""

from __future__ import annotations

import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "airootfs/usr/share/backgrounds/archtitan"

W, H = 2560, 1440

# ── TDL palette (Catppuccin Mocha) ──────────────────────────────────────────
CRUST, MANTLE, BASE = (17, 17, 27), (24, 24, 37), (30, 30, 46)

# (name, background pair, glow colours, glow count)
VARIANTS = [
    ("titan-blue",      (CRUST, MANTLE), [(137, 180, 250), (180, 190, 254), (49, 50, 68)],   3),
    ("titan-mauve",     (CRUST, MANTLE), [(203, 166, 247), (245, 194, 231), (49, 50, 68)],   3),
    ("titan-lavender",  (MANTLE, BASE),  [(180, 190, 254), (203, 166, 247), (69, 71, 90)],   3),
    ("titan-teal",      (CRUST, MANTLE), [(148, 226, 213), (137, 180, 250), (49, 50, 68)],   3),
    ("titan-peach",     (CRUST, MANTLE), [(250, 179, 135), (249, 226, 175), (69, 71, 90)],   3),
    ("titan-green",     (CRUST, MANTLE), [(166, 227, 161), (148, 226, 213), (49, 50, 68)],   3),
    ("titan-pink",      (MANTLE, BASE),  [(245, 194, 231), (203, 166, 247), (69, 71, 90)],   3),
    ("titan-mocha",     (CRUST, MANTLE), [(69, 71, 90), (88, 91, 112), (49, 50, 68)],        4),
    # Light counterpart for Catppuccin Latte: Latte base/crust field, soft
    # blue/mauve accents, and a much gentler vignette (the black edge that
    # settles dark wallpapers reads as grime on a light field).
    ("titan-latte",     ((239, 241, 245), (220, 224, 232)),
     [(30, 102, 245), (136, 57, 239), (174, 180, 198)], 3, 90),
]


def vertical_gradient(top, bottom) -> Image.Image:
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / (H - 1)
        # gentle ease so the blend reads as depth, not a stripe
        t = t * t * (3 - 2 * t)
        c = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        d.line([(0, y), (W, y)], fill=c)
    return img


def glow(size, colour, strength) -> Image.Image:
    """One soft radial glow as an RGBA layer."""
    r = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(r)
    cx, cy = random.randint(0, W), random.randint(0, H)
    d.ellipse([cx - size, cy - size, cx + size, cy + size],
              fill=(*colour, strength))
    return r.filter(ImageFilter.GaussianBlur(size // 2))


def render(name, bg, colours, count, seed, vignette=255) -> Image.Image:
    random.seed(seed)
    img = vertical_gradient(*bg).convert("RGBA")

    for i in range(count):
        size = random.randint(W // 4, W // 2)
        strength = random.randint(70, 120)
        img.alpha_composite(glow(size, colours[i % len(colours)], strength))

    # Vignette — settles the composition into the screen edges
    vign = Image.new("L", (W, H), 0)
    dv = ImageDraw.Draw(vign)
    dv.ellipse([-W // 3, -H // 3, W + W // 3, H + H // 3], fill=255)
    vign = vign.filter(ImageFilter.GaussianBlur(W // 8))
    img.alpha_composite(Image.merge("RGBA", [
        Image.new("L", (W, H), 0), Image.new("L", (W, H), 0),
        Image.new("L", (W, H), 0),
        vign.point(lambda v: int((255 - v) * vignette / 255))]))

    # Film grain — kills gradient banding on8-bit panels
    grain = Image.effect_noise((W, H), 12).convert("L")
    img.alpha_composite(Image.merge("RGBA", [
        Image.new("L", (W, H), 128)] * 3 + [grain.point(lambda v: 10)]))

    return img.convert("RGB")


def main() -> int:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT
    out.mkdir(parents=True, exist_ok=True)
    for i, spec in enumerate(VARIANTS):
        name, bg, colours, count = spec[:4]
        vignette = spec[4] if len(spec) > 4 else 255
        path = out / f"{name}.jpg"
        render(name, bg, colours, count, seed=42 + i,
               vignette=vignette).save(
            path, "JPEG", quality=88, optimize=True)
        print(f"  {path.name:20s} {path.stat().st_size // 1024:4d} KiB")
    print(f"✓ {len(VARIANTS)} wallpapers written to {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
