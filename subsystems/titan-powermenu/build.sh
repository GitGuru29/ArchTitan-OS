#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=== Building ArchTitan Power Menu (titan-powermenu) ==="

mkdir -p "${SCRIPT_DIR}/build"
cd "${SCRIPT_DIR}/build"

cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build . -j"$(nproc)"

echo "=== Installing to airootfs and host ==="
mkdir -p "${WORKSPACE_ROOT}/airootfs/usr/local/bin"
mkdir -p "${WORKSPACE_ROOT}/airootfs/usr/bin"
mkdir -p "${HOME}/.local/bin"

cp titan-powermenu "${WORKSPACE_ROOT}/airootfs/usr/local/bin/titan-powermenu"
cp titan-powermenu "${WORKSPACE_ROOT}/airootfs/usr/bin/titan-powermenu"
chmod +x "${WORKSPACE_ROOT}/airootfs/usr/local/bin/titan-powermenu"
chmod +x "${WORKSPACE_ROOT}/airootfs/usr/bin/titan-powermenu"

if [ -f "${SCRIPT_DIR}/titan-powermenu-host.sh" ]; then
    cp "${SCRIPT_DIR}/titan-powermenu-host.sh" "${HOME}/.local/bin/titan-powermenu"
    chmod +x "${HOME}/.local/bin/titan-powermenu"
else
    cp titan-powermenu "${HOME}/.local/bin/titan-powermenu"
    chmod +x "${HOME}/.local/bin/titan-powermenu"
fi

echo "✓ ArchTitan Power Menu successfully built and installed."
