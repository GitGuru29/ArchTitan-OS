#!/usr/bin/env bash
# Build the C++ TITAN AI engine and install it (plus Kitty integration)
# into the airootfs used by mkarchiso.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${SCRIPT_DIR}/../.."
AIROOTFS="${ROOT}/airootfs"
BUILD_DIR="$(mktemp -d /tmp/titan-ai-build.XXXXXX)"
trap 'rm -rf "${BUILD_DIR}"' EXIT

echo "=== Building TITAN AI C++ engine ==="
cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "${BUILD_DIR}" --parallel >/dev/null

echo "=== Installing TITAN AI into airootfs ==="
install -d -m 0755 "${AIROOTFS}/usr/local/bin"
install -m 0755 "${BUILD_DIR}/titan-ai" "${AIROOTFS}/usr/local/bin/titan-ai"
install -m 0755 "${SCRIPT_DIR}/kitty/titan-ai-kitty.sh" "${AIROOTFS}/usr/local/bin/titan-ai-kitty"

# Example config, fish completions and the Kitty keybinding fragment.
for home in "${AIROOTFS}/etc/skel" "${AIROOTFS}/home/archtitan"; do
    install -d -m 0755 "${home}/.config/archtitan"
    install -d -m 0755 "${home}/.config/fish/completions"
    install -d -m 0755 "${home}/.config/kitty/conf.d"
    install -m 0644 "${SCRIPT_DIR}/configs/titan-ai.example.json" \
        "${home}/.config/archtitan/titan-ai.example.json"
    install -m 0644 "${SCRIPT_DIR}/configs/titan-ai.fish" \
        "${home}/.config/fish/completions/titan-ai.fish"
    install -m 0644 "${SCRIPT_DIR}/configs/kitty-titan-ai.conf" \
        "${home}/.config/kitty/conf.d/titan-ai.conf"
done

echo "✓ titan-ai installed to ${AIROOTFS}/usr/local/bin/titan-ai"
echo "  Kitty shortcut: Ctrl+Shift+S (search window)"
echo "  Google sign-in guide: titan-ai docs (works on installed systems)"
echo "  Tests: python3 -m unittest discover -s subsystems/titan-ai/tests -v"
