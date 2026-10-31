import QtQuick
import ArchTitan.TitanUI

Item {
    id: footerRoot
    width: parent.width
    height: 40

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16

        Row {
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                width: navKeyText.implicitWidth + 10; height: 19; radius: 5
                color: TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: navKeyText
                    anchors.centerIn: parent
                    text: spotlight.gridColumns > 1 ? "↑↓←→" : "↑↓"
                    font.pixelSize: 10
                    font.bold: true
                    color: TitanTheme.textMid
                }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Navigate"; font.pixelSize: 11; color: TitanTheme.textLow }
        }

        Row {
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                width: 20; height: 19; radius: 5
                color: TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)
                anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "⏎"; font.pixelSize: 10; font.bold: true; color: TitanTheme.textMid }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Open"; font.pixelSize: 11; color: TitanTheme.textLow }
        }

        Row {
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                width: 28; height: 19; radius: 5
                color: TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)
                anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "tab"; font.pixelSize: 10; font.bold: true; color: TitanTheme.textMid }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Layout"; font.pixelSize: 11; color: TitanTheme.textLow }
        }

        Row {
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                width: 36; height: 19; radius: 5
                color: TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)
                anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "⇧tab"; font.pixelSize: 10; font.bold: true; color: TitanTheme.textMid }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Category"; font.pixelSize: 11; color: TitanTheme.textLow }
        }

        Row {
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                width: 26; height: 19; radius: 5
                color: TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)
                anchors.verticalCenter: parent.verticalCenter
                Text { anchors.centerIn: parent; text: "esc"; font.pixelSize: 10; font.bold: true; color: TitanTheme.textMid }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Dismiss"; font.pixelSize: 11; color: TitanTheme.textLow }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "> cmd  •  @clip  •  math"
            font.family: TitanTheme.monoFamily
            font.pixelSize: 10
            color: TitanTheme.textLow
        }

        Rectangle {
            width: 4
            height: 4
            radius: 2
            anchors.verticalCenter: parent.verticalCenter
            color: TitanTheme.accent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "ArchTitan Spotlight"
            font.family: TitanTheme.fontFamily
            font.pixelSize: 11
            font.bold: true
            color: TitanTheme.accent
        }
    }
}
