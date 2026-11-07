import QtQuick
import ArchTitan.TitanUI

/* TitanToggleTile — compact quick-toggle tile with a restrained active tint. */
Rectangle {
    id: root

    property string glyph: ""
    property string label: ""
    property bool checked: false
    property color activeColor: TitanTheme.accent

    signal toggled(bool value)

    implicitWidth: 88
    implicitHeight: 88
    radius: TitanTheme.radiusBento
    color: checked ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.16)
                   : (hover.hovered ? TitanTheme.surface0 : TitanTheme.bg3)
    border.width: 1
    border.color: checked ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.55) : TitanTheme.borderSubtle
    scale: tap.pressed ? TitanTheme.pressScale : 1.0
    opacity: enabled ? 1.0 : 0.45
    activeFocusOnTab: true

    Behavior on color { ColorAnimation { duration: TitanTheme.durBase } }
    Behavior on scale { NumberAnimation { duration: TitanTheme.durFast; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -TitanTheme.focusRingOffset
        radius: root.radius + TitanTheme.focusRingOffset
        color: "transparent"
        border.width: TitanTheme.focusRingWidth
        border.color: TitanTheme.focusRing
        visible: root.activeFocus
    }

    Column {
        anchors.centerIn: parent
        spacing: TitanTheme.space2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.glyph
            color: root.checked ? root.activeColor : TitanTheme.textHigh
            font.family: TitanTheme.monoFamily
            font.pixelSize: 22
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: root.checked ? TitanTheme.textHigh : TitanTheme.textMid
            font.family: TitanTheme.fontFamily
            font.pixelSize: TitanTheme.sizeLabel
            font.weight: TitanTheme.weightMedium
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor; id: hover }
    TapHandler {
        id: tap
        enabled: root.enabled
        onTapped: {
            root.forceActiveFocus()
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
    Keys.onReturnPressed: if (root.enabled) { root.checked = !root.checked; root.toggled(root.checked) }
    Keys.onSpacePressed: if (root.enabled) { root.checked = !root.checked; root.toggled(root.checked) }
}
