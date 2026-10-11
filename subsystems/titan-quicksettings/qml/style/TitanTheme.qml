pragma Singleton
import QtQuick

/**
 * TitanTheme — ArchTitan design tokens with Samsung One UI 9.0 styling.
 *
 * Merges the clean Catppuccin Mocha contrast with Samsung One UI 9.0
 * bento-box geometry, continuous squircles, and frosted glass depth.
 */
QtObject {
    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    // ── One UI 9.0 Surfaces & Acrylic Glass ─────────────────────────────────
    readonly property color bgWindow:          "#F20B0E14"   // ~95% frosted dark backdrop
    readonly property color bgSurface:         "#161A26"     // raised bento container
    readonly property color bgSurfaceAlt:      "#1D2232"     // elevated squircle tile
    readonly property color bgInset:           "#0E121C"     // recessed track / inset
    readonly property color bgHover:           "#262D42"     // hover state
    readonly property color bgPressed:         "#191E2C"     // pressed state
    readonly property color bgActive:          "#2B7FFF"     // One UI vibrant active blue

    readonly property color bgOneUICard:       "#1B2030"     // One UI modular bento card
    readonly property color bgOneUICardAlt:    "#23293D"     // slightly brighter subcard
    readonly property color bgOneUITrack:      "#222838"     // pill slider inactive track
    readonly property color bgOneUIPill:       "#2B3248"     // interactive capsule pill

    // ── Borders ─────────────────────────────────────────────────────────────
    readonly property color borderSubtle:      "#18FFFFFF"   // 9% white hairline
    readonly property color borderHover:       "#30FFFFFF"   // 19% white
    readonly property color borderActive:      "#702B7FFF"   // One UI accent glow
    readonly property color borderGlass:       "#14FFFFFF"   // 8% white glass highlight
    readonly property color borderOneUIGlass:  "#17FFFFFF"

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
    readonly property color textPrimary:       "#FFFFFF"     // high-contrast primary
    readonly property color textSecondary:     "#CBD5E1"     // secondary details
    readonly property color textMuted:         "#94A3B8"     // descriptions
    readonly property color textSubtle:        "#64748B"     // timestamps & captions
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