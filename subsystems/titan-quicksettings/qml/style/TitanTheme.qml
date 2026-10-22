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

    readonly property string fontFamily: TDL.TitanTheme.fontFamily
    readonly property string monoFamily: TDL.TitanTheme.monoFamily

    // ── Window / bento surfaces ────────────────────────────────────────────
    readonly property color bgWindow:          TDL.TitanTheme.bg1        // translucent window shell
    readonly property color bgSurface:         TDL.TitanTheme.bg2        // raised container
    readonly property color bgSurfaceAlt:      TDL.TitanTheme.bg3        // elevated squircle tile
    readonly property color bgInset:           TDL.TitanTheme.bgInset    // recessed track
    readonly property color bgHover:           isDark ? TDL.TitanTheme.borderHover : Qt.rgba(0, 0, 0, 0.08)
    readonly property color bgPressed:         isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color bgActive:          TDL.TitanTheme.accent

    readonly property color bgOneUICard:       TDL.TitanTheme.glassCard  // frosted bento card
    readonly property color bgOneUICardAlt:    TDL.TitanTheme.bg4
    readonly property color bgOneUITrack:      TDL.TitanTheme.bgInset
    readonly property color bgOneUIPill:       isDark ? TDL.TitanTheme.bg4 : Qt.rgba(0, 0, 0, 0.04)
    readonly property color bgMenu:            isDark ? Qt.rgba(TDL.TitanTheme.bg0.r, TDL.TitanTheme.bg0.g, TDL.TitanTheme.bg0.b, 0.90) : Qt.rgba(1, 1, 1, 0.92) // power menu scrim

    // ── Borders & glass contours ───────────────────────────────────────────
    readonly property color borderSubtle:      TDL.TitanTheme.borderSubtle
    readonly property color borderHover:       TDL.TitanTheme.borderHover
    readonly property color borderActive:      TDL.TitanTheme.accentEdge
    readonly property color borderGlass:       isDark ? TDL.TitanTheme.borderHover : TDL.TitanTheme.borderSubtle
    readonly property color borderOneUIGlass:  isDark ? TDL.TitanTheme.borderHover : TDL.TitanTheme.borderSubtle

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
