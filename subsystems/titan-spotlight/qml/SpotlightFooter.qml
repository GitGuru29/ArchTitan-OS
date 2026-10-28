import QtQuick
import ArchTitan.TitanUI

Item {
    id: footerRoot
    width: parent.width
    height: 36

    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Qt.rgba(255, 255, 255, 0.08)
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16

        Row {
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                width: 18; height: 18; radius: 4
                color: Qt.rgba(255, 255, 255, 0.08)
                anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "↑↓"; font.pixelSize: 10; color: TitanTheme.textMid }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Navigate"; font.pixelSize: 11; color: TitanTheme.textLow }
        }

        Row {
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                width: 18; height: 18; radius: 4
                color: Qt.rgba(255, 255, 255, 0.08)
                anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "⏎"; font.pixelSize: 10; color: TitanTheme.textMid }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Open"; font.pixelSize: 11; color: TitanTheme.textLow }
        }

        Row {
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                width: 24; height: 18; radius: 4
                color: Qt.rgba(255, 255, 255, 0.08)
                anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "esc"; font.pixelSize: 9; color: TitanTheme.textMid }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Dismiss"; font.pixelSize: 11; color: TitanTheme.textLow }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "ArchTitan Spotlight"
            font.family: TitanTheme.fontFamily
            font.pixelSize: 10
            font.bold: true
            color: TitanTheme.accent
        }
    }
}
