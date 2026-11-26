#!/usr/bin/env python3
"""ArchTitan qt5ct palette generator — one [ColorScheme] file per theme.

qt5ct only understands flat colour-scheme files, so every theme ships one at
``airootfs/usr/share/qt5ct/colors/archtitan-<id>.conf`` and ``titan-theme``
points ``qt5ct.conf`` at the active theme's file.

Catppuccin mocha and latte are vendored verbatim from catppuccin/qt5ct (see
scripts/colour-allow.txt) and are *not* generated. This script renders the
remaining themes from their ``themes/<id>.json`` palette.

The 22-slot role mapping is a direct transliteration of the official
``catppuccin/qt5ct`` whiskers template (qt5ct.tera); the "disabled" link
slots reproduce whiskers' ``sub(saturation=50)`` — HSL saturation minus 50
percentage points — verified against both vendored files.

Usage:
    python3 scripts/gen-qt5ct.py
"""

from __future__ import annotations

import colorsys
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
THEMES = REPO / "airootfs/usr/share/archtitan/themes"
OUT = REPO / "airootfs/usr/share/qt5ct/colors"

# Vendored upstream — never generated (would lose verbatim provenance).
OFFICIAL = {"mocha", "latte"}


def aarrggbb(hexv: str, alpha: str = "ff") -> str:
    return f"{alpha}{hexv[1:].lower()}"


def desaturate_50(hexv: str) -> str:
    """whiskers ``sub(saturation=50)``: HSL S - 50 points, hue/lightness kept."""
    r, g, b = (int(hexv[i:i + 2], 16) / 255 for i in (1, 3, 5))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    r, g, b = colorsys.hls_to_rgb(h, l, max(0.0, s - 0.5))
    return f"#{round(r * 255):02x}{round(g * 255):02x}{round(b * 255):02x}"


def rows(t: dict) -> dict[str, list[str]]:
    p = t["palette"]
    accent, accent2, dark = t["accent"], t["accent2"], t["isDark"]
    # qt5ct's "default" slot: white in dark schemes, black in light ones —
    # both vendored upstream files use *opaque* alpha (ff000000 / ffffffff).
    default = "ffffffff" if dark else "ff000000"
    a_ov0 = aarrggbb(p["surface3"], "80")           # overlay0 @ 50%
    acc, acc2 = aarrggbb(accent), aarrggbb(accent2)
    return {
        "active": [
            aarrggbb(p["textHigh"]), aarrggbb(p["surface1"]),
            aarrggbb(p["surface2"]), aarrggbb(p["surface0"]),
            aarrggbb(p["crust"]), aarrggbb(p["mantle"]),
            aarrggbb(p["textHigh"]), aarrggbb(p["textHigh"]),
            aarrggbb(p["textHigh"]), aarrggbb(p["base"]),
            aarrggbb(p["mantle"]), aarrggbb(p["crust"]),
            acc, aarrggbb(p["crust"]), acc, acc2,
            aarrggbb(p["mantle"]), default,
            aarrggbb(p["base"]), aarrggbb(p["textHigh"]),
            a_ov0, acc,
        ],
        "inactive": [
            aarrggbb(p["textLow"]), aarrggbb(p["base"]),
            aarrggbb(p["surface1"]), aarrggbb(p["surface0"]),
            aarrggbb(p["crust"]), aarrggbb(p["mantle"]),
            aarrggbb(p["textLow"]), aarrggbb(p["textHigh"]),
            aarrggbb(p["textLow"]), aarrggbb(p["base"]),
            aarrggbb(p["mantle"]), aarrggbb(p["crust"]),
            aarrggbb(p["surface0"]), aarrggbb(p["textLow"]),
            aarrggbb(p["textLow"]), aarrggbb(p["textLow"]),
            aarrggbb(p["mantle"]), default,
            aarrggbb(p["base"]), aarrggbb(p["textHigh"]),
            a_ov0, aarrggbb(p["surface0"]),
        ],
        "disabled": [
            aarrggbb(p["surface3"]), aarrggbb(p["surface0"]),
            aarrggbb(p["surface1"]), aarrggbb(p["surface0"]),
            aarrggbb(p["crust"]), aarrggbb(p["mantle"]),
            aarrggbb(p["surface3"]), aarrggbb(p["textHigh"]),
            aarrggbb(p["surface3"]), aarrggbb(p["base"]),
            aarrggbb(p["mantle"]), aarrggbb(p["crust"]),
            aarrggbb(p["mantle"]), aarrggbb(p["surface3"]),
            aarrggbb(desaturate_50(accent)), aarrggbb(desaturate_50(accent2)),
            aarrggbb(p["mantle"]), default,
            aarrggbb(p["base"]), aarrggbb(p["textHigh"]),
            a_ov0, aarrggbb(p["mantle"]),
        ],
    }


def main() -> int:
    if not THEMES.is_dir():
        print(f"gen-qt5ct: {THEMES} not found", file=sys.stderr)
        return 1
    OUT.mkdir(parents=True, exist_ok=True)
    for path in sorted(THEMES.glob("*.json")):
        t = json.loads(path.read_text(encoding="utf-8"))
        if t["id"] in OFFICIAL:
            print(f"  {t['id']}: vendored upstream, skipped")
            continue
        r = rows(t)
        out = OUT / f"archtitan-{t['id']}.conf"
        out.write_text(
            "[ColorScheme]\n"
            + "".join(f"{k}_colors={', '.join(v)}\n" for k, v in r.items()),
            encoding="utf-8",
        )
        print(f"  {out.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
