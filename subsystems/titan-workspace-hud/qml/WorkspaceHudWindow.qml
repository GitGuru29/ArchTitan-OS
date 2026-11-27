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

    readonly property bool liquidGlass: (typeof AppearanceSettings !== "undefined" &&
                                         AppearanceSettings.glassmorphism !== undefined)
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
        // Lighter scrim when glass is on so Hyprland's backdrop blur shows through.
        color: Qt.rgba(0.015, 0.02, 0.035, hudRoot.liquidGlass ? 0.44 : 0.80)

        Behavior on color { ColorAnimation { duration: 180 } }

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
            clip: true
            color: hudRoot.liquidGlass ? TitanTheme.glass : TitanTheme.bg1
            border.width: 1
            border.color: hudRoot.liquidGlass
                          ? Qt.rgba(1, 1, 1, 0.20)
                          : Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g,
                                    TitanTheme.accent.b, 0.18)

            Behavior on color { ColorAnimation { duration: 180 } }

            Rectangle {
                anchors.fill: parent
                visible: hudRoot.liquidGlass
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "#2AFFFFFF" }
                    GradientStop { position: 0.55; color: "#05FFFFFF" }
                    GradientStop { position: 1.0; color: "#10000000" }
                }
                z: 0
            }

            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1
                visible: hudRoot.liquidGlass
                color: Qt.rgba(1, 1, 1, 0.40)
                z: 1
            }

            TextField {
                id: searchField
                z: 2
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
                z: 2
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
