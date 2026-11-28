#!/usr/bin/env bash
# ==============================================================================
# sync-to-pen.sh — Synchronize recent ArchTitan OS modifications to USB Pen Drive
# ==============================================================================
set -euo pipefail

PEN_ROOT="${1:-/run/media/msfvenom/ARCHTITAN}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "═══════════════════════════════════════════════════════════════"
echo "  ArchTitan OS — USB Pen Drive Synchronizer"
echo "═══════════════════════════════════════════════════════════════"
echo "[*] Target mount : $PEN_ROOT"
echo "[*] Source repo  : $REPO_DIR"

if [ ! -d "$PEN_ROOT/usr/local/bin" ]; then
    echo "[-] Error: ArchTitan root filesystem not found at $PEN_ROOT"
    echo "    Make sure the USB drive is mounted. Run:"
    echo "    udisksctl mount -b /dev/disk/by-label/ARCHTITAN"
    exit 1
fi

echo ""
echo "[1/3] Copying system binaries to $PEN_ROOT/usr/local/bin/..."
BINARIES=(
    "qs"
    "quickshell"
    "titan-shell"
    "titan-workspace-hud"
    "titan-adaptive-wallpaper"
    "archtitan-settings"
    "titan-set-wallpaper"
    "titan-wallpaper-restore"
    "titan-wallpaper-picker"
    "titan-media-hud"
    "titan-theme"
    "titan-tour"
    "titan-ai"
    "titan-ai-kitty"
    "titanfetch"
    "titan-cpu-bench"
    "titan-hwm"
    "titan-hwm-daemon"
)

for bin in "${BINARIES[@]}"; do
    src="$REPO_DIR/airootfs/usr/local/bin/$bin"
    dest="$PEN_ROOT/usr/local/bin/$bin"
    if [ -f "$src" ]; then
        echo "  -> Copying $bin"
        was_immutable=0
        if [ -e "$dest" ]; then
            if lsattr "$dest" 2>/dev/null | grep -q -- "-i-"; then
                was_immutable=1
                sudo chattr -i "$dest"
            fi
        fi
        sudo cp -f "$src" "$dest"
        sudo chmod 755 "$dest"
        if [ "$was_immutable" -eq 1 ]; then
            sudo chattr +i "$dest"
        fi
        # Also sync to /usr/bin if present on target
        if [ -d "$PEN_ROOT/usr/bin" ] && [ -e "$PEN_ROOT/usr/bin/$bin" ]; then
            sudo cp -f "$src" "$PEN_ROOT/usr/bin/$bin"
            sudo chmod 755 "$PEN_ROOT/usr/bin/$bin"
        fi
    else
        echo "  [!] Warning: $src not found, skipping"
    fi
done

echo ""
echo "[1b/3] Installing Quickshell runtime libraries & QML modules..."
if [ -d "$REPO_DIR/airootfs/usr/lib/qt6/qml/Quickshell" ]; then
    sudo mkdir -p "$PEN_ROOT/usr/lib/qt6/qml"
    sudo cp -rP "$REPO_DIR/airootfs/usr/lib/qt6/qml/Quickshell" "$PEN_ROOT/usr/lib/qt6/qml/"
    echo "  -> Installed Quickshell QML modules"
fi
if ls "$REPO_DIR/airootfs/usr/lib/libjemalloc.so"* 1>/dev/null 2>&1; then
    sudo cp -P "$REPO_DIR/airootfs/usr/lib/libjemalloc.so"* "$PEN_ROOT/usr/lib/" 2>/dev/null || true
fi
if ls "$REPO_DIR/airootfs/usr/lib/libcpptrace.so"* 1>/dev/null 2>&1; then
    sudo cp -P "$REPO_DIR/airootfs/usr/lib/libcpptrace.so"* "$PEN_ROOT/usr/lib/" 2>/dev/null || true
fi
if [ -d "$REPO_DIR/airootfs/usr/share/fonts/TTF/illogical-impulse-google-sans-flex" ]; then
    sudo mkdir -p "$PEN_ROOT/usr/share/fonts/TTF"
    sudo cp -r "$REPO_DIR/airootfs/usr/share/fonts/TTF/illogical-impulse-google-sans-flex" "$PEN_ROOT/usr/share/fonts/TTF/"
fi

echo ""
echo "[2/3] Installing systemd user services to $PEN_ROOT/etc/systemd/user/..."
sudo mkdir -p "$PEN_ROOT/etc/systemd/user"
sudo cp -f "$REPO_DIR/airootfs/etc/systemd/user/titan-adaptive-wallpaper.service" "$PEN_ROOT/etc/systemd/user/"
sudo chmod 644 "$PEN_ROOT/etc/systemd/user/titan-adaptive-wallpaper.service"

