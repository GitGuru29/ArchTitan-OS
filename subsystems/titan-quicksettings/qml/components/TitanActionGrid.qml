import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanActionGrid — macOS Control Center Frameless Utility Squircles Grid.
 *
 * Features:
 * - Completely frameless container (no outer box border)
 * - No header clutter in normal mode (pure macOS squircle tiles)
 * - In Edit Controls mode:
 *   - Drag and drop any tile to reorder
 *   - Bottom-right corner resize handle (◢) on tiles to toggle Compact (1x1) vs Wide (2x1)
 *   - Quick nudge arrows (◄ / ►)
 */
Item {
    id: gridCardRoot
    Layout.fillWidth: true
    implicitHeight: actionCol.implicitHeight

    property int revision: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.tileVisibilityRevision : 0
    property string sizeMode: (typeof systemCtrl !== "undefined" && systemCtrl)
                              ? systemCtrl.getWidgetSize("actionGrid", "compact")
                              : "compact" // "compact" (4 cols) or "wide" (2 cols)

    readonly property var actionCatalog: ({
        "capture": {
            key: "capture",
            title: "Screenshot",
            icon: "\uf030", // camera
            active: false,
            status: "Region",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.triggerScreenshot(); }
        },
        "record": {
            key: "record",
            title: "Screen Record",
            icon: "\uf03d", // video
            active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.screenRecordingActive : false,
            status: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.screenRecordingActive) ? "Recording" : "Ready",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.toggleScreenRecording(); }
        },
        "colorPick": {
            key: "colorPick",
            title: "Color Picker",
            icon: "\uf1fb", // eye-dropper
            active: false,
            status: "Hex",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.pickColor(); }
        },
        "caffeine": {
            key: "caffeine",
            title: "Stay Awake",
            icon: "\uf0f4", // coffee
            active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.caffeineActive : false,
            status: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.caffeineActive) ? "Active" : "Off",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.caffeineActive = !systemCtrl.caffeineActive; }
        },
        "mic": {
            key: "mic",
            title: "Mic Mute",
            icon: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted) ? "\uf131" : "\uf130",
            active: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sourceMuted : false,
            status: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted) ? "Muted" : "Active",
            action: function() { if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.toggleSourceMute(); }
        },
        "gameMode": {
            key: "gameMode",
            title: "Game Mode",
            icon: "\uf11b", // gamepad
            active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.gameModeActive : false,
            status: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.gameModeActive) ? "Boosted" : "Off",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.gameModeActive = !systemCtrl.gameModeActive; }
        },
        "clipboard": {
            key: "clipboard",
            title: "Clipboard",
            icon: "\uf0ea", // paste
            active: false,
            status: "History",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.openClipboard(); }
        },
        "virtualInput": {
            key: "virtualInput",
            title: "Keyboard",
            icon: "\uf11c", // keyboard
            active: false,
            status: "On-Screen",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.toggleVirtualKeyboard(); }
        },
        "airplane": {
            key: "airplane",
            title: "Airplane",
            icon: "\uf072", // plane
            active: (typeof networkCtrl !== "undefined" && networkCtrl && !networkCtrl.wifiEnabled),
            status: (typeof networkCtrl !== "undefined" && networkCtrl && !networkCtrl.wifiEnabled) ? "On" : "Off",
            action: function() { if (typeof networkCtrl !== "undefined" && networkCtrl) networkCtrl.toggleWifi(); }
        },
        "focus": {
            key: "focus",
            title: "Focus Mode",
            icon: "\uf186", // moon
            active: false,
            status: "DND",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.toggleFocusMode(); }
        },
        "night": {
            key: "night",
            title: "Night Shift",
            icon: "\uf185", // sun
            active: (typeof nightLightCtrl !== "undefined" && nightLightCtrl) ? nightLightCtrl.active : false,
            status: (typeof nightLightCtrl !== "undefined" && nightLightCtrl && nightLightCtrl.active) ? "Warm" : "Off",
            action: function() { if (typeof nightLightCtrl !== "undefined" && nightLightCtrl) nightLightCtrl.toggleNightLight(); }
        },
        "dark": {
            key: "dark",
            title: "Dark Mode",
            icon: "\uf042", // contrast
            active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.themeDark : true,
            status: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.themeDark) ? "Dark" : "Light",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.themeDark = !systemCtrl.themeDark; }
        }
    })

    // Filter out focus/night/dark in normal view if MacFocusClusterModule is already displayed,
    // or show the 8 utility squircles (2 clean rows of 4) so there is zero duplication!
    readonly property var rawOrder: {
        var rev = revision;
        return (typeof systemCtrl !== "undefined" && systemCtrl)
               ? systemCtrl.getActionOrder()
               : ["capture", "record", "colorPick", "caffeine", "mic", "gameMode", "clipboard", "virtualInput"];
    }

    readonly property var currentOrder: {
        var list = [];
        for (var i = 0; i < rawOrder.length; ++i) {
            var k = rawOrder[i];
            // Avoid duplicating Focus, Night Shift, Dark Mode, and Connectivity toggles
            if (k !== "focus" && k !== "night" && k !== "dark" && k !== "airplane") {
                list.push({ key: k, rawIdx: i });
            }
        }
        return list;
    }

    ColumnLayout {
        id: actionCol
        anchors.fill: parent
        anchors.margins: 0
        spacing: 6

        // ── Frameless macOS Squircle Grid ───────────────────────────────────
        GridLayout {
            id: actionsLayout
            Layout.fillWidth: true
            columns: gridCardRoot.sizeMode === "compact" ? 4 : 2
            columnSpacing: 8
            rowSpacing: 8

            property int hoverTargetRawIndex: -1
            property int dragSourceRawIndex: -1

            Repeater {
                model: gridCardRoot.currentOrder

                delegate: Item {
                    id: tileDelegate
                    Layout.fillWidth: true
                    implicitHeight: gridCardRoot.sizeMode === "compact" ? 50 : 44

                    readonly property string tileKey: modelData.key
                    readonly property int rawIndex: modelData.rawIdx
                    readonly property var def: gridCardRoot.actionCatalog[tileKey] || null
                    readonly property bool isActive: (def && def.active) ? true : false

                    DropArea {
                        id: dropArea
                        anchors.fill: parent
                        keys: ["quick-action-tile"]
                        onEntered: (drag) => {
                            actionsLayout.hoverTargetRawIndex = tileDelegate.rawIndex;
                        }
                        onExited: {
                            if (actionsLayout.hoverTargetRawIndex === tileDelegate.rawIndex) {
                                actionsLayout.hoverTargetRawIndex = -1;
                            }
                        }
                    }

                    Rectangle {
                        id: tileItem
                        anchors.fill: isDragged ? undefined : parent
                        width: isDragged ? tileDelegate.width : undefined
                        height: isDragged ? tileDelegate.height : undefined
                        radius: TitanTheme.radiusTile
                        clip: true

                        property bool isDragged: false

                        z: isDragged ? 999 : 1
                        scale: isDragged ? 1.08 : (tileMa.pressed ? 0.94 : (tileMa.containsMouse ? 1.02 : 1.0))
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }

                        color: tileDelegate.isActive
                               ? Qt.rgba(0.04, 0.52, 1.0, 0.28)
                               : (actionsLayout.hoverTargetRawIndex === tileDelegate.rawIndex
                                  ? Qt.rgba(0.04, 0.52, 1.0, 0.32)
                                  : (tileMa.pressed ? TitanTheme.bgPressed : (tileMa.containsMouse ? TitanTheme.bgTitaniumHover : TitanTheme.bgTitanium)))

                        border.color: (tileItem.isDragged || actionsLayout.hoverTargetRawIndex === tileDelegate.rawIndex)
                                      ? TitanTheme.accent
                                      : ((typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                                         ? Qt.rgba(0.04, 0.52, 1.0, 0.55)
                                         : (tileDelegate.isActive ? TitanTheme.accent : (tileMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)))
                        border.width: (tileItem.isDragged || actionsLayout.hoverTargetRawIndex === tileDelegate.rawIndex) ? 2 : 1

                        Drag.active: tileItem.isDragged
                        Drag.source: tileDelegate
                        Drag.keys: ["quick-action-tile"]
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2

                        // ── Edit Mode Overlay: Left/Right Nudge + Bottom-Right Corner Resize (◢) ──
                        RowLayout {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 3
                            spacing: 2
                            visible: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                            z: 10

                            Rectangle {
                                width: 13
                                height: 13
                                radius: 6.5
                                color: leftNudgeMa.containsMouse ? TitanTheme.accent : Qt.rgba(0, 0, 0, 0.55)
                                visible: index > 0

                                Text {
                                    anchors.centerIn: parent
                                    text: "◄"
                                    font.pixelSize: 6
                                    color: "#FFFFFF"
                                }

                                MouseArea {
                                    id: leftNudgeMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof systemCtrl !== "undefined" && systemCtrl && index > 0) {
                                            var prevRaw = gridCardRoot.currentOrder[index - 1].rawIdx;
                                            systemCtrl.moveActionOrder(tileDelegate.rawIndex, prevRaw);
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: 13
                                height: 13
                                radius: 6.5
                                color: rightNudgeMa.containsMouse ? TitanTheme.accent : Qt.rgba(0, 0, 0, 0.55)
                                visible: index < (gridCardRoot.currentOrder.length - 1)

                                Text {
                                    anchors.centerIn: parent
                                    text: "►"
                                    font.pixelSize: 6
                                    color: "#FFFFFF"
                                }

                                MouseArea {
                                    id: rightNudgeMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof systemCtrl !== "undefined" && systemCtrl && index < (gridCardRoot.currentOrder.length - 1)) {
                                            var nextRaw = gridCardRoot.currentOrder[index + 1].rawIdx;
                                            systemCtrl.moveActionOrder(tileDelegate.rawIndex, nextRaw);
                                        }
                                    }
                                }
                            }
                        }

                        // Bottom-Right Corner Resize Handle (◢) in Edit Mode
                        Rectangle {
                            width: 14
                            height: 14
                            radius: 4
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.margins: 2
                            color: cornerResizeMa.containsMouse ? TitanTheme.accent : Qt.rgba(0.04, 0.52, 1.0, 0.35)
                            visible: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                            z: 10

                            Text {
                                anchors.centerIn: parent
                                text: "◢"
                                font.pixelSize: 8
                                color: "#FFFFFF"
                            }

                            MouseArea {
                                id: cornerResizeMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.SizeFDiagCursor
                                onClicked: {
                                    var nextMode = (gridCardRoot.sizeMode === "compact") ? "wide" : "compact";
                                    gridCardRoot.sizeMode = nextMode;
                                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                                        systemCtrl.setWidgetSize("actionGrid", nextMode);
                                }
                            }
                        }

                        // Mode 1: Compact Squircle (4 columns)
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 3
                            visible: gridCardRoot.sizeMode === "compact"

                            Item { Layout.fillHeight: true }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: tileDelegate.def ? tileDelegate.def.icon : "\uf013"
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 15
                                color: tileDelegate.isActive ? "#FFFFFF" : TitanTheme.textPrimary
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: tileDelegate.def ? tileDelegate.def.title : tileDelegate.tileKey
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                                color: tileDelegate.isActive ? "#FFFFFF" : TitanTheme.textSecondary
                                elide: Text.ElideRight
                                Layout.maximumWidth: parent.width - 6
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // Mode 2: Wide 2-Column Pill
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8
                            visible: gridCardRoot.sizeMode === "wide"

                            Rectangle {
                                width: 26
                                height: 26
                                radius: 13
                                color: tileDelegate.isActive ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.12)

                                Text {
                                    anchors.centerIn: parent
                                    text: tileDelegate.def ? tileDelegate.def.icon : "\uf013"
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 12
                                    color: "#FFFFFF"
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    text: tileDelegate.def ? tileDelegate.def.title : tileDelegate.tileKey
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: TitanTheme.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: tileDelegate.def ? tileDelegate.def.status : "Ready"
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 8
                                    color: tileDelegate.isActive ? TitanTheme.accent : TitanTheme.textMuted
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        MouseArea {
                            id: tileMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                                         ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
                                         : Qt.PointingHandCursor

                            drag.target: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) ? tileItem : undefined
                            drag.axis: Drag.XAndYAxis

                            onPressed: {
                                if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) {
                                    tileItem.isDragged = true;
                                    actionsLayout.dragSourceRawIndex = tileDelegate.rawIndex;
                                    tileItem.Drag.start();
                                }
                            }

                            onReleased: {
                                if (tileItem.isDragged) {
                                    tileItem.Drag.drop();
                                    tileItem.isDragged = false;
                                    var fromIdx = actionsLayout.dragSourceRawIndex;
                                    var toIdx = actionsLayout.hoverTargetRawIndex;
                                    if (fromIdx !== -1 && toIdx !== -1 && fromIdx !== toIdx) {
                                        if (typeof systemCtrl !== "undefined" && systemCtrl) {
                                            systemCtrl.moveActionOrder(fromIdx, toIdx);
                                        }
                                    }
                                    actionsLayout.dragSourceRawIndex = -1;
                                    actionsLayout.hoverTargetRawIndex = -1;
                                    tileItem.x = 0;
                                    tileItem.y = 0;
                                }
                            }

                            onCanceled: {
                                if (tileItem.isDragged) {
                                    tileItem.Drag.drop();
                                    tileItem.isDragged = false;
                                    actionsLayout.dragSourceRawIndex = -1;
                                    actionsLayout.hoverTargetRawIndex = -1;
                                    tileItem.x = 0;
                                    tileItem.y = 0;
                                }
                            }

                            onClicked: {
                                if (!(typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)) {
                                    if (tileDelegate.def && tileDelegate.def.action) {
                                        tileDelegate.def.action();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
