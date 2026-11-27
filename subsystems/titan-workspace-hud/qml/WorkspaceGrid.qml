import QtQuick
import ArchTitan.TitanUI

Item {
    id: gridContainer

    property string searchText: ""

    readonly property bool liquidGlass: (typeof AppearanceSettings !== "undefined" &&
                                         AppearanceSettings.glassmorphism !== undefined)
                                        ? AppearanceSettings.glassmorphism !== false
                                        : true
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
        color: Qt.rgba(0, 0, 0, gridContainer.liquidGlass ? 0.32 : 0.62)
        z: -1

        Behavior on color { ColorAnimation { duration: 180 } }
    }

    Rectangle {
        id: glassSurface
        anchors.fill: parent
        radius: outerRadius
        color: gridContainer.liquidGlass ? TitanTheme.glass : TitanTheme.bg0
        border.width: 1
        border.color: gridContainer.liquidGlass
                      ? Qt.rgba(1, 1, 1, 0.18)
                      : Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g,
                                TitanTheme.accent.b, 0.18)
        clip: true

        Behavior on color { ColorAnimation { duration: 180 } }

        // Frosted body: white at the top, dark vignette at the bottom.
        Rectangle {
            anchors.fill: parent
            visible: gridContainer.liquidGlass
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#2EFFFFFF" }
                GradientStop { position: 0.38; color: "#0AFFFFFF" }
                GradientStop { position: 1.0; color: "#16000000" }
            }
        }

        // Specular top lip — the bright refraction edge of liquid glass.
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 1.5
            visible: gridContainer.liquidGlass
            color: Qt.rgba(1, 1, 1, 0.42)
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 64
            visible: gridContainer.liquidGlass
            opacity: 0.55
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#66FFFFFF" }
                GradientStop { position: 1.0; color: "#00FFFFFF" }
            }
        }

        // Slow travelling highlight, like the host shell's glass sweep.
        Rectangle {
            id: specularSweep
            anchors.verticalCenter: parent.verticalCenter
            width: 220
            height: parent.height * 2
            rotation: -18
            visible: gridContainer.liquidGlass
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#00FFFFFF" }
                GradientStop { position: 0.5; color: "#1AFFFFFF" }
                GradientStop { position: 1.0; color: "#00FFFFFF" }
            }

            NumberAnimation on x {
                from: -260
                to: glassSurface.width + 260
                duration: 9000
                loops: Animation.Infinite
                easing.type: Easing.Linear
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

        // Inner rim keeps the glass edge visible over the workspace cards.
        Rectangle {
            anchors.fill: parent
            radius: outerRadius
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.10)
            border.width: 1
            visible: gridContainer.liquidGlass
            z: 24
        }
    }
}
