#!/usr/bin/env python3
"""ArchTitan TDL colour linter.

Enforces that every colour literal in QML / CSS / rasi / conf / C++ files is an
actual value from the Titan Design Language palette (derived from the canonical
token file, titan-ui/qml/style/TitanTheme.qml), a neutral white/black overlay,
or the adaptive accent. This catches off-brand drift (e.g. a stray Tailwind
colour) that would otherwise silently break visual consistency.

Files listed in scripts/colour-allow.txt (path substring, one per line) are
exempt -- used for brand marks, generated artwork and data swatches.

Exit code 1 if any violation is found.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
TOKEN_FILE = REPO / "titan-ui" / "qml" / "style" / "TitanTheme.qml"
ALLOW_FILE = REPO / "scripts" / "colour-allow.txt"
# The baseline theme definition (shipped palettes; every theme shares this
# schema). TitanTheme.qml now derives its surfaces from ThemeBackend at runtime
# and only carries a few alpha literals, so the authoritative colour set for
# static config files is the baseline theme's palette.
BASELINE_THEME = (REPO / "airootfs" / "usr" / "share" / "archtitan"
                  / "themes" / "mocha.json")

# The adaptive accent's default (Catppuccin Mocha blue) and ArchTitan signature cyan;
# runtime accent may be any colour, so any alpha of it is accepted in addition to the static palette.
ACCENT_DEFAULT = "89B4FA".lower()
TITAN_ACCENT = "00D2FF".lower()

# Neutral overlays (white / black at any alpha) are always allowed.
NEUTRALS = {"ffffff", "000000"}

SKIP_DIRS = ("/build/", "tmp-work", "node_modules", "/.git/",
             "airootfs/usr/lib/qt6/qml/", "/.cache/")
# C++ is included so the Qt Widgets surfaces (titanfetch, titanbrowser) obey the
# same no-hardcoded-colour rule as the QML shell — they consume TDL via
# TitanPalette.h, and a stray Mocha literal there is drift just like in QML.
# .qss / .desc cover the installer (Calamares) surfaces.
SCAN_EXT = {".qml", ".css", ".rasi", ".conf", ".qss", ".desc",
            ".cpp", ".h", ".hpp", ".cc"}
# Files with no distinctive suffix that still carry theme colours (GRUB theme).
SCAN_NAMES = {"theme.txt"}
# The token file itself is the source of truth -- never flag it.
SKIP_FILES = {TOKEN_FILE}

HEX_RE = re.compile(r"#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b")
RGB_RE = re.compile(
    r"(?<!\.)\brgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*(?:,\s*[\d.]+\s*)?\)"
)


def load_palette() -> set[str]:
    """Colour tokens allowed in static config files.

    Union of the QML singleton's literal hexes (alpha overlays, derived
    neutral borders) and the baseline theme's palette + accents.
    """
    hexes = {h.lower()[-6:] for h in HEX_RE.findall(
        TOKEN_FILE.read_text(encoding="utf-8")
    )}

    if BASELINE_THEME.exists():
        import json

        theme = json.loads(BASELINE_THEME.read_text(encoding="utf-8"))
        values = list(theme.get("palette", {}).values())
        values += [theme.get("accent", ""), theme.get("accent2", "")]
        for value in values:
            if isinstance(value, str):
                digits = value.strip().lstrip("#")
                if re.fullmatch(r"[0-9a-fA-F]{6}", digits):
                    hexes.add(digits.lower())

    hexes.add(ACCENT_DEFAULT)
    hexes.add(TITAN_ACCENT)
    return hexes


def load_allow() -> list[str]:
    if not ALLOW_FILE.exists():
        return []
    out = []
    for line in ALLOW_FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            out.append(line)
    return out


def rgb_to_hex(r: int, g: int, b: int) -> str:
    return f"{r:02x}{g:02x}{b:02x}"


def main() -> int:
    palette = load_palette()
    allow = load_allow()

    violations: list[tuple[Path, int, str]] = []
    scanned = 0

    for path in REPO.rglob("*"):
        if (path.suffix not in SCAN_EXT and path.name not in SCAN_NAMES) or not path.is_file():
            continue
        rel = path.relative_to(REPO).as_posix()
        if path.resolve() in SKIP_FILES:
            continue
        if any(s in ("/" + rel) for s in SKIP_DIRS):
            continue
        if any(a in rel for a in allow):
            continue

        # CSS/rasi use #RRGGBBAA (alpha last); Qt uses #AARRGGBB (alpha first).
        css_alpha = path.suffix in {".css", ".rasi"}

        scanned += 1
        for lineno, line in enumerate(path.read_text(encoding="utf-8",
                                                     errors="replace").splitlines(), 1):
            # Inline escape hatch for deliberate non-palette colours.
            if "tdl-allow" in line:
                continue
            for m in HEX_RE.finditer(line):
                val = m.group(1).lower()
                rgb = val[:6] if (css_alpha and len(val) == 8) else val[-6:]
                if rgb in palette or rgb in NEUTRALS:
                    continue
                violations.append((path, lineno, m.group(0)))

            for m in RGB_RE.finditer(line):
                r, g, b = (int(m.group(i)) for i in (1, 2, 3))
                if not all(0 <= v <= 255 for v in (r, g, b)):
                    continue
                rgb = rgb_to_hex(r, g, b)
                if rgb in palette or rgb in NEUTRALS:
                    continue
                violations.append((path, lineno, m.group(0)))

    print(f"colour-lint: scanned {scanned} files, palette={len(palette)} tokens, "
          f"allowlist={len(allow)} entries")
    if not violations:
        print("✓ no off-palette colour literals found")
        return 0

    for path, lineno, lit in violations:
        print(f"  {path.relative_to(REPO).as_posix()}:{lineno}: {lit}")
    print(f"\n✗ {len(violations)} off-palette colour literal(s) found")
    print("  Use a TitanTheme token (QML) or a TDL value; add legitimate "
          "brand/data files to scripts/colour-allow.txt")
    return 1


if __name__ == "__main__":
    sys.exit(main())
