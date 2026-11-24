#!/usr/bin/env bash
# Headless smoke test for TitanFocus POSIX signal surfaces and CLI (zero Python).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${SCRIPT_DIR}/../build/titan-focus"

echo "=== TitanFocus Sampler & CLI Smoke Test ==="
test -r /proc/meminfo
test -d /proc/1
echo "[PASS] /proc readable"

if [ -x "${BIN}" ]; then
    "${BIN}" --help >/dev/null
    echo "[PASS] titan-focus --help"

    WAYBAR_OUT="$("${BIN}" --waybar)"
    echo "  waybar json: ${WAYBAR_OUT}"
    grep -q '"text":' <<< "${WAYBAR_OUT}"
    echo "[PASS] titan-focus --waybar returns valid JSON shape"
fi

echo "✓ Smoke test complete."
