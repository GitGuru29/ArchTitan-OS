#!/usr/bin/env bash
# titan-cycle-power
# Cycles: Power Saver -> Balanced -> Performance -> Power Saver
# Talks to power-profiles-daemon via D-Bus Properties (supports both net.hadess.PowerProfiles
# and org.freedesktop.UPower.PowerProfiles) with powerprofilesctl fallback.

CURRENT=$(busctl get-property net.hadess.PowerProfiles \
    /net/hadess/PowerProfiles \
    net.hadess.PowerProfiles \
    ActiveProfile 2>/dev/null | awk -F'"' '{print $2}')

if [[ -z "$CURRENT" ]]; then
    CURRENT=$(busctl get-property org.freedesktop.UPower.PowerProfiles \
        /org/freedesktop/UPower/PowerProfiles \
        org.freedesktop.UPower.PowerProfiles \
        ActiveProfile 2>/dev/null | awk -F'"' '{print $2}')
fi

if [[ -z "$CURRENT" ]] && command -v powerprofilesctl >/dev/null 2>&1; then
    CURRENT=$(powerprofilesctl get 2>/dev/null)
fi

case "$CURRENT" in
    "power-saver")
        NEXT="balanced"
        LABEL="Balanced"
        ICON="power-profile-balanced"
        ;;
    "balanced")
        NEXT="performance"
        LABEL="Performance"
        ICON="power-profile-performance"
        ;;
    *)
        NEXT="power-saver"
        LABEL="Power Saver"
        ICON="power-profile-power-saver"
        ;;
esac

# Try D-Bus net.hadess.PowerProfiles
busctl set-property net.hadess.PowerProfiles \
    /net/hadess/PowerProfiles \
    net.hadess.PowerProfiles \
    ActiveProfile s "$NEXT" 2>/dev/null || \
busctl set-property org.freedesktop.UPower.PowerProfiles \
    /org/freedesktop/UPower/PowerProfiles \
    org.freedesktop.UPower.PowerProfiles \
    ActiveProfile s "$NEXT" 2>/dev/null || \
powerprofilesctl set "$NEXT" 2>/dev/null || true

notify-send -a "Power Manager" -i "$ICON" "Power Profile" "Switched to $LABEL" -t 2000 2>/dev/null || true
