import QtQuick
import ArchTitan.TitanUI

Item {
    id: tileRoot
    width: 104
    height: 92

    property bool isSelected: false
    property var modelItem: null

    signal activated()
    signal hovered()

    scale: tileMouse.pressed ? 0.94 : ((isSelected || tileMouse.containsMouse) ? 1.08 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
    }

    Column {
        anchors.centerIn: parent
        spacing: 6
        width: parent.width

        // Squircle Icon Container
        Item {
            id: iconBox
            width: 52
            height: 52
            anchors.horizontalCenter: parent.horizontalCenter

            // Outer Soft Ambient Aura when selected or hovered
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 12
                height: parent.height + 12
                radius: 18
                color: TitanTheme.alphaColor(TitanTheme.accent, 0.40)
                visible: tileRoot.isSelected || tileMouse.containsMouse
                opacity: tileRoot.isSelected ? 1.0 : 0.6
                z: -1

                Behavior on opacity {
                    NumberAnimation { duration: TitanTheme.durFast }
                }
            }

            // Squircle Surface (clips icon to smooth rounded squircle)
            Rectangle {
                id: squircleBg
                anchors.fill: parent
                radius: 14
                clip: true
                color: Qt.rgba(1, 1, 1, 0.08)
                border.width: tileRoot.isSelected ? 1.5 : 1
                border.color: tileRoot.isSelected
                              ? TitanTheme.accent
                              : (tileMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.12))

                // App Icon Image
                Image {
                    id: appIcon
                    anchors.fill: parent
                    anchors.margins: 1
                    source: modelItem && modelItem.icon ? "image://icon/" + modelItem.icon : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    mipmap: true

                    // Fallback Glyph if image isn't available
                    Text {
                        anchors.centerIn: parent
                        visible: appIcon.status !== Image.Ready
                        text: {
                            if (!modelItem) return "󰀻";
                            if (modelItem.type === "clipboard") return "󰅍";
                            if (modelItem.type === "command") return "󰞷";
                            if (modelItem.type === "system") return "󰒓";
                            return "󰀻";
                        }
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 24
                        color: tileRoot.isSelected ? TitanTheme.accent : TitanTheme.textHigh
                    }
                }

                // Top Specular Sheen (3D Glass Glint)
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 18
                    radius: parent.radius
                    z: 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.22) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
            }
        }

        // App Name Label Underneath
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 6
            horizontalAlignment: Text.AlignHCenter
            text: modelItem ? modelItem.title : ""
            font.family: TitanTheme.fontFamily
            font.pixelSize: 11
            font.weight: tileRoot.isSelected ? Font.DemiBold : Font.Normal
            color: tileRoot.isSelected ? "#FFFFFF" : TitanTheme.textHigh
            elide: Text.ElideRight
            maximumLineCount: 1
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
