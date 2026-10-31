import QtQuick
import ArchTitan.TitanUI

Item {
    id: bentoRoot
    width: 358
    height: 66

    property bool isSelected: false
    property var modelItem: null

    signal activated()
    signal hovered()

    scale: bentoMouse.pressed ? 0.97 : ((isSelected || bentoMouse.containsMouse) ? 1.02 : 1.0)
    y: (isSelected || bentoMouse.containsMouse) ? -2 : 0
    Behavior on scale {
        NumberAnimation { duration: 130; easing.type: Easing.OutBack }
    }
    Behavior on y {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    // Layered 3D Ambient Drop Shadow under the bento tile
    Rectangle {
        id: bentoDropShadow
        anchors.fill: bentoBody
        anchors.topMargin: bentoRoot.isSelected ? 4 : (bentoMouse.containsMouse ? 3 : 2)
        anchors.bottomMargin: bentoRoot.isSelected ? -4 : (bentoMouse.containsMouse ? -3 : -2)
        anchors.leftMargin: -1
        anchors.rightMargin: -1
        radius: bentoBody.radius + 1
        z: -2
        color: Qt.rgba(0, 0, 0, bentoRoot.isSelected ? 0.55 : (bentoMouse.containsMouse ? 0.45 : 0.30))
        Behavior on anchors.topMargin { NumberAnimation { duration: 120 } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 120 } }
    }

    // Outer luminous ambient glow halo when selected/hovered
    Rectangle {
        anchors.fill: bentoBody
        anchors.margins: -2
        radius: bentoBody.radius + 2
        z: -1
        color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.22)
        visible: bentoRoot.isSelected || bentoMouse.containsMouse
        opacity: bentoRoot.isSelected ? 1.0 : (bentoMouse.containsMouse ? 0.50 : 0.0)
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Rectangle {
        id: bentoBody
        anchors.fill: parent
        radius: 16

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: bentoRoot.isSelected
                       ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, TitanTheme.isDark ? 0.26 : 0.18)
                       : (bentoMouse.containsMouse
                          ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))
                          : (TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(1, 1, 1, 0.70)))
            }
            GradientStop {
                position: 1.0
                color: bentoRoot.isSelected
                       ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, TitanTheme.isDark ? 0.11 : 0.08)
                       : (bentoMouse.containsMouse
                          ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(0, 0, 0, 0.03))
                          : (TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.50) : Qt.rgba(1, 1, 1, 0.50)))
            }
        }

        border.width: bentoRoot.isSelected ? 1.5 : (bentoMouse.containsMouse ? 1 : 0)
        border.color: bentoRoot.isSelected
                      ? TitanTheme.accent
                      : (bentoMouse.containsMouse
                         ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.40)
                         : "transparent")

        Behavior on border.color { ColorAnimation { duration: 110 } }

        // Left active indicator pill
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 24
            radius: 2
            color: TitanTheme.accent
            visible: bentoRoot.isSelected
        }

        Item {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            // Frosted 3D Icon Pedestal
            Rectangle {
                id: iconTile
                width: 44
                height: 44
                radius: 13
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.40) : Qt.rgba(1, 1, 1, 0.82)
                border.width: bentoRoot.isSelected ? 1 : 0
                border.color: bentoRoot.isSelected
                              ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.5)
                              : "transparent"

                // Subtle pedestal drop shadow
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 2
                    anchors.bottomMargin: -2
                    radius: parent.radius
                    z: -1
                    color: Qt.rgba(0, 0, 0, 0.28)
                }

                Image {
                    id: appIcon
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    source: modelItem && modelItem.icon ? "image://icon/" + modelItem.icon : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    scale: (bentoRoot.isSelected || bentoMouse.containsMouse) ? 1.08 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120 } }

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

            // Title & Subtitle
            Column {
                anchors.left: iconTile.right
                anchors.leftMargin: 11
                anchors.right: rightBadge.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: modelItem ? modelItem.title : ""
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 13
                    font.weight: bentoRoot.isSelected ? Font.Bold : Font.DemiBold
                    color: bentoRoot.isSelected
                           ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 1.0) : TitanTheme.textHigh)
                           : TitanTheme.textHigh
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: modelItem ? modelItem.subtitle : ""
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    color: bentoRoot.isSelected ? TitanTheme.textMid : TitanTheme.textLow
                    elide: Text.ElideRight
                }
            }

            // Right badge / launch indicator
            Rectangle {
                id: rightBadge
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 22
                width: rightText.implicitWidth + 12
                radius: 6
                color: bentoRoot.isSelected
                       ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.28)
                       : (TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(0, 0, 0, 0.05))
                border.width: bentoRoot.isSelected ? 1 : 0
                border.color: bentoRoot.isSelected ? TitanTheme.accent : "transparent"

                Text {
                    id: rightText
                    anchors.centerIn: parent
                    text: (bentoRoot.isSelected || bentoMouse.containsMouse)
                          ? "⏎"
                          : (modelItem && modelItem.badge ? modelItem.badge : "APP")
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: (bentoRoot.isSelected || bentoMouse.containsMouse) ? 11 : 9
                    font.bold: true
                    color: bentoRoot.isSelected ? TitanTheme.accent : TitanTheme.textLow
                }
            }
        }
    }

    MouseArea {
        id: bentoMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: bentoRoot.hovered()
        onClicked: bentoRoot.activated()
    }
}

