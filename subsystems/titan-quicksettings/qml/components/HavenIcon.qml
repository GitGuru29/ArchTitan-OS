import QtQuick
import "../style"

/**
 * HavenIcon — consistent Nerd Font glyph renderer.
 *
 * Renders a verified JetBrainsMono Nerd Font codepoint on a baseline-aligned,
 * size-scaled Text so mixed icon/text rows line up across the panel.
 */
Text {
    id: iconRoot

    property string source: "\uf059"   // default: circle-question
    property color tint: TitanTheme.textPrimary
    property int glyphSize: 14

    text: source
    color: iconRoot.tint
    font.family: TitanTheme.monoFamily
    font.pixelSize: glyphSize
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Accessible.role: Accessible.StaticText
    Accessible.name: source
}