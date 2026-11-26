pragma Singleton
import QtQuick
import ArchTitan.TitanUI

/**
 * TitanTheme — ArchTitan "Titan Design Language" (TDL) tokens.
 *
 * Single source of truth for every user-facing surface.
 * Performance-first architecture: All dynamic colors, derived alphas,
 * hover/press states, and semantic background roles are computed in native C++
 * by ThemeBackend and bound directly as QColor properties.
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
    readonly property color accentSoft:            ThemeBackend.accentSoft
    readonly property color accentSofter:          ThemeBackend.accentSofter
    readonly property color accentEdge:            ThemeBackend.accentEdge
    readonly property color accentHover:           ThemeBackend.accentHover
    readonly property color accentPressed:         ThemeBackend.accentPressed

    // ── Glass & Transparency ────────────────────────────────────────────────
    readonly property real glassOpacity: ThemeBackend.glassOpacity
    readonly property real glassFactor:  ThemeBackend.glassFactor

    // ── Theme surfaces ──────────────────────────────────────────────────────
    readonly property color crust:    ThemeBackend.crust
    readonly property color mantle:   ThemeBackend.mantle
    readonly property color base:     ThemeBackend.base
    readonly property color surface0: ThemeBackend.surface0
    readonly property color surface1: ThemeBackend.surface1
    readonly property color surface2: ThemeBackend.surface2
    readonly property color surface3: ThemeBackend.surface3

    // Semantic background roles (precomputed in C++)
    readonly property color bg0:      ThemeBackend.bg0
    readonly property color bg1:      ThemeBackend.bg1
    readonly property color bg2:      ThemeBackend.bg2
    readonly property color bg3:      ThemeBackend.bg3
    readonly property color bg4:      ThemeBackend.bg4
    readonly property color bgInset:  ThemeBackend.bgInset

    // Frosted glass / overlay (precomputed in C++)
    readonly property color glass:     ThemeBackend.glass
    readonly property color glassAlt:  ThemeBackend.glassAlt
    readonly property color glassCard: ThemeBackend.glassCard

    // ── Borders ─────────────────────────────────────────────────────────────
    readonly property color border:       ThemeBackend.border
    readonly property color borderSubtle: ThemeBackend.borderSubtle
    readonly property color borderHover:  ThemeBackend.borderHover
    readonly property color borderStrong: ThemeBackend.borderStrong

    // ── Text ────────────────────────────────────────────────────────────────
    readonly property color textHigh:     ThemeBackend.textHigh
    readonly property color textMid:      ThemeBackend.textMid
    readonly property color textLow:      ThemeBackend.textLow
    readonly property color textOnAccent: accentFg

    // ── Semantic status ─────────────────────────────────────────────────────
    readonly property color success:       ThemeBackend.success
    readonly property color warning:       ThemeBackend.warning
    readonly property color danger:        ThemeBackend.danger
    readonly property color dangerHover:   ThemeBackend.dangerHover
    readonly property color dangerPressed: ThemeBackend.dangerPressed
    readonly property color info:          ThemeBackend.info
    readonly property color teal:          ThemeBackend.teal
    readonly property color peach:         ThemeBackend.peach
    readonly property color mauve:         ThemeBackend.mauve
    readonly property color pink:          ThemeBackend.pink

    // ── Typography ──────────────────────────────────────────────────────────
    readonly property string fontFamily:  "Inter"
    readonly property string monoFamily:  "JetBrainsMono Nerd Font"
    readonly property int sizeDisplay:  32
    readonly property int sizeHeadline: 24
    readonly property int sizeTitle:    18
    readonly property int sizeSubtitle: 16
    readonly property int sizeBody:     14
    readonly property int sizeLabel:    12
    readonly property int sizeCaption:  11
    readonly property real lineHeightTight: 1.2
    readonly property real lineHeightBody:  1.45
    readonly property int weightRegular:  400
    readonly property int weightMedium:    500
    readonly property int weightSemiBold:  600
    readonly property int weightBold:      700

    // ── Radii (desktop-first, not phone squircles) ──────────────────────────
    readonly property int radiusSm:      6
    readonly property int radiusMd:      8
    readonly property int radiusLg:     12
    readonly property int radiusXl:     14
    readonly property int radiusBento:  16
    readonly property int radiusWindow: 18
    readonly property int radiusCard:   12
    readonly property int radiusControl: 8
    readonly property int radiusSlider:  26   // circles in compact controls
    readonly property int radiusRound:  999
    readonly property int radiusPill:   999

    // ── Spacing (4-point grid) ──────────────────────────────────────────────
    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16
    readonly property int space6: 24
    readonly property int space8: 32

    // ── Interaction states ──────────────────────────────────────────────────
    readonly property color stateHover:    ThemeBackend.stateHover
    readonly property color statePressed:  ThemeBackend.statePressed
    readonly property color stateSelected: ThemeBackend.stateSelected
    readonly property color focusRing:     ThemeBackend.focusRing
    readonly property int focusRingWidth:  2
    readonly property int focusRingOffset: 2
    readonly property color scrim:         ThemeBackend.scrim

    // ── Motion ──────────────────────────────────────────────────────────────
    readonly property int durFast: 90
    readonly property int durBase: 160
    readonly property int durSlow: 240
    readonly property int durShimmer: 1400
    readonly property int easingStandard: Easing.OutCubic
    readonly property int easingEnter:    Easing.OutCubic
    readonly property int easingExit:     Easing.InCubic
    readonly property int easingEmphasis: Easing.OutQuart
    readonly property real pressScale: 0.98

    // ── C++ Fast Math & Contrast Helpers ────────────────────────────────────
    function contrastRatio(fg, bg) { return ThemeBackend.contrastRatio(fg, bg) }
    function alphaColor(baseColor, alpha) { return ThemeBackend.alphaColor(baseColor, alpha) }
    function lighter(baseColor, factor) { return ThemeBackend.lighterColor(baseColor, factor !== undefined ? factor : 1.08) }
    function darker(baseColor, factor) { return ThemeBackend.darkerColor(baseColor, factor !== undefined ? factor : 1.10) }
    function isAccessible(fg, bg, minRatio) { return ThemeBackend.isAccessible(fg, bg, minRatio !== undefined ? minRatio : 4.5) }
}
