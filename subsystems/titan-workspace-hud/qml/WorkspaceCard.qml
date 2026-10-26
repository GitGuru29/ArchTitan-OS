import QtQuick
import QtQuick.Controls

Rectangle {
    id: card
    property int wsId: 1
    property bool isActive: false
    property var windowList: []
    property int winCount: 0

    width: 236
    height: 136
    radius: 16

    color: isActive ? "#D9181825" : (dropArea.containsDrag ? "#4000D2FF" : (cardMouse.containsMouse ? "#B3252838" : "#8C1E1E2E"))
    border.color: isActive ? "#00D2FF" : (dropArea.containsDrag ? "#00D2FF" : (cardMouse.containsMouse ? "#26FFFFFF" : "#12FFFFFF"))
    border.width: isActive || dropArea.containsDrag ? 2 : 1.5

    Behavior on color { ColorAnimation { duration: 160 } }
    Behavior on border.color { ColorAnimation { duration: 160 } }

    // Direct Keyboard Shortcut Pill (󰘳 1 .. 󰘳 0)
    Rectangle {
        id: shortcutPill
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 8
        width: shortcutText.implicitWidth + 12
        height: 18
        radius: 6
        color: isActive ? "#3300D2FF" : "#B311111B"
        border.color: isActive ? "#8000D2FF" : "#1AFFFFFF"
        border.width: 1
        z: 5

        Text {
            id: shortcutText
            anchors.centerIn: parent
            text: "󰘳 " + (wsId === 10 ? "0" : wsId.toString())
            font.family: "JetBrainsMono Nerd Font, monospace"
            font.pixelSize: 10
            font.bold: true
            color: isActive ? "#00D2FF" : "#80CDD6F4"
        }
    }

    // Window Count Badge (Visible on busy spaces >= 3 windows)
    Rectangle {
        id: countPill
        visible: winCount >= 3
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8
        width: countText.implicitWidth + 12
        height: 18
        radius: 6
        color: "#CC11111B"
        border.color: "#1AFFFFFF"
        border.width: 1
        z: 5

        Text {
            id: countText
            anchors.centerIn: parent
            text: winCount + " wins"
            font.family: "Inter, sans-serif"
            font.pixelSize: 9
            font.weight: Font.DemiBold
            color: "#A6CDD6F4"
        }
    }

    // Empty Workspace: Large Elegant Centered Number
    Text {
        visible: winCount === 0
        anchors.centerIn: parent
        text: wsId.toString()
        font.family: "Inter, Noto Sans, sans-serif"
        font.pixelSize: 52
        font.bold: true
        color: isActive ? "#8C00D2FF" : "#38CDD6F4"
    }

    // Occupied Workspace: Miniature Window Tiles
    Item {
        anchors.fill: parent
        visible: winCount > 0

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
            }
        }
    }

    // Drop Area for relocating dragged windows
    DropArea {
        id: dropArea
        anchors.fill: parent
        onDropped: (drop) => {
            if (drop.source && drop.source.windowAddress) {
                hyprland.moveWindowToWorkspace(drop.source.windowAddress, wsId);
            }
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
