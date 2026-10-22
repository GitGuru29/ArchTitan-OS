#!/usr/bin/env python3
"""ArchTitan TDL palette parity guard.

The C++ mirror of the design system (`titan-ui/include/TitanPalette.h`) must
stay in lock-step with its two sources of truth:

  * the QML singleton  titan-ui/qml/style/TitanTheme.qml   (token *set* and
    derived-alpha values), and
  * the canonical theme airootfs/usr/share/archtitan/themes/mocha.json
    (base palette values).

Historically the mirror drifted silently: `bg1`/`bg2`/`bg3` all returned the
opaque `base`, and glass/border/accent-derivative tokens were missing entirely.
This check fails if a QML token has no C++ accessor, if the Mocha fallback
table disagrees with mocha.json, or if a derived token's alpha differs.

Pure stdlib; run from CI.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
QML = REPO / "titan-ui" / "qml" / "style" / "TitanTheme.qml"
HDR = REPO / "titan-ui" / "include" / "TitanPalette.h"
# build.sh copies the header into the ISO tree; the two must stay byte-identical
# (the shipped copy is what bundled Widgets apps compile against).
HDR_INSTALLED = REPO / "airootfs" / "usr" / "include" / "archtitan" / "TitanPalette.h"
THEME = (REPO / "airootfs" / "usr" / "share" / "archtitan"
         / "themes" / "mocha.json")

# Tokens whose QML value is a `Qt.rgba(r, g, b, alpha)` derivative rather than a
# plain palette lookup; the C++ mirror must carry the same alpha.
DERIVED = {
    "bg1", "bg2", "bgInset", "glass", "glassAlt", "glassCard",
    "accentSoft", "accentSofter", "accentEdge",
}

COLOUR_RE = re.compile(r"\bproperty\s+(?:readonly\s+)?color\s+(\w+)")
SCALAR_RE = re.compile(
    r"\bproperty\s+(?:readonly\s+)?(int|real|string|bool)\s+(\w+)\s*:\s*([^\n]+)")
RGBA_RE = re.compile(
    r"\bproperty\s+color\s+(\w+)\s*:\s*Qt\.rgba\(\s*[^,]+,\s*[^,]+,\s*[^,]+,\s*([0-9.]+)\s*\)")
ACCESSOR_RE = re.compile(
    r"inline\s+(?:QColor|QString|int|double|bool)\s+(\w+)\s*\(\s*\)")
RETURN_RE = re.compile(r"\breturn\s+(.+?);", re.DOTALL)
TRAILING_INT_RE = re.compile(r",\s*(\d{1,3})\s*\)\s*$")
MOCHA_ENTRY_RE = re.compile(
    r"\{\s*QStringLiteral\(\"(\w+)\"\)\s*,\s*"
    r"QColor\(\s*0x([0-9A-Fa-f]{2}),\s*0x([0-9A-Fa-f]{2}),\s*0x([0-9A-Fa-f]{2})\s*\)\s*\}")


def norm(value: str) -> str:
    return value.strip().lstrip("#").lower()


def load_theme() -> dict[str, str]:
    theme = json.loads(THEME.read_text(encoding="utf-8"))
    out = {k: norm(v) for k, v in theme.get("palette", {}).items()}
    for key in ("accent", "accent2"):
        if theme.get(key):
            out[key] = norm(theme[key])
    return out


def parse_qml() -> tuple[set[str], set[str], dict[str, float]]:
    text = QML.read_text(encoding="utf-8")
    colours = set(COLOUR_RE.findall(text))
    scalars = {name for _, name, _ in SCALAR_RE.findall(text)}
    alphas = {name: float(a) for name, a in RGBA_RE.findall(text)}
    return colours, scalars, alphas


def parse_header() -> tuple[set[str], dict[str, str], dict[str, int]]:
    text = HDR.read_text(encoding="utf-8")

    names: set[str] = set()
    returns: dict[str, str] = {}
    for m in ACCESSOR_RE.finditer(text):
        name = m.group(1)
        names.add(name)
        brace = text.find("{", m.end())
        if brace == -1:
            continue
        depth, i = 1, brace + 1
        while i < len(text) and depth:
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
            i += 1
        body = text[brace + 1 : i - 1]
        rm = RETURN_RE.search(body)
        if rm:
            returns[name] = rm.group(1).strip()

    mocha = {
        name: f"{r}{g}{b}".lower()
        for name, r, g, b in MOCHA_ENTRY_RE.findall(text)
    }

    alphas: dict[str, int] = {}
    for name in DERIVED:
        tm = TRAILING_INT_RE.search(returns.get(name, ""))
        if tm:
            alphas[name] = int(tm.group(1))

    return names, mocha, alphas


def main() -> int:
    problems: list[str] = []

    colours, scalars, qml_alphas = parse_qml()
    names, mocha, cpp_alphas = parse_header()

    # 1. Token coverage: every QML token has a C++ accessor of the same name.
    for token in sorted(colours):
        if token not in names:
            problems.append(f"missing C++ accessor for colour token '{token}'")
    for token in sorted(scalars):
        if token not in names:
            problems.append(f"missing C++ accessor for scalar token '{token}'")

    # 2. Base palette: the Mocha fallback table matches mocha.json.
    theme = load_theme()
    for key, value in sorted(theme.items()):
        if key not in mocha:
            problems.append(f"mocha fallback is missing palette key '{key}'")
        elif mocha[key] != value:
            problems.append(f"mocha fallback '{key}' = #{mocha[key]} "
                            f"but mocha.json has #{value}")

    # 3. Derived-alpha parity.
    for token in sorted(DERIVED):
        frac = qml_alphas.get(token)
        if frac is None:
            problems.append(f"could not read QML alpha for derived token '{token}'")
            continue
        expected = round(frac * 255)
        got = cpp_alphas.get(token)
        if got is None:
            problems.append(f"cannot read derived alpha for '{token}' in header")
        elif got != expected:
            problems.append(f"derived alpha '{token}': QML {frac} (~{expected}) "
                            f"but C++ uses {got}")

    # 4. The installed copy of the header must be byte-identical to the source
    #    (build.sh does the copy; this catches a stale hand-edited install).
    if not HDR_INSTALLED.exists():
        problems.append(f"installed header missing: {HDR_INSTALLED.relative_to(REPO)}")
    elif HDR_INSTALLED.read_bytes() != HDR.read_bytes():
        problems.append(
            "installed header differs from titan-ui/include/TitanPalette.h "
            "(run titan-ui/build.sh or copy the file)")

    print(f"palette-parity: {len(colours)} colour tokens, {len(scalars)} scalar "
          f"tokens, {len(mocha)} fallback colours, {len(DERIVED)} derived alphas")

    if not problems:
        print("✓ C++ TitanPalette mirrors TitanTheme.qml")
        return 0

    for p in problems:
        print(f"  ✗ {p}")
    print(f"\n✗ {len(problems)} palette parity problem(s)")
    return 1


if __name__ == "__main__":
    sys.exit(main())
