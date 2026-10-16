#!/usr/bin/env bash
# ArchTitan Titan Hardware Manager v3 — build & package.
#
# Builds the daemon (with the telemetry sidecar that feeds titan-sysmon) and
# installs it into the airootfs tree alongside the systemd unit + slice.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
AIRROOT="${SCRIPT_DIR}/../airootfs"

echo "=== Building THM v3 (titan-hwm-daemon) ==="
cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release
cmake --build "${BUILD_DIR}" -j"$(nproc)"

echo "=== Installing into airootfs ==="
mkdir -p "${AIRROOT}/usr/local/bin" "${AIRROOT}/usr/bin"
cp -f "${BUILD_DIR}/titan-hwm-daemon" "${AIRROOT}/usr/local/bin/titan-hwm-daemon"
cp -f "${BUILD_DIR}/titan-hwm-daemon" "${AIRROOT}/usr/bin/titan-hwm-daemon"
chmod 0755 "${AIRROOT}/usr/local/bin/titan-hwm-daemon" "${AIRROOT}/usr/bin/titan-hwm-daemon"

echo "✓ THM v3 built and installed to airootfs."
