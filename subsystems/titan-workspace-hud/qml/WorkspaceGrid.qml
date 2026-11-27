import QtQuick
import ArchTitan.TitanUI

Item {
    id: gridContainer

    property string searchText: ""

    readonly property bool liquidGlass: AppearanceSettings.glassmorphism !== false
    readonly property int columns: 5
    readonly property int rows: 2
    readonly property int spacing: 8
    readonly property real cellWidth: (width - spacing * (columns - 1)) / columns
    readonly property real cellHeight: (height - spacing * (rows - 1)) / rows
    readonly property int outerRadius: 24

    property int activeWorkspaceId: {
        var spaces = hyprland.workspaces || [];
        for (var i = 0; i < spaces.length; ++i) {
            if (spaces[i].active) return spaces[i].id;
        }
        return -1;
    }

    readonly property var filteredWorkspaces: {
        var raw = hyprland.workspaces || [];
        var query = searchText.trim().toLowerCase();
        if (!query) return raw;

        var result = [];
        for (var i = 0; i < raw.length; ++i) {
            var ws = raw[i];
            var matchesWorkspace = String(ws.id).indexOf(query) >= 0;
            var windows = [];
            var list = ws.windows || [];
            for (var j = 0; j < list.length; ++j) {
                var win = list[j];
                var haystack = ((win.title || "") + " " + (win.class || "")).toLowerCase();
                if (matchesWorkspace || haystack.indexOf(query) >= 0) windows.push(win);
            }
            if (!matchesWorkspace && windows.length === 0) continue;

            var copy = {};
            for (var key in ws) copy[key] = ws[key];
            copy.windows = windows;
            copy.windowCount = windows.length;
            result.push(copy);
        }
        return result;
    }

    readonly property int activeIndex: {
        var list = filteredWorkspaces;
        for (var i = 0; i < list.length; ++i) {
            if (list[i].id === activeWorkspaceId) return i;
        }
        return -1;
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 6
        radius: outerRadius + 6
        color: Qt.rgba(0, 0, 0, 0.45)
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
            height: 52
            visible: gridContainer.liquidGlass
            opacity: 0.5
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#4DFFFFFF" }
                GradientStop { position: 1.0; color: "#00FFFFFF" }
            }
        }

        Grid {
            id: grid
            anchors.fill: parent
            anchors.margins: 10
            columns: gridContainer.columns
            rows: gridContainer.rows
            columnSpacing: gridContainer.spacing
            rowSpacing: gridContainer.spacing

            Repeater {
                model: gridContainer.filteredWorkspaces
                delegate: WorkspaceCard {
                    cardWidth: gridContainer.cellWidth - 2
                    cardHeight: gridContainer.cellHeight - 2
                    wsId: modelData.id
                    isActive: modelData.active
                    winCount: modelData.windowCount
                    windowList: modelData.windows
                    hasAudio: modelData.hasAudio || false
                }
            }
        }

        Rectangle {
            id: focusRing
            visible: gridContainer.activeIndex >= 0
            x: grid.x + (gridContainer.activeIndex % gridContainer.columns)
                * (gridContainer.cellWidth + gridContainer.spacing)
            y: grid.y + Math.floor(gridContainer.activeIndex / gridContainer.columns)
                * (gridContainer.cellHeight + gridContainer.spacing)
            width: gridContainer.cellWidth
            height: gridContainer.cellHeight
            radius: 18
            color: "transparent"
            border.color: TitanTheme.accentEdge
            border.width: 2.5
            z: 20

            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
        }
    }
}
