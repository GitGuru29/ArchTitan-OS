#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

echo "==> Configuring titan-shell..."
cmake -DCMAKE_BUILD_TYPE=Release ..

echo "==> Compiling titan-shell..."
cmake --build . -- -j$(nproc)

echo "==> Installing to airootfs..."
mkdir -p "${REPO_ROOT}/airootfs/usr/local/bin"
cp -f titan-shell "${REPO_ROOT}/airootfs/usr/local/bin/titan-shell"
chmod +x "${REPO_ROOT}/airootfs/usr/local/bin/titan-shell"

echo "✅ titan-shell built and installed to airootfs/usr/local/bin/titan-shell"
