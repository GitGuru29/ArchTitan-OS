import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanActionGrid — macOS Control Center Bottleneck Utility Squircles Dock.
 *
 * Features:
 * - In "compact" (Bottleneck) mode: Renders 5 signature 50x48 icon-only squircles
 *   inside the stepped bottom-right bottleneck dock (horizontally scrollable to access
 *   additional utilities, or expandable to "wide" 2-column full-width grid via corner handle ◢).
 * - In Edit Controls mode:
 *   - Drag and drop any tile to reorder
 *   - Bottom-right corner resize handle (◢) on tiles to toggle Bottleneck (5 icons) vs Wide (full grid)
 *   - Quick nudge arrows (◄ / ►)
 */
Item {
    id: gridCardRoot
    Layout.fillWidth: true
    implicitHeight: actionCol.implicitHeight

    property int revision: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.tileVisibilityRevision : 0
    property string sizeMode: {
        var rev = revision;
        return (typeof systemCtrl !== "undefined" && systemCtrl)
               ? systemCtrl.getWidgetSize("actionGrid", "compact")
               : "compact"; // "compact" (bottleneck 5-icon row) or "wide" (full-width 2-col pills)
    }

    signal calendarToggleRequested()

    readonly property var actionCatalog: ({
        "region": {
            key: "region",
            title: "Region Snip",
            icon: "\uf065", // expand / frame corners
            active: false,
            status: "Area",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.triggerScreenshot(); }
        },
        "capture": {
            key: "capture",
            title: "Screenshot",
            icon: "\uf030", // camera
            active: false,
            status: "Screen",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.triggerScreenshot(); }
        },
        "record": {
            key: "record",
            title: "Screen Record",
            icon: "\uf192", // dot-circle record icon
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
            icon: "\uf0f4", // coffee cup
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
        }
    })

    // Ensure the 5 mockup bottleneck icons (Region Snip, Screenshot, Screen Record, Color Picker, Stay Awake)
    // lead the list while preserving user drag-and-drop order.
    readonly property var rawOrder: {
        var rev = revision;
        return (typeof systemCtrl !== "undefined" && systemCtrl)
               ? systemCtrl.getActionOrder()
               : ["capture", "record", "colorPick", "caffeine", "mic", "gameMode", "clipboard", "virtualInput"];
    }

    readonly property var currentOrder: {
        var list = [];
        // Always include the signature 5 bottleneck icons in compact mode, or all 8 in wide mode
        var preferredFive = [
            { key: "region", rawIdx: 0 },
            { key: "capture", rawIdx: 1 },
            { key: "record", rawIdx: 2 },
            { key: "colorPick", rawIdx: 3 },
            { key: "caffeine", rawIdx: 4 }
        ];
        if (sizeMode === "compact" && !(typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)) {
            return preferredFive;
        }

        // In Edit Mode or Wide Mode, show customizable list from systemCtrl
        list.push({ key: "region", rawIdx: -1 });
        for (var i = 0; i < rawOrder.length; ++i) {
            var k = rawOrder[i];
            if (k !== "focus" && k !== "night" && k !== "dark" && k !== "airplane" && gridCardRoot.actionCatalog[k]) {
                list.push({ key: k, rawIdx: i });
            }
        }
        if (sizeMode === "compact") {
            return list.slice(0, 5);
        }
        return list.slice(0, 8);
    }

    ColumnLayout {
        id: actionCol
        anchors.fill: parent
        anchors.margins: 0
        spacing: 6

        // ── Bottleneck 5-Icon Row (Compact) or Full 2-Column Grid (Wide) ─────
        GridLayout {
            id: actionsLayout
            Layout.fillWidth: true
            columns: gridCardRoot.sizeMode === "compact" ? 5 : 2
            columnSpacing: 8
            rowSpacing: 8

            property int hoverTargetRawIndex: -1
            property int dragSourceRawIndex: -1

            Repeater {
                model: gridCardRoot.currentOrder

                delegate: Item {
                    id: tileDelegate
                    Layout.fillWidth: true
                    implicitHeight: gridCardRoot.sizeMode === "compact" ? 48 : 44

                    readonly property string tileKey: modelData.key
                    readonly property int rawIndex: modelData.rawIdx
                    readonly property var def: gridCardRoot.actionCatalog[tileKey] || null
                    readonly property bool isActive: (def && def.active) ? true : false

                    DropArea {
                        id: dropArea
                        anchors.fill: parent
                        keys: ["quick-action-tile"]
                        onEntered: (drag) => {
                            if (tileDelegate.rawIndex >= 0)
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
                        scale: isDragged ? 1.08 : (tileMa.pressed ? 0.93 : (tileMa.containsMouse ? 1.03 : 1.0))
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }

                        color: tileDelegate.isActive
                               ? Qt.rgba(0.04, 0.52, 1.0, 0.30)
                               : (actionsLayout.hoverTargetRawIndex === tileDelegate.rawIndex && tileDelegate.rawIndex >= 0
                                  ? Qt.rgba(0.04, 0.52, 1.0, 0.32)
                                  : (tileMa.pressed ? TitanTheme.bgPressed : (tileMa.containsMouse ? TitanTheme.bgTitaniumHover : TitanTheme.bgTitanium)))

                        border.color: (tileItem.isDragged || (actionsLayout.hoverTargetRawIndex === tileDelegate.rawIndex && tileDelegate.rawIndex >= 0))
                                      ? TitanTheme.accent
                                      : ((typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                                         ? Qt.rgba(0.04, 0.52, 1.0, 0.60)
                                         : (tileDelegate.isActive ? TitanTheme.accent : (tileMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)))
                        border.width: (tileItem.isDragged || (actionsLayout.hoverTargetRawIndex === tileDelegate.rawIndex && tileDelegate.rawIndex >= 0)) ? 2 : 1

                        Drag.active: tileItem.isDragged
                        Drag.source: tileDelegate
                        Drag.keys: ["quick-action-tile"]
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2

                        // ── Edit Mode Overlay: Bottom-Right Corner Resize (◢) ──
                        Rectangle {
                            width: 13
                            height: 13
                            radius: 4
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.margins: 2
                            color: cornerResizeMa.containsMouse ? TitanTheme.accent : Qt.rgba(0.04, 0.52, 1.0, 0.40)
                            visible: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                            z: 10

                            Text {
                                anchors.centerIn: parent
                                text: "◢"
                                font.pixelSize: 7
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

                        // Mode 1: Bottleneck Icon Squircle (5 columns, pure centered icon like mockup)
                        Item {
                            anchors.fill: parent
                            visible: gridCardRoot.sizeMode === "compact"

                            Text {
                                anchors.centerIn: parent
                                text: tileDelegate.def ? tileDelegate.def.icon : "\uf013"
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 17
                                color: tileDelegate.isActive ? "#FFFFFF" : TitanTheme.textPrimary
                            }
                        }

                        // Mode 2: Wide 2-Column Pill (Full Width with Title & Subtitle)
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

                            drag.target: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode && tileDelegate.rawIndex >= 0) ? tileItem : undefined
                            drag.axis: Drag.XAndYAxis

                            onPressed: {
                                if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode && tileDelegate.rawIndex >= 0) {
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
