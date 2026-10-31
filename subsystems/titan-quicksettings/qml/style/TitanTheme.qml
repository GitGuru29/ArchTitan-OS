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

    // ── Window / bento surfaces (macOS Liquid Frosted Glass) ──────────────
    readonly property color bgWindow:          isDark ? Qt.rgba(TDL.TitanTheme.base.r, TDL.TitanTheme.base.g, TDL.TitanTheme.base.b, Math.min(0.95, 0.46 * glassFactor)) : Qt.rgba(TDL.TitanTheme.base.r, TDL.TitanTheme.base.g, TDL.TitanTheme.base.b, Math.min(0.95, 0.62 * glassFactor))
    readonly property color bgSurface:         isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.45)
    readonly property color bgSurfaceAlt:      isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.60)
    readonly property color bgInset:           isDark ? Qt.rgba(0, 0, 0, 0.28) : Qt.rgba(0, 0, 0, 0.05)
    readonly property color bgHover:           isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.70)
    readonly property color bgPressed:         isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color bgActive:          TDL.TitanTheme.accent

    readonly property color bgOneUICard:       isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(1, 1, 1, 0.50)
    readonly property color bgOneUICardAlt:    isDark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.65)
    readonly property color bgOneUITrack:      isDark ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(0, 0, 0, 0.06)
    readonly property color bgOneUIPill:       isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.60)
    readonly property color bgMenu:            isDark ? Qt.rgba(TDL.TitanTheme.bg0.r, TDL.TitanTheme.bg0.g, TDL.TitanTheme.bg0.b, 0.75) : Qt.rgba(1, 1, 1, 0.88)

    // ── Borders & glass contours ───────────────────────────────────────────
    readonly property color borderSubtle:      isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color borderHover:       isDark ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.20)
    readonly property color borderActive:      TDL.TitanTheme.accentEdge
    readonly property color borderGlass:       isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color borderOneUIGlass:  isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10)

    // ── Accents & indicators ───────────────────────────────────────────────
    readonly property color accent:            TDL.TitanTheme.accent
    readonly property color accentBlue:        TDL.TitanTheme.accent
    readonly property color accentText:        TDL.TitanTheme.accentFg
    readonly property color cyan:              TDL.TitanTheme.teal
    readonly property color green:             TDL.TitanTheme.success
    readonly property color red:               TDL.TitanTheme.danger
    readonly property color yellow:            TDL.TitanTheme.warning
    readonly property color teal:              TDL.TitanTheme.teal
    readonly property color lavender:          TDL.TitanTheme.mauve
    readonly property color peach:             TDL.TitanTheme.peach

    // ── Text & typography ──────────────────────────────────────────────────
    readonly property color textPrimary:       TDL.TitanTheme.textHigh
    readonly property color textSecondary:     TDL.TitanTheme.textMid
    readonly property color textMuted:         TDL.TitanTheme.textLow
    readonly property color textSubtle:        TDL.TitanTheme.textLow
    readonly property color textOnAccent:      TDL.TitanTheme.accentFg

    // ── Type scale ──────────────────────────────────────────────────────────
    readonly property int sizeClock:    32
    readonly property int sizeDisplay:  18
    readonly property int sizeTitle:    14
    readonly property int sizeBody:     12
    readonly property int sizeSmall:    11
    readonly property int sizeCaption:  9

    // ── One UI geometry & radii ─────────────────────────────────────────────
    readonly property int radiusWindow:     TDL.TitanTheme.radiusWindow
    readonly property int radiusBento:      TDL.TitanTheme.radiusBento
    readonly property int radiusCard:       TDL.TitanTheme.radiusCard
    readonly property int radiusControl:    TDL.TitanTheme.radiusControl
    readonly property int radiusSlider:     TDL.TitanTheme.radiusSlider
    readonly property int radiusCircle:     TDL.TitanTheme.radiusSlider
    readonly property int radiusPill:       TDL.TitanTheme.radiusBento
    readonly property int radiusIcon:       TDL.TitanTheme.radiusCard

    readonly property int spacing:         10
    readonly property int panelPadding:    14
}
