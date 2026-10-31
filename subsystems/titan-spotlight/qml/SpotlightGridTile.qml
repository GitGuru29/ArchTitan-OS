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

    scale: tileMouse.pressed ? 0.95 : ((isSelected || tileMouse.containsMouse) ? 1.035 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: 140; easing.type: Easing.OutBack }
    }

    // Outer ambient glow halo when selected/hovered
    Rectangle {
        anchors.fill: tileBody
        anchors.margins: -3
        radius: 22
        z: -1
        color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.22)
        visible: tileRoot.isSelected || tileMouse.containsMouse
        opacity: tileRoot.isSelected ? 1.0 : (tileMouse.containsMouse ? 0.65 : 0.0)
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
                       ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, TitanTheme.isDark ? 0.26 : 0.18)
                       : (tileMouse.containsMouse
                          ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.06))
                          : (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.045) : Qt.rgba(1, 1, 1, 0.72)))
            }
            GradientStop {
                position: 1.0
                color: tileRoot.isSelected
                       ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, TitanTheme.isDark ? 0.12 : 0.08)
                       : (tileMouse.containsMouse
                          ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.03))
                          : (TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.22) : Qt.rgba(1, 1, 1, 0.52)))
            }
        }

        border.width: tileRoot.isSelected ? 1.5 : 1
        border.color: tileRoot.isSelected
                      ? TitanTheme.accent
                      : (tileMouse.containsMouse
                         ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.45)
                         : (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)))

        Behavior on border.color { ColorAnimation { duration: 110 } }

        // Specular top glass highlight strip
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 28
            height: 1
            color: tileRoot.isSelected
                   ? Qt.rgba(1, 1, 1, 0.45)
                   : (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.85))
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
                   : (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.06))
            border.width: 1
            border.color: tileRoot.isSelected
                          ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.6)
                          : (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06))

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

            // Frosted Icon Pedestal
            Rectangle {
                id: iconPedestal
                width: 52
                height: 52
                radius: 15
                anchors.horizontalCenter: parent.horizontalCenter
                color: TitanTheme.isDark
                       ? (tileRoot.isSelected ? Qt.rgba(0, 0, 0, 0.38) : Qt.rgba(0, 0, 0, 0.32))
                       : Qt.rgba(1, 1, 1, 0.85)
                border.width: 1
                border.color: tileRoot.isSelected
                              ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.55)
                              : (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))

                Image {
                    id: appIcon
                    anchors.centerIn: parent
                    width: 34
                    height: 34
                    source: modelItem && modelItem.icon ? "image://icon/" + modelItem.icon : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true

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

