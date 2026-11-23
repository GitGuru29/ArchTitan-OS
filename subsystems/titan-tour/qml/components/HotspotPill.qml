import QtQuick
import ArchTitan.TitanUI

Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property color hotspotColor: TitanTheme.accent
    property bool isSelected: false
    signal clicked()

    implicitWidth: contentRow.implicitWidth + 16
    implicitHeight: 28
    radius: 14

    color: isSelected ? Qt.rgba(hotspotColor.r, hotspotColor.g, hotspotColor.b, 0.22)
                      : (mouseArea.containsMouse ? Qt.rgba(hotspotColor.r, hotspotColor.g, hotspotColor.b, 0.12)
                                                 : Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.85))
    border.width: isSelected ? 1.5 : 1
    border.color: isSelected ? hotspotColor
                             : (mouseArea.containsMouse ? Qt.rgba(hotspotColor.r, hotspotColor.g, hotspotColor.b, 0.6)
                                                        : Qt.rgba(1, 1, 1, 0.14))

    scale: mouseArea.pressed ? 0.96 : (mouseArea.containsMouse ? 1.04 : 1.0)
    Behavior on scale { NumberAnimation { duration: 120 } }
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.icon
            color: root.isSelected ? root.hotspotColor : (mouseArea.containsMouse ? root.hotspotColor : TitanTheme.textMid)
            font.family: TitanTheme.monoFamily
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.label
            color: root.isSelected ? TitanTheme.textHigh : (mouseArea.containsMouse ? TitanTheme.textHigh : TitanTheme.textMid)
            font.family: TitanTheme.fontFamily
            font.pixelSize: 11
            font.weight: root.isSelected ? Font.Bold : Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
