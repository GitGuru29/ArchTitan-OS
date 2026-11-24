#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

echo "=== Building ArchTitan Quick Settings & Notification Center ==="
touch "${SCRIPT_DIR}/resources.qrc"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"
cmake ..
make -j"$(nproc)"

echo "=== Installing to build directory ==="
# Note: In unified titan-shell architecture, airootfs/usr/local/bin/titan-quicksettings
# is a wrapper forwarding to titan-shell. Do not overwrite with the standalone binary.
echo "✓ Standalone Titan Quick Settings available at ${BUILD_DIR}/titan-quicksettings"