echo ""
echo "[3/3] Configuring user environment for archtitan..."
TARGET_USER_HOME="$PEN_ROOT/home/archtitan"
if [ -d "$TARGET_USER_HOME" ]; then
    # Ensure config & user systemd dirs exist
    mkdir -p "$TARGET_USER_HOME/.config/archtitan"
    mkdir -p "$TARGET_USER_HOME/.config/systemd/user/default.target.wants"

    # Copy service to user config directory and enable it
    cp -f "$REPO_DIR/airootfs/etc/systemd/user/titan-adaptive-wallpaper.service" "$TARGET_USER_HOME/.config/systemd/user/"
    ln -sf "../titan-adaptive-wallpaper.service" "$TARGET_USER_HOME/.config/systemd/user/default.target.wants/titan-adaptive-wallpaper.service"

    # Setup initial adaptive-wallpaper.json if not present
    if [ ! -f "$TARGET_USER_HOME/.config/archtitan/adaptive-wallpaper.json" ]; then
        ACTIVE_WP=$(cat "$TARGET_USER_HOME/.config/archtitan/wallpaper" 2>/dev/null | head -n 1 || echo "")
        if [ -z "$ACTIVE_WP" ] || [ ! -f "$ACTIVE_WP" ] || [[ "$ACTIVE_WP" == *"/archtitan/wallpapers/"* ]]; then
            ACTIVE_WP="/usr/share/backgrounds/archtitan/wallpaper.png"
        fi
        cat <<EOF > "$TARGET_USER_HOME/.config/archtitan/adaptive-wallpaper.json"
{
  "enabled": true,
  "autoSync": true,
  "intensity": 0.7,
  "originalWallpaper": "${ACTIVE_WP}",
  "manualPaletteOverride": ""
}
EOF
    fi

    # Sync Hyprland configs if present
    if [ -d "$TARGET_USER_HOME/.config/hypr" ]; then
        cp -f "$REPO_DIR/airootfs/home/archtitan/.config/hypr/hyprland.conf" "$TARGET_USER_HOME/.config/hypr/" 2>/dev/null || true
        cp -f "$REPO_DIR/airootfs/home/archtitan/.config/hypr/hyprland.lua" "$TARGET_USER_HOME/.config/hypr/" 2>/dev/null || true
    fi

    # Sync Quickshell and Illogical Impulse configs
    if [ -d "$REPO_DIR/airootfs/home/archtitan/.config/quickshell" ]; then
        mkdir -p "$TARGET_USER_HOME/.config/quickshell"
        cp -rP "$REPO_DIR/airootfs/home/archtitan/.config/quickshell/"* "$TARGET_USER_HOME/.config/quickshell/" 2>/dev/null || true
        echo "  -> Synced quickshell config to user"
    fi
    if [ -d "$REPO_DIR/airootfs/home/archtitan/.config/illogical-impulse" ]; then
        mkdir -p "$TARGET_USER_HOME/.config/illogical-impulse"
        cp -rP "$REPO_DIR/airootfs/home/archtitan/.config/illogical-impulse/"* "$TARGET_USER_HOME/.config/illogical-impulse/" 2>/dev/null || true
        echo "  -> Synced illogical-impulse config to user"
    fi

    # Fix ownership to 1000:1000
    sudo chown -R 1000:1000 "$TARGET_USER_HOME/.config" 2>/dev/null || true
    echo "  -> User config and systemd auto-start configured."
fi

# Sync /etc/skel configs
if [ -d "$PEN_ROOT/etc/skel" ]; then
    mkdir -p "$PEN_ROOT/etc/skel/.config/hypr" "$PEN_ROOT/etc/skel/.config/quickshell" "$PEN_ROOT/etc/skel/.config/illogical-impulse"
    sudo cp -f "$REPO_DIR/airootfs/etc/skel/.config/hypr/hyprland.conf" "$PEN_ROOT/etc/skel/.config/hypr/" 2>/dev/null || true
    sudo cp -f "$REPO_DIR/airootfs/etc/skel/.config/hypr/hyprland.lua" "$PEN_ROOT/etc/skel/.config/hypr/" 2>/dev/null || true
    sudo cp -rP "$REPO_DIR/airootfs/etc/skel/.config/quickshell/"* "$PEN_ROOT/etc/skel/.config/quickshell/" 2>/dev/null || true
    sudo cp -rP "$REPO_DIR/airootfs/etc/skel/.config/illogical-impulse/"* "$PEN_ROOT/etc/skel/.config/illogical-impulse/" 2>/dev/null || true
fi

echo ""
echo "[*] Flushing filesystem buffers to disk..."
sync

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  [✓] All recent ArchTitan modifications synced successfully!"
echo "═══════════════════════════════════════════════════════════════"
