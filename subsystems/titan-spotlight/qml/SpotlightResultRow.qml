import QtQuick
import ArchTitan.TitanUI

/**
 * SpotlightResultRow — Apple Spotlight list row item.
 * Clean, compact, with native icon, primary title, subtitle, and vibrant selection pill.
 */
Rectangle {
    id: rowRoot
    width: parent.width
    height: 44
    radius: 9

    property bool isSelected: false
    property var modelItem: null

    signal activated()
    signal hovered()

    color: isSelected
           ? TitanTheme.accent
           : (rowHover.containsMouse ? TitanTheme.stateHover : "transparent")

    Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 12
        spacing: 10

        // App Icon Tile
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            radius: 7
            color: rowRoot.isSelected ? TitanTheme.alphaColor(TitanTheme.crust, 0.20) : TitanTheme.alphaColor(TitanTheme.surface0, 0.60)
            border.width: 1
            border.color: rowRoot.isSelected ? TitanTheme.alphaColor(TitanTheme.textOnAccent, 0.25) : TitanTheme.borderSubtle

            Image {
                anchors.centerIn: parent
                width: 22
                height: 22
                source: rowRoot.modelItem && rowRoot.modelItem.icon ? ("image://icon/" + rowRoot.modelItem.icon) : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: rowRoot.modelItem && rowRoot.modelItem.type === "command" ? "󰞷" :
                      rowRoot.modelItem && rowRoot.modelItem.type === "clipboard" ? "󰅍" :
                      rowRoot.modelItem && rowRoot.modelItem.type === "system" ? "󰒓" : "󰀻"
                font.family: TitanTheme.monoFamily
                font.pixelSize: 15
                color: rowRoot.isSelected ? TitanTheme.textOnAccent : TitanTheme.accent
                visible: !parent.children[0].visible
            }
        }

        // Title and Subtitle Text Column
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 28 - 10 - (badgeRect.visible ? badgeRect.width + 10 : 0)
            spacing: 1

            Text {
                width: parent.width
                text: rowRoot.modelItem ? (rowRoot.modelItem.title || "") : ""
                font.family: TitanTheme.fontFamily
                font.pixelSize: 13
                font.weight: rowRoot.isSelected ? TitanTheme.weightSemiBold : TitanTheme.weightMedium
                color: rowRoot.isSelected ? TitanTheme.textOnAccent : TitanTheme.textHigh
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: rowRoot.modelItem ? (rowRoot.modelItem.subtitle || "") : ""
                font.family: TitanTheme.fontFamily
                font.pixelSize: 10
                color: rowRoot.isSelected ? TitanTheme.alphaColor(TitanTheme.textOnAccent, 0.75) : TitanTheme.textLow
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }

        // Right Category Badge
        Rectangle {
            id: badgeRect
            anchors.verticalCenter: parent.verticalCenter
            height: 18
            width: badgeText.implicitWidth + 10
            radius: 5
            color: rowRoot.isSelected ? TitanTheme.alphaColor(TitanTheme.crust, 0.25) : TitanTheme.stateHover
            visible: rowRoot.modelItem && rowRoot.modelItem.badge !== undefined

            Text {
                id: badgeText
                anchors.centerIn: parent
                text: rowRoot.modelItem ? (rowRoot.modelItem.badge || "") : ""
                font.family: TitanTheme.fontFamily
                font.pixelSize: 9
                font.weight: TitanTheme.weightSemiBold
                color: rowRoot.isSelected ? TitanTheme.textOnAccent : TitanTheme.textMid
            }
        }
    }

    MouseArea {
        id: rowHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: rowRoot.hovered()
        onClicked: rowRoot.activated()
    }
}
