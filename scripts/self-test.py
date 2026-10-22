#!/usr/bin/env python3
"""Guard-the-guards: prove the consistency checkers actually fail on drift.

A linter that silently passes is worse than no linter. This injects a known-bad
value into each checker's protected dimension, asserts a non-zero exit, then
restores the tree in a `finally` block. Cheap, dependency-free, deterministic —
so it can run in CI before the real checks.

Exit code 1 if any checker fails to catch its probe.
"""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SCRIPTS = REPO / "scripts"
HDR_SRC = REPO / "titan-ui" / "include" / "TitanPalette.h"
HDR_INSTALLED = REPO / "airootfs" / "usr" / "include" / "archtitan" / "TitanPalette.h"
PROBE = REPO / "zzz-selftest-probe.qml"

failures: list[str] = []


def rc(script: str) -> int:
    return subprocess.run([sys.executable, str(SCRIPTS / script)],
                          capture_output=True).returncode


def expect(name: str, script: str, want: int, got: int, detail: str) -> None:
    ok = got == want
    print(f"  {'✓' if ok else '✗'} {name}: exit {got} (want {want}) — {detail}")
    if not ok:
        failures.append(name)


def main() -> int:
    print("self-test: probing the consistency checkers")
    try:
        # 1. colour-lint must reject an off-palette literal…
        PROBE.write_text('import QtQuick\nRectangle { color: "#FF00FF" }\n',
                         encoding="utf-8")
        expect("colour-lint catches drift", "colour-lint.py", 1, rc("colour-lint.py"),
               'probe with "#FF00FF"')

        # 2. …and accept an on-palette one (so it is not just always failing).
        PROBE.write_text('import QtQuick\nRectangle { color: "#89B4FA" }\n',
                         encoding="utf-8")
        expect("colour-lint accepts palette", "colour-lint.py", 0, rc("colour-lint.py"),
               'probe with "#89B4FA"')
    finally:
        PROBE.unlink(missing_ok=True)

    # 3. palette-parity must reject a header that drifts from the source copy.
    backup = HDR_INSTALLED.read_bytes()
    try:
        HDR_INSTALLED.write_bytes(backup + b"\n// selftest drift\n")
        expect("palette-parity catches drift", "palette-parity.py", 1,
               rc("palette-parity.py"), "installed header differs")
    finally:
        shutil.copyfile(HDR_SRC, HDR_INSTALLED)

    # 4. palette-parity must accept the restored tree (sanity).
    expect("palette-parity clean after restore", "palette-parity.py", 0,
           rc("palette-parity.py"), "tree restored")

    if failures:
        print(f"\n✗ {len(failures)} checker(s) failed their probe: "
              + ", ".join(failures))
        return 1
    print("✓ all checkers catch the drift they exist to catch")
    return 0


if __name__ == "__main__":
    sys.exit(main())
