#!/usr/bin/env python3
"""ArchTitan TDL contrast audit (WCAG 2.1).

Parses the colour tokens out of the baseline theme definition
(``airootfs/usr/share/archtitan/themes/mocha.json`` — TitanTheme.qml now derives
its colours from ThemeBackend at runtime) and checks a set of
foreground/background pairings used throughout the shell against WCAG
relative-luminance contrast thresholds. Translucent backgrounds (AARRGGBB) are
composited over an opaque backdrop before measuring.

Exit status: 0 when every pair meets its target, 1 otherwise.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
THEME = REPO / "airootfs/usr/share/archtitan/themes/mocha.json"

# Status roles read straight from the theme palette under the same name.
ROLES = (
    "textHigh", "textMid", "textLow",
    "success", "warning", "danger", "teal", "peach", "mauve", "pink",
)

# Default adaptive accent + its auto-selected foreground (see themebackend.cpp).
ACCENT = "#89B4FA"
ACCENT_FG = "#11111B"

# (foreground, background, min-ratio, label). Backdrop for translucent bg.
PAIRS = [
    ("textHigh", "bg0", 7.0, "primary text / deepest"),
    ("textHigh", "base", 4.5, "primary text / base"),
    ("textMid", "bg0", 4.5, "secondary text / deepest"),
    ("textMid", "base", 4.5, "secondary text / base"),
    ("textMid", "surface0", 4.5, "secondary text / raised"),
    ("textLow", "bg0", 3.0, "tertiary text / deepest"),
    ("textLow", "base", 3.0, "tertiary text / base"),
    ("textLow", "surface0", 3.0, "tertiary text / raised"),
    ("info", "bg0", 4.5, "info / deepest"),
    ("success", "bg0", 4.5, "success / deepest"),
    ("warning", "bg0", 4.5, "warning / deepest"),
    ("danger", "bg0", 4.5, "danger / deepest"),
    ("teal", "bg0", 4.5, "teal / deepest"),
    ("peach", "bg0", 4.5, "peach / deepest"),
    ("mauve", "bg0", 4.5, "mauve / deepest"),
    ("pink", "bg0", 4.5, "pink / deepest"),
    ("accent", "bg0", 4.5, "accent / deepest"),
]


def parse_tokens() -> dict[str, str]:
    """Colour tokens for the audit, from the baseline theme definition.

    TitanTheme.qml derives every colour from ThemeBackend at runtime, so the
    authoritative values live in the shipped theme JSONs. `bg0` is the deepest
    surface (crust); the other roles keep their palette names.
    """
    theme = json.loads(THEME.read_text(encoding="utf-8"))
    palette = theme.get("palette", {})

    tokens: dict[str, str] = {}
    for name in ("crust", "base", "surface0") + ROLES:
        value = palette.get(name)
        if isinstance(value, str):
            tokens[name] = value
    # `bg0` is the audit's name for the deepest surface (crust).
    tokens["bg0"] = palette.get("crust", "")

    tokens["accent"] = theme.get("accent", ACCENT)
    # `info` is the accent unless the theme overrides it (see themebackend.cpp).
    tokens["info"] = palette.get("info") or theme.get("accent", ACCENT)
    return {name: value for name, value in tokens.items() if value}


def to_rgba(value: str) -> tuple[float, float, float, float]:
    """Return (r, g, b, a) as 0..1 floats from #RRGGBB / #AARRGGBB."""
    h = value.lstrip("#")
    if len(h) == 6:
        r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
        a = 255
    elif len(h) == 8:
        a, r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4, 6))
    else:
        raise ValueError(f"bad colour {value!r}")
    return r / 255, g / 255, b / 255, a / 255


def over(fg: str, backdrop: str) -> tuple[float, float, float]:
    fr, fg_, fb, fa = to_rgba(fg)
    br, bg_, bb, _ = to_rgba(backdrop)
    return (fr * fa + br * (1 - fa),
            fg_ * fa + bg_ * (1 - fa),
            fb * fa + bb * (1 - fa))


def luminance(rgb: tuple[float, float, float]) -> float:
    def chan(c: float) -> float:
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (chan(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def ratio(fg_rgb: tuple[float, float, float], bg_rgb: tuple[float, float, float]) -> float:
    l1, l2 = luminance(fg_rgb), luminance(bg_rgb)
    hi, lo = max(l1, l2), min(l1, l2)
    return (hi + 0.05) / (lo + 0.05)


def main() -> int:
    t = parse_tokens()
    t.setdefault("accent", ACCENT)
    t.setdefault("accentFg", ACCENT_FG)
    pairs = PAIRS + [("accentFg", "accent", 4.5, "text on accent (adaptive)")]

    failures = 0
    for fg_name, bg_name, target, label in pairs:
        if fg_name not in t or bg_name not in t:
            print(f"  ? {fg_name}/{bg_name}: token missing")
            continue
        # Composite translucent backgrounds over the deepest opaque base.
        bg_rgb = over(t[bg_name], t["crust"]) if len(t[bg_name]) == 9 else to_rgba(t[bg_name])[:3]
        # Foreground alpha over its own backdrop.
        fg_rgb = over(t[fg_name], t[bg_name]) if len(t[fg_name]) == 9 else to_rgba(t[fg_name])[:3]
        r = ratio(fg_rgb, bg_rgb)
        ok = r >= target
        mark = "✓" if ok else "✗"
        print(f"  {mark} {label:32s} {r:5.2f}:1  (need {target:.1f})")
        if not ok:
            failures += 1

    if failures:
        print(f"\n✗ {failures} contrast pair(s) below target")
        return 1
    print("\n✓ all contrast pairs meet target")
    return 0


if __name__ == "__main__":
    sys.exit(main())
