import QtQuick
import ArchTitan.TitanUI

/**
 * SpotlightFooter — Apple Spotlight minimalist metadata footer.
 */
Item {
    id: footerRoot
    width: parent.width
    height: 28

    // Top hairline
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: TitanTheme.borderSubtle
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        // Left Result Count
        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: spotlight.hasCalcResult ? "Calculator" : (spotlight.results.length + (spotlight.results.length === 1 ? " result" : " results"))
            font.family: TitanTheme.fontFamily
            font.pixelSize: 11
            color: TitanTheme.textLow
        }

        // Right Keyboard Shortcuts
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Row {
                spacing: 5
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: 18; height: 16; radius: 4
                    color: TitanTheme.stateHover
                    border.width: 1
                    border.color: TitanTheme.borderSubtle
                    anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: "⏎"; font.pixelSize: 9; font.bold: true; color: TitanTheme.textMid }
                }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "Open"; font.pixelSize: 10; color: TitanTheme.textLow }
            }

            Row {
                spacing: 5
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: 22; height: 16; radius: 4
                    color: TitanTheme.stateHover
                    border.width: 1
                    border.color: TitanTheme.borderSubtle
                    anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: "esc"; font.pixelSize: 8; font.bold: true; color: TitanTheme.textMid }
                }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "Close"; font.pixelSize: 10; color: TitanTheme.textLow }
            }
        }
    }
}
