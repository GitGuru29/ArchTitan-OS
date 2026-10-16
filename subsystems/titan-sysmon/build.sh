#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

echo "=== Building ArchTitan System Monitor (titan-sysmon) ==="
mkdir -p "${BUILD_DIR}"
cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON
cmake --build "${BUILD_DIR}" -j"$(nproc)"

echo "=== Installing to airootfs ==="
mkdir -p "${SCRIPT_DIR}/../../airootfs/usr/local/bin"
cp -f "${BUILD_DIR}/titan-sysmon" "${SCRIPT_DIR}/../../airootfs/usr/local/bin/titan-sysmon"
chmod 0755 "${SCRIPT_DIR}/../../airootfs/usr/local/bin/titan-sysmon"

echo "✓ Titan System Monitor successfully built and installed to airootfs."
