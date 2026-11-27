import QtQuick
import QtQuick.Window
import QtQuick.Controls
import ArchTitan.TitanUI

Window {
    id: hudRoot
    title: "titan-workspace-hud"
    width: Screen.desktopAvailableWidth
    height: Screen.desktopAvailableHeight

    flags: Qt.FramelessWindowHint
    color: "transparent"
    visible: false

    readonly property bool liquidGlass: (typeof AppearanceSettings !== "undefined")
                                        ? AppearanceSettings.glassmorphism !== false
                                        : true

    property bool isDragging: false
    property bool pendingClose: false
    property bool isOpen: false
    property string searchText: ""

    function openHud() {
        pendingClose = false;
        searchText = "";
        searchField.text = "";
        hudRoot.visible = true;
        hudRoot.isOpen = true;
        hudRoot.requestActivate();
        searchField.forceActiveFocus();
    }

    function closeHud() {
        if (!isDragging) {
            hudRoot.isOpen = false;
            hudRoot.visible = false;
            pendingClose = false;
        } else {
            pendingClose = true;
        }
    }

    function toggleHud() {
        if (hudRoot.visible) closeHud();
        else openHud();
    }

    function switchWorkspace(wsId) {
        hyprland.switchToWorkspace(wsId);
        hudRoot.closeHud();
    }

    // Dimmed full-screen scrim, like the host overview. Clicking away closes.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.015, 0.02, 0.035, 0.76)

        MouseArea {
            anchors.fill: parent
            onClicked: hudRoot.closeHud()
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: hudRoot.closeHud()
        Keys.onPressed: (event) => {
            var ws = 0;
            if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                ws = event.key - Qt.Key_1 + 1;
            } else if (event.key === Qt.Key_0) {
                ws = 10;
            }
            if (ws > 0) {
                hudRoot.switchWorkspace(ws);
                event.accepted = true;
            }
        }
    }

    Column {
        id: overviewColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 42
        width: Math.min(parent.width - 48, 1680)
        spacing: 12

        Rectangle {
            id: searchBar
            width: parent.width
            height: 46
            radius: 14
            color: hudRoot.liquidGlass ? TitanTheme.glassCard : TitanTheme.bg1
            border.width: 1
            border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g,
                                  TitanTheme.accent.b, hudRoot.liquidGlass ? 0.42 : 0.18)

            TextField {
                id: searchField
                anchors.fill: parent
                leftPadding: 16
                rightPadding: 92
                verticalAlignment: TextInput.AlignVCenter
                background: null
                color: TitanTheme.textHigh
                placeholderText: "Search windows or workspaces…"
                placeholderTextColor: TitanTheme.textLow
                font.pixelSize: 14
                selectByMouse: true
                onTextChanged: hudRoot.searchText = text
                Keys.onEscapePressed: hudRoot.closeHud()
                Keys.onPressed: (event) => {
                    var ws = 0;
                    if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                        ws = event.key - Qt.Key_1 + 1;
                    } else if (event.key === Qt.Key_0) {
                        ws = 10;
                    }
                    if (ws > 0) {
                        hudRoot.switchWorkspace(ws);
                        event.accepted = true;
                    }
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "1–0 switch · Esc close"
                font.family: "Inter, sans-serif"
                font.pixelSize: 10
                color: TitanTheme.textLow
            }
        }

        WorkspaceGrid {
            id: gridItem
            width: parent.width
            height: Math.min(hudRoot.height - overviewColumn.anchors.topMargin - 112, 820)
            searchText: hudRoot.searchText
        }
    }
}
