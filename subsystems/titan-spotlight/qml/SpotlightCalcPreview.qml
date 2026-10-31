import QtQuick
import ArchTitan.TitanUI

Rectangle {
    id: calcCard
    width: parent.width
    height: 64
    radius: 14
    color: calcCard.isSelected
           ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.28)
           : Qt.rgba(1, 1, 1, 0.08)
    border.width: calcCard.isSelected ? 1.5 : 1
    border.color: calcCard.isSelected ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.12)

    // Ambient glow halo
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: calcCard.radius + 1
        z: -1
        color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.20)
        visible: calcCard.isSelected
    }

    property bool isSelected: false

    signal clicked()

    Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        // Calculator icon tile
        Rectangle {
            id: calcIconTile
            width: 38
            height: 38
            radius: 10
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.2)
            border.width: 1
            border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.4)

            Text {
                anchors.centerIn: parent
                text: "󰃬"
                font.family: TitanTheme.monoFamily
                font.pixelSize: 18
                color: TitanTheme.accent
            }
        }

        // Formula and Result text
        Column {
            anchors.left: calcIconTile.right
            anchors.leftMargin: 14
            anchors.right: actionBadge.left
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: "= " + spotlight.calcResult
                font.family: TitanTheme.fontFamily
                font.pixelSize: 20
                font.bold: true
                color: TitanTheme.textHigh
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: spotlight.calcFormula + "  •  Press ⏎ to copy to clipboard"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                color: TitanTheme.textMid
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Action badge
        Rectangle {
            id: actionBadge
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            width: 72
            height: 26
            radius: 6
            color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.15)
            border.width: 1
            border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.4)

            Text {
                anchors.centerIn: parent
                text: "⏎ Copy"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: TitanTheme.accent
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: calcCard.clicked()
    }
}
