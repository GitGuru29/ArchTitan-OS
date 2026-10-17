#!/usr/bin/env bash
# ArchTitan Titan Hardware Manager v3 — build & package.
#
# Builds the daemon (with the telemetry sidecar that feeds titan-sysmon) and the
# CLI, then installs them into the airootfs tree alongside the systemd unit.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
AIRROOT="${SCRIPT_DIR}/../airootfs"

echo "=== Building THM v3 (titan-hwm-daemon + titan-hwm) ==="
cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release
cmake --build "${BUILD_DIR}" -j"$(nproc)"

TITANFETCH_DIR="${SCRIPT_DIR}/../titanfetch-src"
if [[ -f "${TITANFETCH_DIR}/CMakeLists.txt" ]]; then
    echo "=== Building titanfetch (THM v3 telemetry consumer) ==="
    cmake -S "${TITANFETCH_DIR}" -B "${TITANFETCH_DIR}/build" -DCMAKE_BUILD_TYPE=Release
    cmake --build "${TITANFETCH_DIR}/build" -j"$(nproc)"
fi

echo "=== Installing into airootfs ==="
mkdir -p "${AIRROOT}/usr/local/bin" "${AIRROOT}/usr/bin"
cp -f "${BUILD_DIR}/titan-hwm-daemon" "${AIRROOT}/usr/local/bin/titan-hwm-daemon"
cp -f "${BUILD_DIR}/titan-hwm-daemon" "${AIRROOT}/usr/bin/titan-hwm-daemon"
cp -f "${BUILD_DIR}/titan-hwm"        "${AIRROOT}/usr/local/bin/titan-hwm"
chmod 0755 "${AIRROOT}/usr/local/bin/titan-hwm-daemon" \
           "${AIRROOT}/usr/bin/titan-hwm-daemon" \
           "${AIRROOT}/usr/local/bin/titan-hwm"

if [[ -x "${TITANFETCH_DIR}/build/titanfetch" ]]; then
    cp -f "${TITANFETCH_DIR}/build/titanfetch" "${AIRROOT}/usr/local/bin/titanfetch"
    cp -f "${TITANFETCH_DIR}/build/titanfetch" "${AIRROOT}/usr/bin/titanfetch"
    chmod 0755 "${AIRROOT}/usr/local/bin/titanfetch" "${AIRROOT}/usr/bin/titanfetch"
fi

echo "✓ THM v3 built and installed to airootfs."
