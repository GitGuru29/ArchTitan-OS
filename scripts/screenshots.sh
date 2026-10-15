#!/usr/bin/env bash
# ArchTitan TitanUI screenshot harness.
#
# Renders the design-system surfaces to PNGs in ./screenshots using the Qt QML
# runtime with the offscreen platform + software renderer (no GPU/Wayland needed),
# so it works in CI and over SSH. Each surface instantiates a real component tree,
# waits for it to render, then grabs the window via Item.grabToImage().
#
# Usage:  scripts/screenshots.sh
# Env:    QML_BIN=/path/to/qml   (default: /usr/lib/qt6/bin/qml)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUT="${ROOT}/screenshots"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

QML_BIN="${QML_BIN:-/usr/lib/qt6/bin/qml}"
IMPORT_PATH="${ROOT}/airootfs/usr/lib/qt6/qml:${ROOT}/titan-ui/build/qml"

if [[ ! -x "${QML_BIN}" ]]; then
    echo "✗ Qt QML runtime not found at ${QML_BIN} (set QML_BIN=...)" >&2
    exit 127
fi

mkdir -p "${OUT}"
fail=0

render() {
    local name="$1" out="$2"
    local qmlfile="${TMP}/${name}.qml"
    cat > "${qmlfile}"
    QML_IMPORT_PATH="${IMPORT_PATH}" \
    QT_QPA_PLATFORM=offscreen \
    QT_QUICK_BACKEND=software \
    QT_FORCE_STDERR_LOGGING=1 \
        timeout 20 "${QML_BIN}" "${qmlfile}" 2>&1 | sed "s/^/[${name}] /" || true
    if [[ -f "${out}" ]]; then
        echo "✓ ${name} -> ${out#${ROOT}/}"
    else
        echo "✗ ${name}: no screenshot written" >&2
        fail=1
    fi
}

# 1. Full component gallery (all primitives + states).
render gallery "${OUT}/gallery.png" <<QML
import QtQuick
import QtQuick.Window
import ArchTitan.TitanUI

Window {
    width: 900; height: 820; visible: true
    color: TitanTheme.bg0

    TitanGalleryBody { anchors.fill: parent }

    Timer {
        interval: 700; running: true
        onTriggered: contentItem.grabToImage(function(res) {
            res.saveToFile("${OUT}/gallery.png")
            Qt.quit()
        })
    }
}
QML

# 2. Loading / empty / error states on the deepest surface.
render states "${OUT}/states.png" <<QML
import QtQuick
import QtQuick.Window
import ArchTitan.TitanUI

Window {
    width: 640; height: 300; visible: true
    color: TitanTheme.bg0

    Row {
        anchors.centerIn: parent
        spacing: 32

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            TitanSpinner { size: 32 }
            TitanSkeleton { width: 180; height: 14 }
            TitanSkeleton { width: 120; height: 14 }
        }
        TitanEmptyState {
            width: 220
            title: "No notifications"
            description: "You're all caught up."
        }
        TitanErrorState {
            width: 220
            description: "Check your connection and retry."
        }
    }

    Timer {
        interval: 700; running: true
        onTriggered: contentItem.grabToImage(function(res) {
            res.saveToFile("${OUT}/states.png")
            Qt.quit()
        })
    }
}
QML

exit "${fail}"
