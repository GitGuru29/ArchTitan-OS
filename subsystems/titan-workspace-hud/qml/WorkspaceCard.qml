import QtQuick
import QtQuick.Controls
import ArchTitan.TitanUI

Rectangle {
    id: card

    property real cardWidth: 360
    property real cardHeight: 460
    property int wsId: 1
    property bool isActive: false
    property var windowList: []
    property int winCount: 0
    property bool hasAudio: false

    readonly property bool liquidGlass: (typeof AppearanceSettings !== "undefined" &&
                                         AppearanceSettings.glassmorphism !== undefined)
                                        ? AppearanceSettings.glassmorphism !== false
                                        : true

    width: cardWidth
    height: cardHeight
    radius: 16
    clip: true

    color: isActive ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b,
                              liquidGlass ? 0.14 : 0.24)
                    : (dropArea.containsDrag ? (liquidGlass ? TitanTheme.accentSofter : TitanTheme.accentSoft)
                                             : (cardMouse.containsMouse ? (liquidGlass ? TitanTheme.glassCard : TitanTheme.bg3)
                                                                        : (liquidGlass ? TitanTheme.glassAlt : TitanTheme.bg1)))
    border.width: isActive || dropArea.containsDrag ? 2 : 1
    border.color: isActive || dropArea.containsDrag ? TitanTheme.accentEdge : TitanTheme.borderSubtle

    Behavior on color { ColorAnimation { duration: 180 } }
    Behavior on border.color { ColorAnimation { duration: 180 } }

    // Liquid-glass body sheen and refraction lip.
    Rectangle {
        anchors.fill: parent
        visible: card.liquidGlass
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#24FFFFFF" }
            GradientStop { position: 0.45; color: "#05FFFFFF" }
            GradientStop { position: 1.0; color: "#12000000" }
        }
        z: 1
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 1
        visible: card.liquidGlass
        color: Qt.rgba(1, 1, 1, 0.38)
        z: 3
    }

    Rectangle {
        anchors.fill: parent
        radius: card.radius
        color: "transparent"
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: 1
        visible: card.liquidGlass
        z: 3
    }

    Rectangle {
        id: shortcutPill
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10
        width: shortcutText.implicitWidth + 14
        height: 22
        radius: 7
        color: isActive ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.28)
                        : Qt.rgba(0.05, 0.05, 0.08, card.liquidGlass ? 0.42 : 0.72)
        border.color: isActive ? TitanTheme.accentEdge : TitanTheme.borderSubtle
        border.width: 1
        z: 5

        Text {
            id: shortcutText
            anchors.centerIn: parent
            text: "󰘳 " + (wsId === 10 ? "0" : wsId.toString())
            font.family: "JetBrainsMono Nerd Font, monospace"
            font.pixelSize: 11
            font.bold: true
            color: isActive ? TitanTheme.accent : TitanTheme.textMid
        }
    }

    Rectangle {
        id: audioPill
        visible: hasAudio
        anchors.top: parent.top
        anchors.right: countPill.visible ? countPill.left : parent.right
        anchors.margins: 10
        anchors.rightMargin: countPill.visible ? 6 : 10
        width: 26
        height: 22
        radius: 7
        color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.18)
        border.color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.48)
        border.width: 1
        z: 6

        Text {
            anchors.centerIn: parent
            text: "󰕾"
            font.pixelSize: 12
            color: TitanTheme.success

            SequentialAnimation on opacity {
                running: hasAudio
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 600; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
            }
        }
    }

    Rectangle {
        id: countPill
        visible: winCount >= 3
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: countText.implicitWidth + 14
        height: 22
        radius: 7
        color: Qt.rgba(0.05, 0.05, 0.08, card.liquidGlass ? 0.46 : 0.78)
        border.color: TitanTheme.borderSubtle
        border.width: 1
        z: 5

        Text {
            id: countText
            anchors.centerIn: parent
            text: winCount + " wins"
            font.family: "Inter, sans-serif"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: TitanTheme.textMid
        }
    }

    Text {
        anchors.centerIn: parent
        text: wsId.toString()
        font.family: "Inter, Noto Sans, sans-serif"
        font.pixelSize: Math.min(220, cardHeight * 0.46)
        font.bold: true
        color: isActive ? TitanTheme.accent : TitanTheme.textHigh
        opacity: winCount === 0 ? 0.82 : 0.14
        z: 0

        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    Item {
        anchors.fill: parent
        anchors.margins: 6
        visible: winCount > 0
        z: 2

        Repeater {
            model: windowList
            delegate: WindowTile {
                x: Math.max(4, (modelData.rxN || 0) * parent.width)
                y: Math.max(4, (modelData.ryN || 0) * parent.height)
                tileWidth: Math.max(36, (modelData.rwN || 0.25) * parent.width)
                tileHeight: Math.max(36, (modelData.rhN || 0.25) * parent.height)
                windowAddress: modelData.address
                appClass: modelData.class
                windowTitle: modelData.title
                iconSource: modelData.icon
                thumbnailSource: modelData.thumbnail || ""
                isFocused: modelData.isFocused || false
            }
        }
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        onDropped: (drop) => {
            if (drop.source && drop.source.windowAddress) {
                hyprland.moveWindowToWorkspace(drop.source.windowAddress, wsId);
            }
        }
    }

    Rectangle {
        id: dropHint
        anchors.centerIn: parent
        width: 124
        height: 28
        radius: 14
        color: card.liquidGlass ? TitanTheme.glassCard : TitanTheme.bg1
        border.color: TitanTheme.accentEdge
        border.width: 1
        visible: dropArea.containsDrag
        z: 30

        Text {
            anchors.centerIn: parent
            text: "Move here"
            font.family: "Inter, sans-serif"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: TitanTheme.accent
        }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!hudRoot.isDragging) {
                hyprland.switchToWorkspace(wsId);
                hudRoot.closeHud();
            }
        }
    }
}
