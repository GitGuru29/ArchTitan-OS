pragma Singleton
import QtQuick

/**
 * TitanTheme — ArchTitan design tokens with Samsung One UI 9.0 styling.
 *
 * Merges the clean Catppuccin Mocha contrast with Samsung One UI 9.0
 * bento-box geometry, continuous squircles, and frosted glass depth.
 */
QtObject {
    property bool isDark: true

    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    // ── One UI 9.0 Adaptive Surfaces ───────────────────────────────────────
    readonly property color bgWindow:          isDark ? "#0B0E14" : "#F4F6F9"     // solid opaque backdrop
    readonly property color bgSurface:         isDark ? "#161A26" : "#E8ECF2"     // raised bento container
    readonly property color bgSurfaceAlt:      isDark ? "#1D2232" : "#DFE4EC"     // elevated squircle tile
    readonly property color bgInset:           isDark ? "#0E121C" : "#E2E8F0"     // recessed track / inset
    readonly property color bgHover:           isDark ? "#262D42" : "#DCE3EE"     // hover state
    readonly property color bgPressed:         isDark ? "#191E2C" : "#CBD5E1"     // pressed state
    readonly property color bgActive:          "#2B7FFF"                          // One UI vibrant active blue

    readonly property color bgOneUICard:       isDark ? "#1B2030" : "#FFFFFF"     // One UI modular bento card
    readonly property color bgOneUICardAlt:    isDark ? "#23293D" : "#F1F5F9"     // slightly brighter subcard
    readonly property color bgOneUITrack:      isDark ? "#222838" : "#E2E8F0"     // pill slider inactive track
    readonly property color bgOneUIPill:       isDark ? "#2B3248" : "#EDF2F7"     // interactive capsule pill

    // ── Borders ─────────────────────────────────────────────────────────────
    readonly property color borderSubtle:      isDark ? "#18FFFFFF" : "#18000000" // hairline
    readonly property color borderHover:       isDark ? "#30FFFFFF" : "#30000000"
    readonly property color borderActive:      "#702B7FFF"                        // One UI accent glow
    readonly property color borderGlass:       isDark ? "#14FFFFFF" : "#14000000" // glass highlight
    readonly property color borderOneUIGlass:  isDark ? "#17FFFFFF" : "#17000000"

    // ── Accents & Indicators ────────────────────────────────────────────────
    readonly property color accent:            "#2B7FFF"     // One UI 9 Electric Blue
    readonly property color accentBlue:        "#2B7FFF"
    readonly property color accentText:        "#FFFFFF"     // white text on vibrant pill
    readonly property color cyan:              "#38BDF8"     // electric cyan
    readonly property color green:             "#10B981"     // One UI emerald active
    readonly property color red:               "#EF4444"     // One UI crimson alert
    readonly property color yellow:            "#F59E0B"     // One UI amber
    readonly property color teal:              "#14B8A6"
    readonly property color lavender:          "#818CF8"
    readonly property color peach:             "#F97316"     // Night light warm glow

    // ── Text & Typography ───────────────────────────────────────────────────
    readonly property color textPrimary:       isDark ? "#FFFFFF" : "#0F172A"     // high-contrast primary
    readonly property color textSecondary:     isDark ? "#CBD5E1" : "#334155"     // secondary details
    readonly property color textMuted:         isDark ? "#94A3B8" : "#64748B"     // descriptions
    readonly property color textSubtle:        isDark ? "#64748B" : "#94A3B8"     // timestamps & captions
    readonly property color textOnAccent:      "#FFFFFF"

    // ── Type scale ──────────────────────────────────────────────────────────
    readonly property int sizeClock:    32
    readonly property int sizeDisplay:  18
    readonly property int sizeTitle:    14
    readonly property int sizeBody:     12
    readonly property int sizeSmall:    11
    readonly property int sizeCaption:  9

    // ── One UI Geometry & Radii ─────────────────────────────────────────────
    readonly property int radiusWindow:    28    // main overlay rounded corner
    readonly property int radiusBento:     24    // modular bento cards
    readonly property int radiusCard:      20    // notification & inner cards
    readonly property int radiusControl:   16    // small buttons
    readonly property int radiusSlider:    26    // thick pill slider
    readonly property int radiusCircle:    26    // circular quick toggle buttons (52px)
    readonly property int radiusPill:      24    // segmented pill
    readonly property int radiusIcon:      20

    readonly property int spacing:         10
    readonly property int panelPadding:    14
}