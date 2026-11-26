#!/usr/bin/env bash
# ArchTitan Titan Quick Settings - Test on Host Machine
# Run this single script to test the overlay on your host

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"

# Set up runtime library and QML import paths for host execution
export QML_IMPORT_PATH="$REPO_DIR/airootfs/usr/lib/qt6/qml:${QML_IMPORT_PATH:-}"
export QML2_IMPORT_PATH="$REPO_DIR/airootfs/usr/lib/qt6/qml:${QML2_IMPORT_PATH:-}"
export LD_LIBRARY_PATH="$REPO_DIR/airootfs/usr/lib:$REPO_DIR/titan-ui/build:${LD_LIBRARY_PATH:-}"

# Use the freshly built binary
BIN="$BUILD_DIR/titan-quicksettings"

echo "============================================================"
echo "  ArchTitan Titan Quick Settings - Host Test"
echo "============================================================"

# Check environment
echo "[*] Environment check:"
echo "  WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-not set}"
echo "  XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-not set}"
echo "  XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-not set}"
echo ""

# Verify binary exists
if [ ! -f "$BIN" ]; then
    echo "[!] Binary not found: $BIN"
    echo "[!] Building first..."
    bash "$SCRIPT_DIR/build.sh"
    echo ""
fi

# Check if running under Wayland
if [ "$XDG_SESSION_TYPE" != "wayland" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    echo "[!] Warning: Not running under Wayland"
    echo "[!] This app requires Wayland (Hyprland/Wayfire/Sway)"
    echo ""
fi

# Kill any existing instance
pkill -x titan-quicksettings 2>/dev/null || true
sleep 0.3

echo "[*] Starting daemon..."
QT_QPA_PLATFORM=wayland "$BIN" --daemon &
DAEMON_PID=$!

sleep 0.8

echo "[*] Showing quick settings overlay..."
QT_QPA_PLATFORM=wayland "$BIN" --toggle

echo ""
echo "============================================================"
echo "  ✓ Quick Settings is now visible"
echo "============================================================"
echo ""
echo "Controls:"
echo "  - Press ESC or click outside to close"
echo "  - Use Super+N to toggle (if bound in Hyprland)"
echo "  - Ctrl+C to stop this test session"
echo ""
echo "To bind Super+N temporarily in Hyprland:"
echo "  echo 'bind = SUPER, N, exec, $BIN --toggle' >> ~/.config/hypr/hyprland.conf"
echo "  hyprctl reload"
echo ""

# Wait for user to stop
trap "echo; echo '[*] Stopping...'; kill $DAEMON_PID 2>/dev/null; pkill -x titan-quicksettings 2>/dev/null; exit 0" INT TERM

wait $DAEMON_PID 2>/dev/null || true
