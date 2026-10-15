#!/usr/bin/env python3
"""One-off helper: snap off-palette colour literals to the nearest TDL token.

Used during P5 to bring leftover shell-config drift (swaync/kitty/waybar/rofi)
onto the Titan Design Language palette. Alpha is preserved. Run with the list
of files to rewrite as arguments.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
TOKEN_FILE = REPO / "titan-ui" / "qml" / "style" / "TitanTheme.qml"

HEX_RE = re.compile(r"#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b")
# (?<!\.) excludes Qt.rgba(r,g,b,a), whose args are 0..1 floats (not bytes).
RGB_RE = re.compile(
    r"(?<!\.)\brgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*(,\s*[\d.]+\s*)?\)"
)
NEUTRALS = {"ffffff", "000000"}


def load_palette() -> dict[str, tuple[int, int, int]]:
    text = TOKEN_FILE.read_text(encoding="utf-8")
    # Only SOLID 6-digit tokens are valid match targets. Translucent glass
    # tokens (#AARRGGBB) are excluded so surfs snap to real solid surfaces
    # rather than to an arbitrary glass RGB.
    pal: dict[str, tuple[int, int, int]] = {}
    for h in re.findall(r'"#([0-9a-fA-F]{6})"', text):
        pal[h.lower()] = tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
    pal["89b4fa"] = (0x89, 0xB4, 0xFA)  # accent default
    pal["252838"] = (0x25, 0x28, 0x38)  # border (not quoted as a bare hex)
    return pal


def nearest(rgb: tuple[int, int, int], pal: dict[str, tuple[int, int, int]]) -> str:
    return min(pal, key=lambda h: sum((a - b) ** 2 for a, b in zip(rgb, pal[h])))


def main(paths: list[str]) -> int:
    pal = load_palette()
    total = 0
    for arg in paths:
        p = Path(arg)
        if not p.is_absolute():
            p = REPO / p
        text = p.read_text(encoding="utf-8")
        logs: list[str] = []
        css_alpha = p.suffix in {".css", ".rasi"}

        def sub_hex(m: re.Match) -> str:
            val = m.group(1).lower()
            if len(val) == 8:
                rgb, alpha = (val[:6], val[6:]) if css_alpha else (val[-6:], val[:-6])
            else:
                rgb, alpha = val, ""
            if rgb in pal or rgb in NEUTRALS:
                return m.group(0)
            rep = nearest(tuple(int(rgb[i:i + 2], 16) for i in (0, 2, 4)), pal)
            out = "#" + (rep + alpha if css_alpha else alpha + rep)
            logs.append(f"    #{val} -> {out}")
            return out

        def sub_rgb(m: re.Match) -> str:
            r, g, b = (int(m.group(i)) for i in (1, 2, 3))
            rgb = f"{r:02x}{g:02x}{b:02x}"
            alpha = m.group(4) or ""
            if rgb in pal or rgb in NEUTRALS:
                return m.group(0)
            rep = nearest((r, g, b), pal)
            nr, ng, nb = (int(rep[i:i + 2], 16) for i in (0, 2, 4))
            logs.append(f"    rgba({r},{g},{b}) -> rgba({nr},{ng},{nb})")
            return f"rgba({nr}, {ng}, {nb}{alpha})"

        new = RGB_RE.sub(sub_rgb, text)
        new = HEX_RE.sub(sub_hex, new)
        if new != text:
            p.write_text(new)
            total += len(logs)
            print(f"  {p.relative_to(REPO)}  ({len(logs)} remapped)")
            for line in logs[:6]:
                print(line)
            if len(logs) > 6:
                print(f"    … +{len(logs) - 6} more")
    print(f"colour-remap: {total} literal(s) snapped to TDL")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
