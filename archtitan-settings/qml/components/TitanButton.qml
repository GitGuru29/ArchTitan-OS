import QtQuick
import QtQuick.Controls.Basic
import ArchTitanSettings
import ArchTitan.TitanUI

Rectangle {
    id: root
    height: 36
    radius: TitanTheme.radiusMd
    implicitWidth: label.implicitWidth + 36

    property string text: "Button"
    property bool   primary: true
    property color  accentColor: TitanTheme.accent

    color: root.primary
           ? (hover.pressed ? Qt.darker(root.accentColor, 1.15) : (hover.containsMouse ? Qt.lighter(root.accentColor, 1.1) : root.accentColor))
           : (hover.containsMouse ? TitanTheme.bg4 : TitanTheme.bg3)

    border.width: root.primary ? 0 : 1
    border.color: TitanTheme.border

    Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }

    opacity: root.enabled ? 1.0 : 0.35

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        font { pixelSize: 13; family: "Inter" }
        font.weight: Font.Medium
        color: root.primary ? TitanTheme.accentFg : TitanTheme.textHigh
    }

    scale: hover.pressed ? 0.97 : 1.0
    Behavior on scale { NumberAnimation { duration: 80 } }

    signal clicked()

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        enabled: root.enabled
    }
}
