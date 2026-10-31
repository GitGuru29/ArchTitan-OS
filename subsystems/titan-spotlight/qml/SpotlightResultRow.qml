import QtQuick
import ArchTitan.TitanUI

Rectangle {
    id: rowRoot
    width: parent.width
    height: 54
    radius: 14

    property bool isSelected: false
    property var modelItem: null

    signal activated()
    signal hovered()

    scale: rowHover.pressed ? 0.98 : ((isSelected || rowHover.containsMouse) ? 1.01 : 1.0)
    y: (isSelected || rowHover.containsMouse) ? -1 : 0
    Behavior on scale { NumberAnimation { duration: 110 } }
    Behavior on y { NumberAnimation { duration: 110 } }

    // 3D Drop Shadow behind selected/hovered row
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: rowRoot.isSelected ? 3 : 2
        anchors.bottomMargin: rowRoot.isSelected ? -3 : -2
        radius: rowRoot.radius + 1
        z: -1
        color: Qt.rgba(0, 0, 0, rowRoot.isSelected ? 0.45 : (rowHover.containsMouse ? 0.35 : 0.0))
        visible: rowRoot.isSelected || rowHover.containsMouse
    }

    gradient: Gradient {
        GradientStop {
            position: 0.0
            color: rowRoot.isSelected
                   ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, TitanTheme.isDark ? 0.24 : 0.16)
                   : (rowHover.containsMouse
                      ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.065) : Qt.rgba(0, 0, 0, 0.045))
                      : "transparent")
        }
        GradientStop {
            position: 1.0
            color: rowRoot.isSelected
                   ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, TitanTheme.isDark ? 0.11 : 0.08)
                   : (rowHover.containsMouse
                      ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(0, 0, 0, 0.02))
                      : "transparent")
        }
    }

    border.width: rowRoot.isSelected ? 1.5 : (rowHover.containsMouse ? 1 : 0)
    border.color: rowRoot.isSelected
                  ? TitanTheme.accent
                  : (rowHover.containsMouse
                     ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.35)
                     : "transparent")

    // Left active glow bar
    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: 24
        radius: 2
        color: TitanTheme.accent
        visible: rowRoot.isSelected
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14

        // Icon Tile
        Rectangle {
            id: iconTile
            width: 38
            height: 38
            radius: 11
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.38) : Qt.rgba(1, 1, 1, 0.80)
            border.width: rowRoot.isSelected ? 1 : 0
            border.color: rowRoot.isSelected
                          ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.45)
                          : "transparent"

            // 3D subtle icon pedestal shadow
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 2
                anchors.bottomMargin: -2
                radius: parent.radius
                z: -1
                color: Qt.rgba(0, 0, 0, 0.25)
            }

            Image {
                id: appIcon
                anchors.centerIn: parent
                width: 26
                height: 26
                source: modelItem && modelItem.icon ? "image://icon/" + modelItem.icon : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true

                Text {
                    anchors.centerIn: parent
                    visible: appIcon.status !== Image.Ready
                    text: modelItem && modelItem.type === "clipboard" ? "󰅍" : (modelItem && modelItem.type === "command" ? "󰞷" : (modelItem && modelItem.type === "system" ? "󰒓" : "󰘳"))
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
            anchors.right: rightPack.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: modelItem ? modelItem.title : ""
                font.family: TitanTheme.fontFamily
                font.pixelSize: 14
                font.weight: rowRoot.isSelected ? Font.Bold : Font.DemiBold
                color: rowRoot.isSelected
                       ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 1.0) : TitanTheme.textHigh)
                       : TitanTheme.textHigh
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: modelItem ? modelItem.subtitle : ""
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                color: rowRoot.isSelected ? TitanTheme.textMid : TitanTheme.textLow
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Right side Category Badge + Action Pill
        Row {
            id: rightPack
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            spacing: 8

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                height: 20
                width: catLabel.implicitWidth + 12
                radius: 6
                visible: modelItem && modelItem.badge !== undefined && modelItem.badge !== ""
                color: TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(0, 0, 0, 0.05)
                border.width: 0

                Text {
                    id: catLabel
                    anchors.centerIn: parent
                    text: modelItem && modelItem.badge ? modelItem.badge : ""
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                    color: rowRoot.isSelected ? TitanTheme.textHigh : TitanTheme.textLow
                }
            }

            Rectangle {
                id: actionPill
                anchors.verticalCenter: parent.verticalCenter
                width: 68
                height: 24
                radius: 7
                color: rowRoot.isSelected
                       ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.28)
                       : (TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.30) : Qt.rgba(0, 0, 0, 0.05))
                border.width: rowRoot.isSelected ? 1 : 0
                border.color: rowRoot.isSelected ? TitanTheme.accent : "transparent"
                visible: rowRoot.isSelected || rowHover.containsMouse

                Text {
                    anchors.centerIn: parent
                    text: modelItem && modelItem.type === "clipboard" ? "⏎ Paste" : (modelItem && modelItem.type === "command" ? "⏎ Run" : "⏎ Open")
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: rowRoot.isSelected ? TitanTheme.accent : TitanTheme.textMid
                }
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
