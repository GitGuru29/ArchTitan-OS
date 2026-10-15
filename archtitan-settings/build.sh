#!/usr/bin/env bash
# ArchTitan Settings — build & package into the airootfs tree.
#
# The app depends on the shared ArchTitan.TitanUI QML module at runtime.
# Build that first with ../titan-ui/build.sh (or the ISO build) so the module
# is installed under usr/lib/qt6/qml.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
AIROOT="${SCRIPT_DIR}/../airootfs"
BIN="${BUILD_DIR}/archtitan-settings"

echo "=== Building ArchTitan Settings ==="
mkdir -p "${BUILD_DIR}"
cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr
cmake --build "${BUILD_DIR}" -j"$(nproc)"

echo "=== Installing into airootfs ==="
install -Dm755 "${BIN}" "${AIROOT}/usr/bin/archtitan-settings"
install -Dm755 "${BIN}" "${AIROOT}/usr/local/bin/archtitan-settings"
echo "  -> ${AIROOT}/usr/bin/archtitan-settings"
echo "  -> ${AIROOT}/usr/local/bin/archtitan-settings"
echo "! Remember to run ../titan-ui/build.sh if the TitanUI module changed."
echo "✓ ArchTitan Settings built and installed into airootfs."
