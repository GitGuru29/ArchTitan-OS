#!/usr/bin/env python3
"""ArchTitan config-tree drift checker.

Three config trees ship in the ISO profile and must not silently diverge:

  * ``airootfs/etc/skel``       -> canonical source of truth
  * ``airootfs/root``           -> must be byte-identical to skel for shared files
  * ``airootfs/home/archtitan`` -> live-ISO variant, byte-identical to skel
                                   except for documented deltas

Rules
-----
1. For every file present in BOTH ``skel`` and ``root`` the bytes must match.
   Root-only files are expected (``.automated_script.sh``, ``.bash_profile``,
   ``.zlogin``, ``.gnupg/``) and ignored. Divergences fail the check unless the
   relative path is listed in ``ROOT_ALLOW``.
2. Every file in ``skel`` must also exist in ``home/archtitan`` — a whole file
   missing from the live tree (the historic hyprlock.conf bug) is a failure.
3. For every file present in both ``skel`` and ``home/archtitan`` the bytes
   must match unless the path is in ``LIVE_EXPECTED`` (documented live-ISO
   differences). The live tree locks nothing and never blanks the screen.

The ONLY sanctioned live-ISO difference today:
  * ``.config/hypr/hypridle.conf``  -> zero timeouts on the live session.
    Everything else is kept byte-identical across all three trees; live-only
    behaviour (disabled lock, no DPMS, installer autostart) is decided at
    runtime by ``/run/archiso`` checks inside ``hyprland.lua`` itself.

Exit status: 0 when clean, 1 otherwise.
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
    # The live session must never blank or lock: no timeouts, lock_cmd = :.
    ".config/hypr/hypridle.conf",
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

    for rel, sp in sorted(skel.items()):
        # Rule 1: skel == root for every shared file.
        if rel in root:
            if sp.read_bytes() != root[rel].read_bytes() and rel not in ROOT_ALLOW:
                violations.append(f"skel/root diverged: {rel}")
        # Rule 2: nothing may be missing from the live tree.
        if rel not in live:
            violations.append(f"missing from live tree: {rel}")
        # Rule 3: skel == live unless explicitly exempted.
        elif rel not in LIVE_EXPECTED and sp.read_bytes() != live[rel].read_bytes():
            violations.append(f"skel/live diverged: {rel}")

    print(f"config-drift: skel={len(skel)} root={len(root)} live={len(live)} files")
    for rel in sorted(LIVE_EXPECTED):
        print(f"  · live-ISO documented delta: {rel}")
    for v in violations:
        print(f"  ✗ {v}")

    if violations:
        print(f"\n✗ {len(violations)} config-tree divergence(s). "
              f"Sync the file or extend the allowlist with a comment.")
        return 1
    print("✓ config trees consistent")
    return 0


if __name__ == "__main__":
    sys.exit(main())
