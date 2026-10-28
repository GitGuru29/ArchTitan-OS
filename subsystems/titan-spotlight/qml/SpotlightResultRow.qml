import QtQuick
import ArchTitan.TitanUI

Rectangle {
    id: rowRoot
    width: parent.width
    height: 52
    radius: 12

    property bool isSelected: false
    property var modelItem: null

    signal activated()

    color: isSelected ?
        (TitanTheme.isDark ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.22) : Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.15))
        : (rowHover.containsMouse ? (TitanTheme.isDark ? Qt.rgba(255, 255, 255, 0.05) : Qt.rgba(0, 0, 0, 0.04)) : "transparent")

    border.width: isSelected ? 1 : 0
    border.color: isSelected ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.5) : "transparent"

    Behavior on color { ColorAnimation { duration: 100 } }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14

        // Icon Tile
        Rectangle {
            id: iconTile
            width: 36
            height: 36
            radius: 9
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.3) : Qt.rgba(255, 255, 255, 0.6)
            border.width: 1
            border.color: isSelected ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.3) : Qt.rgba(255, 255, 255, 0.08)

            Image {
                id: appIcon
                anchors.centerIn: parent
                width: 26
                height: 26
                source: modelItem && modelItem.icon ? "image://icon/" + modelItem.icon : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true

                // Fallback icon if image fails
                Text {
                    anchors.centerIn: parent
                    visible: appIcon.status !== Image.Ready
                    text: modelItem && modelItem.type === "clipboard" ? "󰅍" : (modelItem && modelItem.type === "command" ? "󰞷" : "󰘳")
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 18
                    color: TitanTheme.accent
                }
            }
        }

        // Labels
        Column {
            anchors.left: iconTile.right
            anchors.leftMargin: 12
            anchors.right: actionPill.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: modelItem ? modelItem.title : ""
                font.family: TitanTheme.fontFamily
                font.pixelSize: 14
                font.bold: isSelected
                color: isSelected ? (TitanTheme.isDark ? "#ffffff" : TitanTheme.textHigh) : TitanTheme.textHigh
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: modelItem ? modelItem.subtitle : ""
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                color: isSelected ? TitanTheme.textMid : TitanTheme.textLow
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Right side Action Pill
        Rectangle {
            id: actionPill
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            width: 68
            height: 24
            radius: 6
            color: isSelected ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.25) : Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: isSelected ? TitanTheme.accent : Qt.rgba(255, 255, 255, 0.08)
            visible: isSelected || rowHover.containsMouse

            Text {
                anchors.centerIn: parent
                text: modelItem && modelItem.type === "clipboard" ? "⏎ Paste" : (modelItem && modelItem.type === "command" ? "⏎ Run" : "⏎ Open")
                font.family: TitanTheme.fontFamily
                font.pixelSize: 10
                font.bold: true
                color: isSelected ? TitanTheme.accent : TitanTheme.textMid
            }
        }
    }

    MouseArea {
        id: rowHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: rowRoot.activated()
    }
}
