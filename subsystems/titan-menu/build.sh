#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

echo "=== Building ArchTitan Menu (titan-menu) ==="
mkdir -p "${BUILD_DIR}"
cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON
cmake --build "${BUILD_DIR}" -j"$(nproc)"

if [[ -x "${BUILD_DIR}/titan-menu-tests" ]]; then
    echo "=== Running unit tests ==="
    QT_QPA_PLATFORM=offscreen "${BUILD_DIR}/titan-menu-tests"
fi

echo "=== Installing to airootfs ==="
mkdir -p "${SCRIPT_DIR}/../../airootfs/usr/local/bin"
cp -f "${BUILD_DIR}/titan-menu" "${SCRIPT_DIR}/../../airootfs/usr/local/bin/titan-menu"
chmod 0755 "${SCRIPT_DIR}/../../airootfs/usr/local/bin/titan-menu"

echo "✓ ArchTitan Menu successfully built and installed to airootfs."
