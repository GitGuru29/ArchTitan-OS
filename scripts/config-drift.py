#!/usr/bin/env python3
"""ArchTitan config-tree drift checker.

Three config trees ship in the ISO profile and must not silently diverge:

  * ``airootfs/etc/skel``       -> canonical / newest
  * ``airootfs/root``           -> must be byte-identical to skel for shared files
  * ``airootfs/home/archtitan`` -> live-ISO variant (documented deltas only)

Rules
-----
1. For every file present in BOTH ``skel`` and ``root`` the bytes must match.
   Root-only files are expected (``.automated_script.sh``, ``.bash_profile``,
   ``.zlogin``, ``.gnupg/``) and ignored. Divergences fail the check unless the
   relative path is listed in ``ROOT_ALLOW``.
2. For every file present in both ``skel`` and ``home/archtitan`` a divergence
   is only a *warning* unless the path is in ``LIVE_EXPECTED`` (documented
   live-ISO differences), in which case it is silent. This tree intentionally
   disables lock/idle/DPMS and omits the layer rule.

Exit status: 0 when clean (no rule-1 violations), 1 otherwise.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SKEL = REPO / "airootfs/etc/skel"
ROOT = REPO / "airootfs/root"
LIVE = REPO / "airootfs/home/archtitan"

# Files allowed to differ between skel and root (relative to the tree root).
ROOT_ALLOW = {
    # root's login shell additionally runs fastfetch.
    ".config/fish/config.fish",
}

# Files known/expected to differ in the live-ISO variant (relative path).
LIVE_EXPECTED = {
    ".config/hypr/hypridle.conf",
    ".config/hypr/hyprland.conf",
    ".config/hypr/hyprland.lua",
    ".config/hypr/hyprlock.conf",  # present in skel, omitted on the live ISO
}


def rel_files(base: Path) -> dict[str, Path]:
    if not base.is_dir():
        return {}
    out: dict[str, Path] = {}
    for dirpath, _dirs, files in os.walk(base):
        for name in files:
            p = Path(dirpath) / name
            out[str(p.relative_to(base))] = p
    return out


def main() -> int:
    skel = rel_files(SKEL)
    root = rel_files(ROOT)
    live = rel_files(LIVE)

    violations: list[str] = []
    warnings: list[str] = []

    for rel, sp in sorted(skel.items()):
        if rel in root:
            if sp.read_bytes() != root[rel].read_bytes() and rel not in ROOT_ALLOW:
                violations.append(rel)
        if rel in live:
            if sp.read_bytes() != live[rel].read_bytes() and rel not in LIVE_EXPECTED:
                warnings.append(rel)

    print(f"config-drift: skel={len(skel)} root={len(root)} live={len(live)} files")
    for rel in warnings:
        print(f"  ~ live variant differs (informational): {rel}")
    for rel in violations:
        print(f"  ✗ skel/root diverged: {rel}")

    if violations:
        print(f"\n✗ {len(violations)} skel/root divergence(s). "
              f"Sync the file or add it to ROOT_ALLOW.")
        return 1
    print("✓ config trees consistent")
    return 0


if __name__ == "__main__":
    sys.exit(main())
