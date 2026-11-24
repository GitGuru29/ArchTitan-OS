#!/usr/bin/env bash
# Build and install TITAN AI on the current (host) Arch system.
# This is separate from build.sh, which stages files into the ISO airootfs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(mktemp -d /tmp/titan-ai-host-build.XXXXXX)"
trap 'rm -rf "${BUILD_DIR}"' EXIT

echo "=== Building TITAN AI C++ engine ==="
cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "${BUILD_DIR}" --parallel >/dev/null

# Prefer /usr/local, fall back to ~/.local when sudo needs a password.
if [[ -n "${TITAN_AI_PREFIX:-}" ]]; then
    PREFIX="${TITAN_AI_PREFIX}"
    SUDO=""
    if [[ ! -w "${PREFIX}/bin" ]] && [[ "$(id -u)" -ne 0 ]]; then SUDO="sudo"; fi
elif [[ "$(id -u)" -eq 0 || -w /usr/local/bin ]]; then
    PREFIX="/usr/local"
    SUDO=""
elif sudo -n true 2>/dev/null; then
    PREFIX="/usr/local"
    SUDO="sudo"
else
    PREFIX="${HOME}/.local"
    SUDO=""
    echo "! sudo unavailable; installing to ${PREFIX}/bin instead"
fi
BIN_DIR="${PREFIX}/bin"
${SUDO} install -d -m 0755 "${BIN_DIR}"
${SUDO} install -m 0755 "${BUILD_DIR}/titan-ai" "${BIN_DIR}/titan-ai"
${SUDO} install -m 0755 "${SCRIPT_DIR}/kitty/titan-ai-kitty.sh" "${BIN_DIR}/titan-ai-kitty"
KITTY_BIN="${BIN_DIR}/titan-ai-kitty"

CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
install -d -m 0700 "${CONFIG_HOME}/archtitan"
if [[ ! -e "${CONFIG_HOME}/archtitan/titan-ai.example.json" ]]; then
    install -m 0644 "${SCRIPT_DIR}/configs/titan-ai.example.json" \
        "${CONFIG_HOME}/archtitan/titan-ai.example.json"
fi

install -d -m 0755 "${CONFIG_HOME}/fish/completions"
install -m 0644 "${SCRIPT_DIR}/configs/titan-ai.fish" \
    "${CONFIG_HOME}/fish/completions/titan-ai.fish"
if [[ -f "${CONFIG_HOME}/fish/config.fish" ]] \
    && ! grep -q "alias ai='titan-ai'" "${CONFIG_HOME}/fish/config.fish"; then
    printf '\n# TITAN AI shortcut\nalias ai=%stitan-ai%s\n' "'" "'" \
        >> "${CONFIG_HOME}/fish/config.fish"
fi
if [[ "${PREFIX}" == "${HOME}"* ]] \
    && [[ -f "${CONFIG_HOME}/fish/config.fish" ]] \
    && ! grep -q 'fish_add_path.*\.local/bin' "${CONFIG_HOME}/fish/config.fish"; then
    printf '\nfish_add_path %s/.local/bin\n' "${HOME}" >> "${CONFIG_HOME}/fish/config.fish"
fi

install -d -m 0755 "${CONFIG_HOME}/kitty/conf.d"
KITTY_FRAGMENT="${CONFIG_HOME}/kitty/conf.d/titan-ai.conf"
install -m 0644 "${SCRIPT_DIR}/configs/kitty-titan-ai.conf" "${KITTY_FRAGMENT}"
sed -i "s|/usr/local/bin/titan-ai-kitty|${KITTY_BIN}|g" "${KITTY_FRAGMENT}"
if [[ "${BIN_DIR}" != "/usr/local/bin" ]]; then
    # Make the shortcut find the engine even if Kitty's PATH differs from the shell's.
    sed -i "s|launch --type=window|launch --env TITAN_AI_ENGINE=${BIN_DIR}/titan-ai --type=window|" \
        "${KITTY_FRAGMENT}"
fi
KITTY_CONF="${CONFIG_HOME}/kitty/kitty.conf"
if [[ ! -f "${KITTY_CONF}" ]]; then
    printf '# ArchTitan Kitty configuration\ninclude conf.d/*.conf\n' > "${KITTY_CONF}"
elif ! grep -q 'include conf\.d/\*\.conf' "${KITTY_CONF}"; then
    printf '\n# TITAN AI keybindings (Ctrl+Shift+S opens a search window)\ninclude conf.d/*.conf\n' \
        >> "${KITTY_CONF}"
fi

echo "✓ titan-ai installed to ${BIN_DIR}/titan-ai"
echo "✓ Kitty shortcut: Ctrl+Shift+S (restart Kitty to load it)"
echo "  Configure keys with: titan-ai setup   or   titan-ai auth google"
