import QtQuick
import QtQuick.Controls
import ArchTitan.TitanUI

Rectangle {
    id: card

    property int cardIndex: 0
    property int wsId: 1
    property bool isActive: false
    property var windowList: []
    property int winCount: 0
    property bool hasAudio: false

    width: 236
    height: 136
    radius: 16

    color: isActive ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.14)
                    : (dropArea.containsDrag ? TitanTheme.accentSofter
                                             : (cardMouse.containsMouse ? TitanTheme.bg4 : TitanTheme.glassAlt))
    border.width: isActive || dropArea.containsDrag ? 2 : 1
    border.color: isActive || dropArea.containsDrag ? TitanTheme.accentEdge : TitanTheme.borderSubtle

    Behavior on color { ColorAnimation { duration: 160 } }
    Behavior on border.color { ColorAnimation { duration: 160 } }

    // Direct keyboard shortcut pill (󰘳 1 .. 󰘳 0)
    Rectangle {
        id: shortcutPill
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 8
        width: shortcutText.implicitWidth + 12
        height: 18
        radius: 6
        color: isActive ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.28)
                        : Qt.rgba(0.05, 0.05, 0.08, 0.66)
        border.color: isActive ? TitanTheme.accentEdge : TitanTheme.borderSubtle
        border.width: 1
        z: 5

        Text {
            id: shortcutText
            anchors.centerIn: parent
            text: "󰘳 " + (wsId === 10 ? "0" : wsId.toString())
            font.family: "JetBrainsMono Nerd Font, monospace"
            font.pixelSize: 10
            font.bold: true
            color: isActive ? TitanTheme.accent : TitanTheme.textMid
        }
    }

    // Pulsing audio badge
    Rectangle {
        id: audioPill
        visible: hasAudio
        anchors.top: parent.top
        anchors.right: countPill.visible ? countPill.left : parent.right
        anchors.margins: 8
        anchors.rightMargin: countPill.visible ? 4 : 8
        width: 22
        height: 18
        radius: 6
        color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.18)
        border.color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.48)
        border.width: 1
        z: 6

        Text {
            anchors.centerIn: parent
            text: "󰕾"
            font.pixelSize: 10
            color: TitanTheme.success

            SequentialAnimation on opacity {
                running: hasAudio
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 600; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
            }
        }
    }

    // Window count badge
    Rectangle {
        id: countPill
        visible: winCount >= 3
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8
        width: countText.implicitWidth + 12
        height: 18
        radius: 6
        color: Qt.rgba(0.05, 0.05, 0.08, 0.74)
        border.color: TitanTheme.borderSubtle
        border.width: 1
        z: 5

        Text {
            id: countText
            anchors.centerIn: parent
            text: winCount + " wins"
            font.family: "Inter, sans-serif"
            font.pixelSize: 9
            font.weight: Font.DemiBold
            color: TitanTheme.textMid
        }
    }

    // Host-style large workspace number, always present behind live tiles.
    Text {
        anchors.centerIn: parent
        text: wsId.toString()
        font.family: "Inter, Noto Sans, sans-serif"
        font.pixelSize: 52
        font.bold: true
        color: isActive ? TitanTheme.accent : TitanTheme.textHigh
        opacity: winCount === 0 ? 0.82 : 0.16
        z: 0

        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    // Live miniature window tiles
    Item {
        anchors.fill: parent
        visible: winCount > 0
        z: 2

        Repeater {
            model: windowList
            delegate: WindowTile {
                x: modelData.rx
                y: modelData.ry
                tileWidth: modelData.rw
                tileHeight: modelData.rh
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
        width: 100
        height: 24
        radius: 12
        color: TitanTheme.glassCard
        border.color: TitanTheme.accentEdge
        border.width: 1
        visible: dropArea.containsDrag
        z: 30

        Text {
            anchors.centerIn: parent
            text: "Move here"
            font.family: "Inter, sans-serif"
            font.pixelSize: 10
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
