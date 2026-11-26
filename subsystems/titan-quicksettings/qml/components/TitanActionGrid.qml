import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanActionGrid — macOS Control Center Bottleneck Utility Squircles Dock.
 *
 * Features:
 * - Renders active utility squircles in a 5-column bottleneck grid (or 2-column Wide mode).
 * - Full Add / Remove / Reorder / Resize support in Edit Controls mode:
 *   - Top-Left [−] badge on active tiles removes the tile from the dock.
 *   - Inline "+ Add Controls" tray lets users add more buttons (Mic Mute, Game Mode,
 *     Clipboard, Keyboard, Airplane, etc.) with 1 click.
 *   - Drag and drop any tile to reorder.
 *   - Bottom-right corner resize handle (◢) toggles Compact (5-col icons) vs Wide (2-col pills).
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
               : "compact"; // "compact" (bottleneck 5-col icon squircles) or "wide" (full-width 2-col pills)
    }

    readonly property bool editActive: (typeof rootWindow !== "undefined" && rootWindow && rootWindow.inPlaceEditMode)

    readonly property var actionCatalog: ({
        "region": {
            key: "region",
            title: "Region Snip",
            icon: "\uf065", // expand / frame corners
            defaultVisible: true,
            active: false,
            status: "Area",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.takeScreenshot(); }
        },
        "capture": {
            key: "capture",
            title: "Screenshot",
            icon: "\uf030", // camera
            defaultVisible: true,
            active: false,
            status: "Screen",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.takeScreenshot(); }
        },
        "record": {
            key: "record",
            title: "Screen Record",
            icon: "\uf192", // dot-circle record icon
            defaultVisible: true,
            active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.screenRecordingActive : false,
            status: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.screenRecordingActive) ? "Recording" : "Ready",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.toggleScreenRecording(); }
        },
        "colorPick": {
            key: "colorPick",
            title: "Color Picker",
            icon: "\uf1fb", // eye-dropper
            defaultVisible: true,
            active: false,
            status: "Hex",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.pickColor(); }
        },
        "caffeine": {
            key: "caffeine",
            title: "Stay Awake",
            icon: "\uf0f4", // coffee cup
            defaultVisible: true,
            active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.caffeineActive : false,
            status: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.caffeineActive) ? "Active" : "Off",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.caffeineActive = !systemCtrl.caffeineActive; }
        },
        "mic": {
            key: "mic",
            title: "Mic Mute",
            icon: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted) ? "\uf131" : "\uf130",
            defaultVisible: false,
            active: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sourceMuted : false,
            status: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted) ? "Muted" : "Active",
            action: function() { if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.toggleSourceMute(); }
        },
        "gameMode": {
            key: "gameMode",
            title: "Game Mode",
            icon: "\uf11b", // gamepad
            defaultVisible: false,
            active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.gameModeActive : false,
            status: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.gameModeActive) ? "Boosted" : "Off",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.gameModeActive = !systemCtrl.gameModeActive; }
        },
        "clipboard": {
            key: "clipboard",
            title: "Clipboard",
            icon: "\uf0ea", // paste
            defaultVisible: false,
            active: false,
            status: "History",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.openClipboard(); }
        },
        "virtualInput": {
            key: "virtualInput",
            title: "Keyboard",
            icon: "\uf11c", // keyboard
            defaultVisible: false,
            active: false,
            status: "On-Screen",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.toggleVirtualKeyboard(); }
        },
        "airplane": {
            key: "airplane",
            title: "Airplane",
            icon: "\uf072", // plane
            defaultVisible: false,
            active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.airplaneMode : false,
            status: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.airplaneMode) ? "On" : "Off",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.toggleAirplaneMode(); }
        }
    })

    readonly property var rawOrder: {
        var rev = revision;
        return (typeof systemCtrl !== "undefined" && systemCtrl)
               ? systemCtrl.getActionOrder()
               : ["region", "capture", "record", "colorPick", "caffeine", "mic", "gameMode", "clipboard", "virtualInput", "airplane"];
    }

    function isKeyVisible(k) {
        var defObj = gridCardRoot.actionCatalog[k];
        if (!defObj) return false;
        if (typeof systemCtrl !== "undefined" && systemCtrl) {
            return systemCtrl.getTileVisible("bottleneck_" + k, defObj.defaultVisible);
        }
        return defObj.defaultVisible;
    }

    // Active (visible) buttons in the bottleneck dock
    readonly property var currentOrder: {
        var rev = revision;
        var list = [];
        for (var i = 0; i < rawOrder.length; ++i) {
            var k = rawOrder[i];
            if (k !== "focus" && k !== "night" && k !== "dark" && gridCardRoot.actionCatalog[k]) {
                if (gridCardRoot.isKeyVisible(k)) {
                    list.push({ key: k, rawIdx: i });
                }
            }
        }
        // Always ensure at least 1 button remains visible
        if (list.length === 0) {
            list.push({ key: "capture", rawIdx: 0 });
        }
        return list;
    }

    // Hidden (available to add) buttons shown in the "+ Add Buttons" tray
    readonly property var availableToAdd: {
        var rev = revision;
        var list = [];
        for (var i = 0; i < rawOrder.length; ++i) {
            var k = rawOrder[i];
            if (k !== "focus" && k !== "night" && k !== "dark" && gridCardRoot.actionCatalog[k]) {
                if (!gridCardRoot.isKeyVisible(k)) {
                    list.push({ key: k, rawIdx: i });
                }
            }
        }
        return list;
    }

    ColumnLayout {
        id: actionCol
        anchors.fill: parent
        anchors.margins: 0
        spacing: 6

        // ── Bottleneck 5-Column Icon Row (or 2-Column Wide Grid) ─────────────
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
                                      : (gridCardRoot.editActive
                                         ? Qt.rgba(0.04, 0.52, 1.0, 0.60)
                                         : (tileDelegate.isActive ? TitanTheme.accent : (tileMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)))
                        border.width: (tileItem.isDragged || (actionsLayout.hoverTargetRawIndex === tileDelegate.rawIndex && tileDelegate.rawIndex >= 0)) ? 2 : 1

                        Drag.active: tileItem.isDragged
                        Drag.source: tileDelegate
                        Drag.keys: ["quick-action-tile"]
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2

                        // ── Edit Mode Top-Left [−] Remove Button ─────────────────
                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 2
                            color: removeMa.containsMouse ? TitanTheme.red : Qt.rgba(0.94, 0.27, 0.27, 0.85)
                            visible: gridCardRoot.editActive && gridCardRoot.currentOrder.length > 1
                            z: 12

                            Text {
                                anchors.centerIn: parent
                                text: "−"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: "#FFFFFF"
                            }

                            MouseArea {
                                id: removeMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof systemCtrl !== "undefined" && systemCtrl) {
                                        systemCtrl.setTileVisible("bottleneck_" + tileDelegate.tileKey, false);
                                    }
                                }
                            }
                        }

                        // ── Edit Mode Bottom-Right Corner Resize (◢) ─────────────
                        Rectangle {
                            width: 13
                            height: 13
                            radius: 4
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.margins: 2
                            color: cornerResizeMa.containsMouse ? TitanTheme.accent : Qt.rgba(0.04, 0.52, 1.0, 0.40)
                            visible: gridCardRoot.editActive
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
                                font.pixelSize: 16
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
                            cursorShape: gridCardRoot.editActive
                                         ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
                                         : Qt.PointingHandCursor

                            drag.target: (gridCardRoot.editActive && tileDelegate.rawIndex >= 0) ? tileItem : undefined
                            drag.axis: Drag.XAndYAxis

                            onPressed: {
                                if (gridCardRoot.editActive && tileDelegate.rawIndex >= 0) {
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
                                if (!gridCardRoot.editActive) {
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

        // ── Inline "+ Add More Buttons" Tray (Shown in Edit Controls Mode) ───
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: addTrayCol.implicitHeight + 14
            radius: 12
            color: Qt.rgba(0.04, 0.52, 1.0, 0.10)
            border.color: Qt.rgba(0.04, 0.52, 1.0, 0.40)
            border.width: 1
            visible: gridCardRoot.editActive && gridCardRoot.availableToAdd.length > 0

            ColumnLayout {
                id: addTrayCol
                anchors.fill: parent
                anchors.margins: 7
                spacing: 5

                Text {
                    text: "+ ADD MORE CONTROLS TO BOTTLENECK"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    font.letterSpacing: 0.6
                    color: TitanTheme.accent
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 5

                    Repeater {
                        model: gridCardRoot.availableToAdd

                        delegate: Rectangle {
                            readonly property var def: gridCardRoot.actionCatalog[modelData.key] || null
                            width: addChipRow.implicitWidth + 14
                            height: 24
                            radius: 12
                            color: addChipMa.containsMouse ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.12)
                            border.color: TitanTheme.accent
                            border.width: 1

                            RowLayout {
                                id: addChipRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: "+"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: "#FFFFFF"
                                }

                                Text {
                                    text: def ? def.icon : ""
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 10
                                    color: "#FFFFFF"
                                }

                                Text {
                                    text: def ? def.title : modelData.key
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    color: "#FFFFFF"
                                }
                            }

                            MouseArea {
                                id: addChipMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof systemCtrl !== "undefined" && systemCtrl) {
                                        systemCtrl.setTileVisible("bottleneck_" + modelData.key, true);
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
