import QtQuick
import ArchTitan.TitanUI

/* TitanToggleTile — One UI 9.0 squircle quick-toggle tile. */
Rectangle {
    id: root

    property string glyph: ""
    property string label: ""
    property bool checked: false
    property color activeColor: TitanTheme.accent

    signal toggled(bool value)

    implicitWidth: 96
    implicitHeight: 96
    radius: TitanTheme.radiusBento
    color: checked ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.90)
                   : (hover.hovered ? TitanTheme.surface0 : TitanTheme.glassCard)
    border.width: 1
    border.color: checked ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.9) : TitanTheme.borderSubtle
    scale: tap.pressed ? 0.96 : 1.0
    opacity: enabled ? 1.0 : 0.5

    Behavior on color { ColorAnimation { duration: TitanTheme.durBase } }
    Behavior on scale { NumberAnimation { duration: TitanTheme.durFast; easing.type: Easing.OutCubic } }

    Column {
        anchors.centerIn: parent
        spacing: TitanTheme.space2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.glyph
            color: root.checked ? TitanTheme.accentFg : TitanTheme.textHigh
            font.family: TitanTheme.monoFamily
            font.pixelSize: 24
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: root.checked ? TitanTheme.accentFg : TitanTheme.textMid
            font.family: TitanTheme.fontFamily
            font.pixelSize: TitanTheme.sizeLabel
            font.weight: TitanTheme.weightMedium
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor; id: hover }
    TapHandler {
        id: tap
        enabled: root.enabled
        onTapped: { root.checked = !root.checked; root.toggled(root.checked) }
    }
}
