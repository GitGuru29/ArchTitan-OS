import QtQuick
import ArchTitan.TitanUI

Item {
    id: cardRoot
    width: 154
    height: 180

    required property string title
    required property string subtitle
    required property string iconGlyph
    required property string keyHint
    required property color accentColor
    property bool isSelected: false

    signal triggered()

    scale: mouseArea.pressed ? 0.94 : (mouseArea.containsMouse || isSelected ? 1.05 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: 140; easing.type: Easing.OutBack }
    }

    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 26
        color: TitanTheme.isDark
               ? (isSelected || mouseArea.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.16) : "#B311111B")
               : (isSelected || mouseArea.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.14) : "#D9FFFFFF")

        border.width: (isSelected || mouseArea.containsMouse) ? 2 : 1
        border.color: (isSelected || mouseArea.containsMouse)
                      ? accentColor
                      : Qt.rgba(255, 255, 255, 0.10)

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        // Glow halo on selection/hover
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 30
            z: -1
            color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.28)
            visible: isSelected || mouseArea.containsMouse
            opacity: isSelected ? 1.0 : (mouseArea.containsMouse ? 0.7 : 0.0)
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        Column {
            anchors.centerIn: parent
            spacing: 10
            width: parent.width - 24

            // Icon circle
            Rectangle {
                width: 60
                height: 60
                radius: 30
                anchors.horizontalCenter: parent.horizontalCenter
                color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.18)
                border.width: 1
                border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.35)

                Text {
                    anchors.centerIn: parent
                    text: cardRoot.iconGlyph
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 30
                    color: cardRoot.accentColor
                }
            }

            // Title & Subtitle
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2
                width: parent.width

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: cardRoot.title
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                    color: (isSelected || mouseArea.containsMouse) ? TitanTheme.textHigh : TitanTheme.textHigh
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: cardRoot.subtitle
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    color: TitanTheme.textLow
                }
            }

            // Keycap shortcut pill
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: keyText.implicitWidth + 14
                height: 20
                radius: 6
                color: (isSelected || mouseArea.containsMouse)
                       ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3)
                       : Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                border.color: (isSelected || mouseArea.containsMouse)
                              ? accentColor
                              : Qt.rgba(255, 255, 255, 0.12)

                Text {
                    id: keyText
                    anchors.centerIn: parent
                    text: cardRoot.keyHint
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: (isSelected || mouseArea.containsMouse) ? accentColor : TitanTheme.textMid
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cardRoot.triggered()
    }
}
