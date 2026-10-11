pragma Singleton
import QtQuick

/**
 * TitanTheme — ArchTitan design tokens.
 *
 * Palette is Catppuccin Mocha, tuned to match the OS-wide surface language
 * used by Waybar (rgba(13,14,21) bar), the SwayNC notification center and the
 * Titan media HUD.  All typography uses JetBrainsMono Nerd Font, the single
 * icon+text family shipped on the ISO, so UI glyphs never fall back to a
 * mismatched font.
 */
QtObject {
    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    // ── Surfaces ────────────────────────────────────────────────────────────
    readonly property color bgWindow:      "#F00B0E13"   // drawer body, ~94% charcoal moon
    readonly property color bgSurface:     "#151924"     // raised card
    readonly property color bgSurfaceAlt:  "#1A1F2C"     // elevated control
    readonly property color bgInset:       "#0D111A"     // recessed (inset rows)
    readonly property color bgHover:       "#242B3B"     // hover fill
    readonly property color bgPressed:     "#1B2130"     // pressed fill
    readonly property color bgActive:      "#89B4FA"     // active accent fill

    // ── Borders ─────────────────────────────────────────────────────────────
    readonly property color borderSubtle:  "#14FFFFFF"   // 8% white hairline
    readonly property color borderHover:   "#2CFFFFFF"   // 17% white
    readonly property color borderActive:  "#6689B4FA"   // accent
    readonly property color borderGlass:   "#0DFFFFFF"

    // ── Accents (Catppuccin Mocha) ──────────────────────────────────────────
    readonly property color accent:        "#89B4FA"     // blue — primary accent
    readonly property color accentText:    "#0B0E17"     // text on accent fill
    readonly property color cyan:          "#38BDF8"     // electric cyan (brand)
    readonly property color green:         "#A6E3A1"     // success / active
    readonly property color red:           "#F38BA8"     // destructive
    readonly property color yellow:        "#F9E2AF"     // warning
    readonly property color teal:          "#94E2D5"
    readonly property color lavender:      "#B4BEFE"
    readonly property color peach:         "#FAB387"

    // ── Text ────────────────────────────────────────────────────────────────
    readonly property color textPrimary:   "#CDD6F4"
    readonly property color textSecondary: "#A6ADC8"
    readonly property color textMuted:     "#9399B2"
    readonly property color textSubtle:    "#6C7086"
    readonly property color textOnAccent:  "#0B0E17"

    // ── Type scale ──────────────────────────────────────────────────────────
    readonly property int sizeDisplay: 17
    readonly property int sizeTitle:   13
    readonly property int sizeBody:    12
    readonly property int sizeSmall:   11
    readonly property int sizeCaption: 9

    // ── Geometry ────────────────────────────────────────────────────────────
    readonly property int radiusWindow:  24
    readonly property int radiusCard:    16
    readonly property int radiusControl: 12
    readonly property int radiusPill:    24
    readonly property int radiusIcon:    20
    readonly property int spacing:       10
    readonly property int panelPadding:  14
}