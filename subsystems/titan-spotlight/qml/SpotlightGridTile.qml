import QtQuick
import ArchTitan.TitanUI

Item {
    id: tileRoot
    width: 174
    height: 130

    property bool isSelected: false
    property var modelItem: null

    signal activated()
    signal hovered()

    scale: tileMouse.pressed ? 0.96 : ((isSelected || tileMouse.containsMouse) ? 1.03 : 1.0)
    transform: Translate {
        y: (tileRoot.isSelected || tileMouse.containsMouse) ? -2 : 0
        Behavior on y {
            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
        }
    }
    Behavior on scale {
        NumberAnimation { duration: 140; easing.type: Easing.OutBack }
    }

    // Layered 3D Ambient Drop Shadow under the tile
    Rectangle {
        id: tileDropShadow
        anchors.fill: tileBody
        anchors.topMargin: tileRoot.isSelected ? 6 : (tileMouse.containsMouse ? 5 : 3)
        anchors.bottomMargin: tileRoot.isSelected ? -6 : (tileMouse.containsMouse ? -5 : -3)
        anchors.leftMargin: -2
        anchors.rightMargin: -2
        radius: tileBody.radius + 2
        z: -2
        color: Qt.rgba(0, 0, 0, tileRoot.isSelected ? 0.65 : (tileMouse.containsMouse ? 0.52 : 0.38))
        Behavior on anchors.topMargin { NumberAnimation { duration: 120 } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 120 } }
    }

    // Outer luminous ambient glow halo when selected/hovered
    Rectangle {
        anchors.fill: tileBody
        anchors.margins: -3
        radius: tileBody.radius + 3
        z: -1
        color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.28)
        visible: tileRoot.isSelected || tileMouse.containsMouse
        opacity: tileRoot.isSelected ? 1.0 : (tileMouse.containsMouse ? 0.55 : 0.0)
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Rectangle {
        id: tileBody
        anchors.fill: parent
        radius: 19

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: tileRoot.isSelected
                       ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.35)
                       : (tileMouse.containsMouse
                          ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.90))
                          : (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.75)))
            }
            GradientStop {
                position: 1.0
                color: tileRoot.isSelected
                       ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.14)
                       : (tileMouse.containsMouse
                          ? (TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.28) : Qt.rgba(0, 0, 0, 0.04))
                          : (TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.30) : Qt.rgba(0, 0, 0, 0.06)))
            }
        }

        border.width: tileRoot.isSelected ? 1.5 : 1
        border.color: tileRoot.isSelected
                      ? TitanTheme.accent
                      : (tileMouse.containsMouse
                         ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.45)
                         : Qt.rgba(1, 1, 1, 0.09))

        Behavior on border.color { ColorAnimation { duration: 110 } }

        // Curved top specular sheen (authentic 3D glass gloss)
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 44
            radius: tileBody.radius
            z: 0
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: tileRoot.isSelected
                           ? Qt.rgba(1, 1, 1, 0.22)
                           : (tileMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.09))
                }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Top-right category badge pill
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 8
            anchors.rightMargin: 8
            height: 16
            width: badgeLabel.implicitWidth + 10
            radius: 5
            visible: modelItem && modelItem.badge !== undefined && modelItem.badge !== ""
            color: tileRoot.isSelected
                   ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.30)
                   : (TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(0, 0, 0, 0.06))
            border.width: 1
            border.color: tileRoot.isSelected
                          ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.6)
                          : Qt.rgba(1, 1, 1, 0.07)

            Text {
                id: badgeLabel
                anchors.centerIn: parent
                text: modelItem && modelItem.badge ? modelItem.badge : ""
                font.family: TitanTheme.fontFamily
                font.pixelSize: 8
                font.bold: true
                color: tileRoot.isSelected ? TitanTheme.accent : TitanTheme.textLow
            }
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - 18
            spacing: 7

            // Frosted 3D Icon Pedestal
            Rectangle {
                id: iconPedestal
                width: 52
                height: 52
                radius: 16
                anchors.horizontalCenter: parent.horizontalCenter
                color: TitanTheme.isDark
                       ? (tileRoot.isSelected ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(0, 0, 0, 0.35))
                       : Qt.rgba(1, 1, 1, 0.85)
                border.width: 1
                border.color: tileRoot.isSelected
                              ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.55)
                              : Qt.rgba(1, 1, 1, 0.08)

                // Subtle pedestal drop shadow
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 2
                    anchors.bottomMargin: -2
                    radius: parent.radius
                    z: -1
                    color: Qt.rgba(0, 0, 0, 0.35)
                }

                Image {
                    id: appIcon
                    anchors.centerIn: parent
                    width: 34
                    height: 34
                    source: modelItem && modelItem.icon ? "image://icon/" + modelItem.icon : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    scale: (tileRoot.isSelected || tileMouse.containsMouse) ? 1.08 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        visible: appIcon.status !== Image.Ready
                        text: modelItem && modelItem.type === "clipboard" ? "󰅍" : (modelItem && modelItem.type === "command" ? "󰞷" : (modelItem && modelItem.type === "system" ? "󰒓" : "󰘳"))
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 22
                        color: TitanTheme.accent
                    }
                }
            }

            // App Name & Subtitle
            Column {
                width: parent.width
                spacing: 1

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: modelItem ? modelItem.title : ""
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 13
                    font.weight: tileRoot.isSelected ? Font.Bold : Font.DemiBold
                    color: tileRoot.isSelected
                           ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 1.0) : TitanTheme.textHigh)
                           : TitanTheme.textHigh
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: modelItem ? modelItem.subtitle : ""
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    color: tileRoot.isSelected ? TitanTheme.textMid : TitanTheme.textLow
                    elide: Text.ElideRight
                }
            }
        }
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: tileRoot.hovered()
        onClicked: tileRoot.activated()
    }
}

