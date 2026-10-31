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
                       ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.40)
                       : (tileMouse.containsMouse
                          ? Qt.rgba(1, 1, 1, 0.24)
                          : Qt.rgba(1, 1, 1, 0.12))
            }
            GradientStop {
                position: 1.0
                color: tileRoot.isSelected
                       ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.18)
                       : (tileMouse.containsMouse
                          ? Qt.rgba(1, 1, 1, 0.08)
                          : Qt.rgba(1, 1, 1, 0.04))
            }
        }

        border.width: tileRoot.isSelected ? 1.5 : 1
        border.color: tileRoot.isSelected
                      ? TitanTheme.accent
                      : (tileMouse.containsMouse
                         ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.50)
                         : Qt.rgba(1, 1, 1, 0.12))

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
                           ? Qt.rgba(1, 1, 1, 0.28)
                           : (tileMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.12))
                }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Top Specular Horizon Glint (3D beveled edge light)
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 24
            height: 1
            radius: 1
            z: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: tileRoot.isSelected ? Qt.rgba(1, 1, 1, 0.60) : Qt.rgba(1, 1, 1, 0.28) }
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
                   ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.32)
                   : Qt.rgba(1, 1, 1, 0.10)
            border.width: 1
            border.color: tileRoot.isSelected
                          ? TitanTheme.accent
                          : Qt.rgba(1, 1, 1, 0.14)

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
                color: tileRoot.isSelected
                       ? Qt.rgba(1, 1, 1, 0.20)
                       : (tileMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.09))
                border.width: 1
                border.color: tileRoot.isSelected
                              ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.60)
                              : Qt.rgba(1, 1, 1, 0.16)

                // Top specular sheen inside icon squircle
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 18
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.18) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
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

