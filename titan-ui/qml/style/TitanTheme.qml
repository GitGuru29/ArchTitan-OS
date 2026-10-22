pragma Singleton
import QtQuick
import ArchTitan.TitanUI

/**
 * TitanTheme — ArchTitan "Titan Design Language" (TDL) tokens.
 *
 * Single source of truth for every user-facing surface. Colour tokens are
 * bindings onto ThemeBackend, which loads the active theme from
 * ~/.config/archtitan/theme.json (written by `titan-theme`) and falls back to
 * Catppuccin Mocha — so QML recolours live on every theme or accent switch
 * with no restarts. Geometry and glass depth follow Samsung One UI 9.0.
 *
 * Import: `import ArchTitan.TitanUI`
 */
QtObject {
    id: theme

    // ── Mode ────────────────────────────────────────────────────────────────
    readonly property bool isDark: ThemeBackend.isDark

    // ── Accent (theme / wallpaper-adaptive) ─────────────────────────────────
    property color accent: ThemeBackend.accent
    readonly property color accentFg:              ThemeBackend.accentFg
    readonly property color accentSoft:            Qt.rgba(accent.r, accent.g, accent.b, 0.18)
    readonly property color accentSofter:          Qt.rgba(accent.r, accent.g, accent.b, 0.10)
    readonly property color accentEdge:            Qt.rgba(accent.r, accent.g, accent.b, 0.55)

    // ── Theme surfaces ──────────────────────────────────────────────────────
    readonly property color crust:    ThemeBackend.crust
    readonly property color mantle:   ThemeBackend.mantle
    readonly property color base:     ThemeBackend.base
    readonly property color surface0: ThemeBackend.surface0
    readonly property color surface1: ThemeBackend.surface1
    readonly property color surface2: ThemeBackend.surface2
    readonly property color surface3: ThemeBackend.surface3

    // Semantic background roles
    readonly property color bg0:      crust                             // deepest
    readonly property color bg1:      Qt.rgba(base.r, base.g, base.b, 0.702)   // window shell (translucent)
    readonly property color bg2:      Qt.rgba(base.r, base.g, base.b, 0.6)     // card
    readonly property color bg3:      base                              // elevated
    readonly property color bg4:      surface0                          // hover
    readonly property color bgInset:  Qt.rgba(crust.r, crust.g, crust.b, 0.502) // recessed

    // Frosted glass / overlay
    readonly property color glass:     Qt.rgba(crust.r, crust.g, crust.b, 0.722)
    readonly property color glassAlt:  Qt.rgba(mantle.r, mantle.g, mantle.b, 0.439)
    readonly property color glassCard: Qt.rgba(mantle.r, mantle.g, mantle.b, 0.4)

    // ── Borders ─────────────────────────────────────────────────────────────
    readonly property color border:       ThemeBackend.border
    readonly property color borderSubtle: isDark ? "#18FFFFFF" : "#1A000000"
    readonly property color borderHover:  isDark ? "#40FFFFFF" : "#30000000"
    readonly property color borderStrong: accentEdge

    // ── Text ────────────────────────────────────────────────────────────────
    readonly property color textHigh:     ThemeBackend.textHigh
    readonly property color textMid:      ThemeBackend.textMid
    readonly property color textLow:      ThemeBackend.textLow
    readonly property color textOnAccent: accentFg

    // ── Semantic status ─────────────────────────────────────────────────────
    readonly property color success: ThemeBackend.success
    readonly property color warning: ThemeBackend.warning
    readonly property color danger:  ThemeBackend.danger
    readonly property color info:    ThemeBackend.info
    readonly property color teal:    ThemeBackend.teal
    readonly property color peach:   ThemeBackend.peach
    readonly property color mauve:   ThemeBackend.mauve
    readonly property color pink:    ThemeBackend.pink

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
    readonly property int radiusMd:     12
    readonly property int radiusLg:     16
    readonly property int radiusXl:     20
    readonly property int radiusBento:  24
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
