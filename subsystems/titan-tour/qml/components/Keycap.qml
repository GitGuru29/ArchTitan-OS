import QtQuick
import ArchTitan.TitanUI

Rectangle {
    id: root

    property string text: ""
    property bool isAccent: false

    implicitWidth: Math.max(26, label.implicitWidth + 12)
    implicitHeight: 24
    radius: 6

    color: isAccent ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.18)
                    : Qt.rgba(TitanTheme.surface1.r, TitanTheme.surface1.g, TitanTheme.surface1.b, 0.75)
    border.width: 1
    border.color: isAccent ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.45)
                           : Qt.rgba(1, 1, 1, 0.12)

    // Subtle bottom keycap shadow line
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: 1
        radius: 1
        color: Qt.rgba(0, 0, 0, 0.35)
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.isAccent ? TitanTheme.accent : TitanTheme.textHigh
        font.family: TitanTheme.monoFamily
        font.pixelSize: 11
        font.weight: 600
    }
}
