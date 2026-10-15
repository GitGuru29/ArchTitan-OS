#!/usr/bin/env python3
"""ArchTitan TDL contrast audit (WCAG 2.1).

Parses the static colour tokens out of ``titan-ui/qml/style/TitanTheme.qml`` and
checks a set of foreground/background pairings used throughout the shell against
WCAG relative-luminance contrast thresholds. Translucent backgrounds (AARRGGBB)
are composited over an opaque backdrop before measuring.

Exit status: 0 when every pair meets its target, 1 otherwise.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
THEME = REPO / "titan-ui/qml/style/TitanTheme.qml"

# Default adaptive accent + its auto-selected foreground (see themebackend.cpp).
ACCENT = "#89B4FA"
ACCENT_FG = "#11111B"

TOKEN_RE = re.compile(
    r'property\s+color\s+(\w+)\s*:\s*"(#[0-9a-fA-F]{6,8})"'
)

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
    tokens: dict[str, str] = {}
    for name, value in TOKEN_RE.findall(THEME.read_text(encoding="utf-8")):
        tokens[name] = value
    return tokens


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
