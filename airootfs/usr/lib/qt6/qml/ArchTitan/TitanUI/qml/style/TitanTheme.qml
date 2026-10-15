pragma Singleton
import QtQuick
import ArchTitan.TitanUI

/**
 * TitanTheme — ArchTitan "Titan Design Language" (TDL) tokens.
 *
 * Single source of truth for every user-facing surface. Base surfaces are
 * Catppuccin Mocha; geometry and glass depth follow Samsung One UI 9.0. The
 * accent is wallpaper-adaptive via ThemeBackend and can be overridden at runtime.
 *
 * Import: `import ArchTitan.TitanUI`
 */
QtObject {
    id: theme

    // ── Mode ────────────────────────────────────────────────────────────────
    readonly property bool isDark: true

    // ── Accent (wallpaper-adaptive) ─────────────────────────────────────────
    property color accent: ThemeBackend.accent
    readonly property color accentFg:              ThemeBackend.accentFg
    readonly property color accentSoft:            Qt.rgba(accent.r, accent.g, accent.b, 0.18)
    readonly property color accentSofter:          Qt.rgba(accent.r, accent.g, accent.b, 0.10)
    readonly property color accentEdge:            Qt.rgba(accent.r, accent.g, accent.b, 0.55)

    // ── Catppuccin Mocha surfaces ───────────────────────────────────────────
    readonly property color crust:    "#11111B"
    readonly property color mantle:   "#181825"
    readonly property color base:     "#1E1E2E"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475A"
    readonly property color surface2: "#585B70"
    readonly property color surface3: "#6C7086"

    // Semantic background roles
    readonly property color bg0:      "#11111B"          // deepest
    readonly property color bg1:      "#B31E1E2E"         // window shell (translucent)
    readonly property color bg2:      "#991E1E2E"         // card
    readonly property color bg3:      "#1E1E2E"           // elevated
    readonly property color bg4:      "#313244"           // hover
    readonly property color bgInset:  "#800E0E16"         // recessed

    // Frosted glass / overlay
    readonly property color glass:     "#B80B0E14"
    readonly property color glassAlt:  "#70161A26"
    readonly property color glassCard: "#66182132"

    // ── Borders ─────────────────────────────────────────────────────────────
    readonly property color border:       "#252838"
    readonly property color borderSubtle: "#18FFFFFF"
    readonly property color borderHover:  "#40FFFFFF"
    readonly property color borderStrong: accentEdge

    // ── Text ────────────────────────────────────────────────────────────────
    readonly property color textHigh:     "#CDD6F4"
    readonly property color textMid:      "#A6ADC8"
    readonly property color textLow:      "#7F849C"
    readonly property color textOnAccent: accentFg

    // ── Semantic status ─────────────────────────────────────────────────────
    readonly property color success: "#A6E3A1"
    readonly property color warning: "#F9E2AF"
    readonly property color danger:  "#F38BA8"
    readonly property color info:    "#89B4FA"
    readonly property color teal:    "#94E2D5"
    readonly property color peach:   "#FAB387"
    readonly property color mauve:   "#CBA6F7"
    readonly property color pink:    "#F5C2E7"

    // ── Typography ──────────────────────────────────────────────────────────
    readonly property string fontFamily:  "Inter"
    readonly property string monoFamily:  "JetBrainsMono Nerd Font"
    readonly property int sizeDisplay: 22
    readonly property int sizeTitle:   15
    readonly property int sizeBody:    13
    readonly property int sizeLabel:   11
    readonly property int sizeCaption: 9
    readonly property int weightRegular:  400
    readonly property int weightMedium:    500
    readonly property int weightSemiBold:  600
    readonly property int weightBold:      700

    // ── Radii (One UI 9.0 squircles) ────────────────────────────────────────
    readonly property int radiusSm:      8
    readonly property int radiusMd:      12
    readonly property int radiusLg:      16
    readonly property int radiusXl:      20
    readonly property int radiusBento:   24
    readonly property int radiusWindow:  28
    readonly property int radiusCard:    20
    readonly property int radiusControl: 16
    readonly property int radiusSlider:  26
    readonly property int radiusPill:    999

    // ── Spacing (4-point grid) ──────────────────────────────────────────────
    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16
    readonly property int space6: 24
    readonly property int space8: 32

    // ── Motion ──────────────────────────────────────────────────────────────
    readonly property int durFast: 120
    readonly property int durBase: 200
    readonly property int durSlow: 320
    readonly property int durShimmer: 1400
    // Easing curves — use for entering (decelerate) vs leaving (accelerate).
    readonly property int easingStandard: Easing.OutCubic
    readonly property int easingEnter:    Easing.OutCubic
    readonly property int easingExit:     Easing.InCubic
    readonly property int easingEmphasis: Easing.OutQuart
    // Feedback
    readonly property real pressScale: 0.97
}
