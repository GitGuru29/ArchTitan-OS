#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

echo "=== Building ArchTitan Hot-Zone Daemon ==="
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"
cmake ..
cmake --build . -j"$(nproc)"

echo "=== Installing to airootfs ==="
DEST_DIR="${SCRIPT_DIR}/../../airootfs/usr/local/bin"
mkdir -p "${DEST_DIR}"
for bin in titan-hotzones titan-zone-osd; do
    cp -f "${BUILD_DIR}/${bin}" "${DEST_DIR}/${bin}"
    chmod 0755 "${DEST_DIR}/${bin}"
done

echo "=== Installing default config ==="
CFG_DIR="${SCRIPT_DIR}/../../airootfs/etc/archtitan"
mkdir -p "${CFG_DIR}"
cp -f "${SCRIPT_DIR}/configs/hotzones.toml" "${CFG_DIR}/hotzones.toml"

echo "✓ Titan Hot-Zone daemon built and installed to airootfs."
