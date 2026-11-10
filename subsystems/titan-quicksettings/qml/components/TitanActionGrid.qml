import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanActionGrid — ArchTitan Comprehensive Quick Action Bento Card.
 *
 * Provides all 12 system actions with:
 * - Dynamic order from systemCtrl.getActionOrder()
 * - In-place reordering (move left/right in edit mode)
 * - Grid resize toggle: Compact Squircles (4x3) vs Wide Tiles (2x6)
 * - Sapphire Cyan active indicators
 * - Perfectly aligned layout (zero gaps or jigsaw breakage)
 */
Rectangle {
    id: gridCardRoot
    Layout.fillWidth: true
    implicitHeight: actionCol.implicitHeight + 20
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                  ? TitanTheme.accent
                  : (cardMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)
    border.width: 1

    property int revision: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.tileVisibilityRevision : 0
    property string sizeMode: (typeof systemCtrl !== "undefined" && systemCtrl)
                              ? systemCtrl.getWidgetSize("actionGrid", "compact")
                              : "compact" // "compact" (4 cols) or "wide" (2 cols)

    readonly property var actionCatalog: ({
        "focus": {
            key: "focus",
            title: "Focus Mode",
            icon: "\uf05b", // crosshairs / dnd
            active: false,
            status: "Off",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.toggleFocusMode(); }
        },
        "dark": {
            key: "dark",
            title: "Dark Mode",
            icon: "\uf042", // contrast
            active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.themeDark : true,
            status: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.themeDark) ? "Obsidian" : "Light",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.themeDark = !systemCtrl.themeDark; }
        },
        "night": {
            key: "night",
            title: "Night Shift",
            icon: "\uf06e", // eye
            active: (typeof nightLightCtrl !== "undefined" && nightLightCtrl) ? nightLightCtrl.active : false,
            status: (typeof nightLightCtrl !== "undefined" && nightLightCtrl && nightLightCtrl.active) ? "4500K Warm" : "Off",
            action: function() { if (typeof nightLightCtrl !== "undefined" && nightLightCtrl) nightLightCtrl.toggleNightLight(); }
        },
        "mic": {
            key: "mic",
            title: "Mic Mute",
            icon: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted) ? "\uf131" : "\uf130",
            active: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sourceMuted : false,
            status: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted) ? "Muted" : "Active",
            action: function() { if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.toggleSourceMute(); }
        },
        "caffeine": {
            key: "caffeine",
            title: "Stay Awake",
            icon: "\uf0f4", // coffee
            active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.caffeineActive : false,
            status: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.caffeineActive) ? "Active" : "Off",
            action: function() { if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.caffeineActive = !systemCtrl.caffeineActive; }
        },
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
        }
    })

    readonly property var currentOrder: {
        var rev = revision;
        return (typeof systemCtrl !== "undefined" && systemCtrl)
               ? systemCtrl.getActionOrder()
               : ["focus", "dark", "night", "mic", "caffeine", "capture", "record", "colorPick", "gameMode", "clipboard", "virtualInput", "airplane"];
    }

    ColumnLayout {
        id: actionCol
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // ── Card Header + Grid Resize Pill Switcher ─────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Quick Actions (" + gridCardRoot.currentOrder.length + ")"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: TitanTheme.textPrimary
            }

            Item { Layout.fillWidth: true }

            // Grid Size Mode Toggle: Compact (4x3) vs Wide (2x6)
            Rectangle {
                height: 20
                width: 90
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.08)
                border.color: TitanTheme.borderHairline
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Compact Squircles Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 9
                        color: gridCardRoot.sizeMode === "compact" ? TitanTheme.accent : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "Compact"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 8
                            font.weight: Font.Bold
                            color: gridCardRoot.sizeMode === "compact" ? "#FFFFFF" : TitanTheme.textMuted
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                gridCardRoot.sizeMode = "compact";
                                if (typeof systemCtrl !== "undefined" && systemCtrl)
                                    systemCtrl.setWidgetSize("actionGrid", "compact");
                            }
                        }
                    }

                    // Wide Tiles Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 9
                        color: gridCardRoot.sizeMode === "wide" ? TitanTheme.accent : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "Wide"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 8
                            font.weight: Font.Bold
                            color: gridCardRoot.sizeMode === "wide" ? "#FFFFFF" : TitanTheme.textMuted
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                gridCardRoot.sizeMode = "wide";
                                if (typeof systemCtrl !== "undefined" && systemCtrl)
                                    systemCtrl.setWidgetSize("actionGrid", "wide");
                            }
                        }
                    }
                }
            }
        }

        // ── Dynamic Action Grid (All 12 Buttons) ─────────────────────────────
        GridLayout {
            id: actionsLayout
            Layout.fillWidth: true
            columns: gridCardRoot.sizeMode === "compact" ? 4 : 2
            columnSpacing: 6
            rowSpacing: 6

            Repeater {
                model: gridCardRoot.currentOrder

                delegate: Item {
                    id: tileDelegate
                    Layout.fillWidth: true
                    implicitHeight: gridCardRoot.sizeMode === "compact" ? 52 : 44

                    readonly property var def: gridCardRoot.actionCatalog[modelData] || null
                    readonly property bool isActive: (def && def.active) ? true : false
                    readonly property int itemIndex: index
                    readonly property string tileKey: modelData

                    // DropArea catches when another tile is dragged over this tile
                    DropArea {
                        id: dropArea
                        anchors.fill: parent
                        keys: ["quick-action-tile"]
                        onEntered: (drag) => {
                            if (drag.source && typeof drag.source.itemIndex !== "undefined") {
                                var fromIdx = drag.source.itemIndex;
                                var toIdx = tileDelegate.itemIndex;
                                if (fromIdx !== toIdx && fromIdx >= 0 && toIdx >= 0) {
                                    if (typeof systemCtrl !== "undefined" && systemCtrl) {
                                        systemCtrl.moveActionOrder(fromIdx, toIdx);
                                    }
                                }
                            }
                        }
                    }

                    // The visual tile that can be dragged
                    Rectangle {
                        id: tileItem
                        anchors.fill: parent
                        radius: 10
                        clip: true

                        property bool isDragged: false

                        z: isDragged ? 99 : 1
                        scale: isDragged ? 1.08 : (tileMa.pressed ? 0.95 : (tileMa.containsMouse ? 1.02 : 1.0))
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }

                        color: tileDelegate.isActive
                               ? Qt.rgba(0.04, 0.52, 1.0, 0.16)
                               : (tileMa.pressed ? TitanTheme.bgPressed : (tileMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgInset))

                        border.color: tileItem.isDragged
                                      ? TitanTheme.accent
                                      : ((typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                                         ? Qt.rgba(0.04, 0.52, 1.0, 0.5)
                                         : (tileDelegate.isActive ? TitanTheme.accent : (tileMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)))
                        border.width: tileItem.isDragged ? 2 : 1

                        Drag.active: tileItem.isDragged
                        Drag.source: tileDelegate
                        Drag.keys: ["quick-action-tile"]
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2

                        // Edit mode drag grip indicator in corner
                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 3
                            color: Qt.rgba(0.04, 0.52, 1.0, 0.35)
                            visible: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                            z: 5

                            Text {
                                anchors.centerIn: parent
                                text: "⋮⋮"
                                font.pixelSize: 8
                                color: "#FFFFFF"
                            }
                        }

                        // Mode 1: Compact Squircle (4 columns)
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 2
                            visible: gridCardRoot.sizeMode === "compact"

                            Item { Layout.fillHeight: true }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: tileDelegate.def ? tileDelegate.def.icon : "\uf013"
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 14
                                color: tileDelegate.isActive ? TitanTheme.accent : TitanTheme.textSecondary
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: tileDelegate.def ? tileDelegate.def.title : modelData
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                                color: tileDelegate.isActive ? TitanTheme.textPrimary : TitanTheme.textMuted
                                elide: Text.ElideRight
                                Layout.maximumWidth: parent.width - 6
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // Mode 2: Wide 2-Column Tile
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            visible: gridCardRoot.sizeMode === "wide"

                            Rectangle {
                                width: 26
                                height: 26
                                radius: 13
                                color: tileDelegate.isActive ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.08)

                                Text {
                                    anchors.centerIn: parent
                                    text: tileDelegate.def ? tileDelegate.def.icon : "\uf013"
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 12
                                    color: tileDelegate.isActive ? "#FFFFFF" : TitanTheme.textMuted
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    text: tileDelegate.def ? tileDelegate.def.title : modelData
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    color: tileDelegate.isActive ? TitanTheme.textPrimary : TitanTheme.textSecondary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: tileDelegate.def ? tileDelegate.def.status : "Off"
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 8
                                    color: tileDelegate.isActive ? TitanTheme.accent : TitanTheme.textSubtle
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

                            onPressed: {
                                if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) {
                                    tileItem.isDragged = true;
                                    tileItem.Drag.start();
                                }
                            }

                            onReleased: {
                                if (tileItem.isDragged) {
                                    tileItem.Drag.drop();
                                    tileItem.isDragged = false;
                                    tileItem.x = 0;
                                    tileItem.y = 0;
                                }
                            }

                            onCanceled: {
                                if (tileItem.isDragged) {
                                    tileItem.Drag.drop();
                                    tileItem.isDragged = false;
                                    tileItem.x = 0;
                                    tileItem.y = 0;
                                }
                            }

                            onClicked: {
                                if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) {
                                    // In edit mode, clicking doesn't trigger action
                                } else {
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

    MouseArea {
        id: cardMa
        anchors.fill: parent
        hoverEnabled: true
        z: -1
    }
}
