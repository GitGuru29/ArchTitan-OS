import QtQuick
import QtQuick.Window

Window {
    id: hudRoot
    title: "titan-workspace-hud"
    width: 1264
    height: 320

    flags: Qt.FramelessWindowHint
    color: "transparent"
    visible: false

    property bool isDragging: false
    property bool pendingClose: false

    function openHud() {
        pendingClose = false;
        hudRoot.visible = true;
        hudRoot.requestActivate();
    }

    function closeHud() {
        if (!isDragging) {
            hudRoot.visible = false;
            pendingClose = false;
        } else {
            pendingClose = true;
        }
    }

    function toggleHud() {
        if (hudRoot.visible) {
            closeHud();
        } else {
            openHud();
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: {
            hudRoot.closeHud();
        }
    }

    WorkspaceGrid {
        id: gridItem
        anchors.centerIn: parent
    }
}
