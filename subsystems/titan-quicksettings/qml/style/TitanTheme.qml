pragma Singleton
import QtQuick
import ArchTitan.TitanUI as TDL

/**
 * TitanTheme — ArchTitan Quick Settings token adapter.
 *
 * This singleton preserves the historical One UI-shaped token names used by
 * the Quick Settings QML, but sources every value from the shared
 * ArchTitan.TitanUI "Titan Design Language" singletons (Catppuccin Mocha base +
 * wallpaper-adaptive accent). Keeping the adapter removes ~4k lines of local
 * palette duplication while letting every component stay untouched.
 *
 * Import: `import "../style"` (unqualified `TitanTheme.*`).
 */
QtObject {
    readonly property bool isDark: TDL.TitanTheme.isDark
    readonly property real glassOpacity: TDL.TitanTheme.glassOpacity
    readonly property real glassFactor: TDL.TitanTheme.glassFactor

    readonly property string fontFamily: TDL.TitanTheme.fontFamily
    readonly property string monoFamily: TDL.TitanTheme.monoFamily

    // ── Window / bento surfaces (macOS Sonoma/Sequoia Obsidian Glass) ──────
    readonly property color bgObsidian:        Qt.rgba(0.055, 0.072, 0.105, Math.max(0.86, Math.min(0.96, 0.92 * glassFactor)))
    readonly property color bgTitanium:        Qt.rgba(0.12, 0.15, 0.20, 0.78)
    readonly property color bgTitaniumCard:    Qt.rgba(0.14, 0.17, 0.23, 0.82)
    readonly property color bgTitaniumHover:   Qt.rgba(0.19, 0.23, 0.30, 0.88)

    readonly property color bgWindow:          bgObsidian
    readonly property color bgSurface:         bgTitanium
    readonly property color bgSurfaceAlt:      bgTitaniumCard
    readonly property color bgInset:           Qt.rgba(1, 1, 1, 0.07)
    readonly property color bgHover:           Qt.rgba(1, 1, 1, 0.12)
    readonly property color bgPressed:         Qt.rgba(1, 1, 1, 0.18)
    readonly property color bgActive:          accent

    readonly property color bgOneUICard:       bgTitaniumCard
    readonly property color bgOneUICardAlt:    bgTitanium
    readonly property color bgOneUITrack:      Qt.rgba(0, 0, 0, 0.36)
    readonly property color bgOneUIPill:       Qt.rgba(1, 1, 1, 0.09)
    readonly property color bgMenu:            Qt.rgba(0.07, 0.085, 0.11, 0.95)

    // ── Borders & metallic contours ────────────────────────────────────────
    readonly property color borderHairline:    Qt.rgba(1, 1, 1, 0.11)
    readonly property color borderSubtle:      Qt.rgba(1, 1, 1, 0.09)
    readonly property color borderHover:       Qt.rgba(1, 1, 1, 0.22)
    readonly property color borderActive:      Qt.rgba(0.04, 0.52, 1.0, 0.75)
    readonly property color borderGlass:       Qt.rgba(1, 1, 1, 0.14)
    readonly property color borderOneUIGlass:  Qt.rgba(1, 1, 1, 0.12)

    // ── Titan Signature Accents (macOS Electric Sapphire Blue & Cyan) ──────
    readonly property color titanBlue:         "#0A84FF"
    readonly property color titanBlueHover:    "#38BDF8"
    readonly property color titanBlueGlow:     Qt.rgba(0.04, 0.52, 1.0, 0.28)
    readonly property color titanCyan:         "#00B4D8"

    readonly property color accent:            titanBlue
    readonly property color accentBlue:        titanBlue
    readonly property color accentGlow:        titanBlueGlow
    readonly property color accentText:        "#FFFFFF"
    readonly property color cyan:              "#38BDF8"
    readonly property color green:             "#10B981"
    readonly property color red:               "#EF4444"
    readonly property color yellow:            "#F59E0B"
    readonly property color teal:              "#00B4D8"
    readonly property color lavender:          "#818CF8"
    readonly property color peach:             "#38BDF8"

    // ── Text & typography ──────────────────────────────────────────────────
    readonly property color textPrimary:       "#FFFFFF"
    readonly property color textSecondary:     Qt.rgba(1, 1, 1, 0.78)
    readonly property color textMuted:         Qt.rgba(1, 1, 1, 0.52)
    readonly property color textSubtle:        Qt.rgba(1, 1, 1, 0.38)
    readonly property color textOnAccent:      "#FFFFFF"

    // ── Type scale ──────────────────────────────────────────────────────────
    readonly property int sizeClock:    28
    readonly property int sizeDisplay:  16
    readonly property int sizeTitle:    13
    readonly property int sizeBody:     11
    readonly property int sizeSmall:    10
    readonly property int sizeCaption:  9

    // ── macOS-Inspired Refined Bento Geometry & Radii ──────────────────────
    readonly property int radiusWindow:     22
    readonly property int radiusBento:      16
    readonly property int radiusCard:       16
    readonly property int radiusModule:     16
    readonly property int radiusTile:       13
    readonly property int radiusControl:    12
    readonly property int radiusSlider:     12
    readonly property int radiusCircle:     24
    readonly property int radiusPill:       99
    readonly property int radiusCapsule:    16
    readonly property int radiusIcon:       14

    readonly property int spacing:         8
    readonly property int panelPadding:    12
}
