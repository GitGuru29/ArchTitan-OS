import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

Item {
    id: gridContainer

    width: 1264
    height: 320

    readonly property bool liquidGlass: (typeof AppearanceSettings !== "undefined" && AppearanceSettings.glassmorphism !== undefined) ? (AppearanceSettings.glassmorphism !== false) : true
    readonly property int cellWidth: 236
    readonly property int cellHeight: 136
    readonly property int cellSpacing: 12
    readonly property int outerRadius: 28

    function findActiveIndex() {
        var spaces = hyprland.workspaces || [];
        for (var i = 0; i < spaces.length; ++i) {
            if (spaces[i].active) return Math.min(i, 9);
        }
        return -1;
    }

    readonly property int activeIndex: findActiveIndex()

    // Soft elevation shadow beneath the overview sheet (host-style).
    Rectangle {
        anchors.fill: parent
        anchors.margins: 6
        radius: outerRadius + 8
        color: Qt.rgba(0, 0, 0, 0.42)
        z: -1
    }

    Rectangle {
        id: glassSurface
        anchors.fill: parent
        radius: outerRadius
        color: gridContainer.liquidGlass ? TitanTheme.glassCard : TitanTheme.bg1
        border.width: 1
        border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g,
                              TitanTheme.accent.b, gridContainer.liquidGlass ? 0.45 : 0.18)
        clip: true

        Rectangle {
            anchors.fill: parent
            visible: gridContainer.liquidGlass
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#26FFFFFF" }
                GradientStop { position: 0.42; color: "#08FFFFFF" }
                GradientStop { position: 1.0; color: "#12000000" }
            }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 46
            visible: gridContainer.liquidGlass
            opacity: 0.5
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#4DFFFFFF" }
                GradientStop { position: 1.0; color: "#00FFFFFF" }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: outerRadius
            color: "transparent"
            border.width: 1
            border.color: "#14FFFFFF"
        }

        Grid {
            id: grid
            anchors.centerIn: parent
            columns: 5
            rows: 2
            columnSpacing: gridContainer.cellSpacing
            rowSpacing: gridContainer.cellSpacing

            Repeater {
                model: hyprland.workspaces
                delegate: WorkspaceCard {
                    cardIndex: index
                    wsId: modelData.id
                    isActive: modelData.active
                    winCount: modelData.windowCount
                    windowList: modelData.windows
                    hasAudio: modelData.hasAudio || false
                }
            }
        }

        // Host-style moving focus ring: the active workspace keeps its own
        // tinted card, while this accent outline slides between cells.
        Rectangle {
            id: focusRing
            visible: gridContainer.activeIndex >= 0
            x: grid.x + (gridContainer.activeIndex % 5) * (gridContainer.cellWidth + gridContainer.cellSpacing)
            y: grid.y + Math.floor(gridContainer.activeIndex / 5) * (gridContainer.cellHeight + gridContainer.cellSpacing)
            width: gridContainer.cellWidth
            height: gridContainer.cellHeight
            radius: 16
            color: "transparent"
            border.color: TitanTheme.accentEdge
            border.width: 2.5
            z: 20

            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
        }
    }
}
