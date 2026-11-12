#!/usr/bin/env bash
# =============================================================================
# make-bench-disk.sh — build the shared benchmark disk image
#
# Creates bench/bench.img (sparse ext4, label BENCHDISK) containing:
#   /guest/   — the benchmark kit (statically-linked tstress + scripts)
#   /results/ — run outputs (guest writes, host extracts via debugfs)
#
# The same physical disk is attached to every arm, so the workload bits are
# byte-identical across ArchTitan+THM / ArchTitan-THM / vanilla Arch.
# =============================================================================
set -euo pipefail

BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BENCH_IMG="$BENCH_DIR/bench.img"
GUEST="$BENCH_DIR/guest"
SIZE="5G"

if [ ! -f "$GUEST/tstress.c" ]; then
    echo "[bench-disk] ERROR: $GUEST/tstress.c missing" >&2
    exit 1
fi

echo "[bench-disk] building static tstress (runs on any x86-64 Linux)"
gcc -O2 -static -o "$GUEST/tstress" "$GUEST/tstress.c" -lm
file "$GUEST/tstress" | grep -q statically || {
    echo "[bench-disk] WARNING: tstress is NOT statically linked — cross-arm runs may fail"
}

echo "[bench-disk] staging guest kit"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/bench-stage.XXXXXX")"
mkdir -p "$STAGE/guest" "$STAGE/results"
cp "$GUEST/tstress"        "$STAGE/guest/"
cp "$GUEST/scenario.sh"    "$STAGE/guest/"
cp "$GUEST/collector.sh"   "$STAGE/guest/"
cp "$GUEST/genproject.sh"  "$STAGE/guest/"

echo "[bench-disk] creating $BENCH_IMG ($SIZE sparse)"
rm -f "$BENCH_IMG"
truncate -s "$SIZE" "$BENCH_IMG"
mkfs.ext4 -q -L BENCHDISK -d "$STAGE" "$BENCH_IMG"

rm -rf "$STAGE"
echo "[bench-disk] done: $BENCH_IMG ($(du -sh "$BENCH_IMG" | cut -f1) used)"
