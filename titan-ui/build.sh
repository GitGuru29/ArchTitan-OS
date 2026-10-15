#!/usr/bin/env bash
# ArchTitan TitanUI — build & package the ArchTitan.TitanUI QML module.
#
# Builds the shared design-system module and installs it into the airootfs tree
# at the path Qt scans for QML import modules, so any bundled app can
# `import ArchTitan.TitanUI` at runtime (and the ISO ships it).
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
AIROOT="${SCRIPT_DIR}/../airootfs"
QML_DIR="${AIROOT}/usr/lib/qt6/qml/ArchTitan/TitanUI"

echo "=== Building ArchTitan.TitanUI (QML module) ==="
mkdir -p "${BUILD_DIR}"
cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_INSTALL_LIBDIR=lib
cmake --build "${BUILD_DIR}" -j"$(nproc)"

echo "=== Installing into airootfs ==="
mkdir -p "${QML_DIR}" "${AIROOT}/usr/lib"

# Backing library (C++ ThemeBackend + compiled-in QML resources).
cp -f "${BUILD_DIR}/libTitanUI.so" "${AIROOT}/usr/lib/libTitanUI.so"

# QML plugin + metadata + source QML live in the QML import tree.
cp -f "${BUILD_DIR}/qml/ArchTitan/TitanUI/libTitanUIplugin.so" "${QML_DIR}/"
cp -f "${BUILD_DIR}/qml/ArchTitan/TitanUI/qmldir"             "${QML_DIR}/"
cp -f "${BUILD_DIR}/qml/ArchTitan/TitanUI/TitanUI.qmltypes"   "${QML_DIR}/"
rm -rf "${QML_DIR}/qml"
cp -r "${BUILD_DIR}/qml/ArchTitan/TitanUI/qml" "${QML_DIR}/qml"

# Shared C++ palette header for Qt Widgets apps (titanfetch, titanbrowser, …).
mkdir -p "${AIROOT}/usr/include/archtitan"
cp -f "${SCRIPT_DIR}/include/TitanPalette.h" "${AIROOT}/usr/include/archtitan/TitanPalette.h"

echo "  -> ${QML_DIR}"
echo "✓ ArchTitan.TitanUI built and installed into airootfs."
