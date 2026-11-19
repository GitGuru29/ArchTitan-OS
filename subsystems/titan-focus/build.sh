#!/usr/bin/env bash
# ArchTitan OS — TitanFocus build, test & install script
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
AIROOT="${SCRIPT_DIR}/../../airootfs"

echo "=== Building TitanFocus ==="
mkdir -p "${BUILD_DIR}"
cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release
cmake --build "${BUILD_DIR}" -j"$(nproc)"

echo "=== Running Headless Unit Tests ==="
ctest --test-dir "${BUILD_DIR}" --output-on-failure

echo "=== Installing into airootfs ==="
install -Dm755 "${BUILD_DIR}/titan-focus" "${AIROOT}/usr/local/bin/titan-focus"

for cfg_root in \
    "${AIROOT}/etc/skel/.config/titan-focus" \
    "${AIROOT}/home/archtitan/.config/titan-focus" \
    "${AIROOT}/root/.config/titan-focus"; do
    install -Dm644 "${SCRIPT_DIR}/configs/focus.toml" "${cfg_root}/focus.toml"
done

echo "  -> ${AIROOT}/usr/local/bin/titan-focus"
echo "✓ TitanFocus built, tested, and installed into airootfs."
