import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

Item {
    id: root

    property int selectedZone: 0

    readonly property var zones: [
        {
            id: "TOP-LEFT HOTZONE (top_left)",
            title: "Titan Spotlight & Clipboard",
            shortcut: "180ms Dwell • Super Tap",
            icon: "\uf002",
            color: TitanTheme.accent,
            rx: 0.16, ry: 0.18,
            desc: "Rest your pointer in the top-left corner for 180ms (or tap Super / Super+Space) to summon Titan Spotlight. Press Super+V to open Clipboard History.",
            actionLabel: "Summon Titan Spotlight",
            trigger: function() { tourCtrl.toggleSpotlight(); }
        },
        {
            id: "TOP-CENTER ISLAND",
            title: "Dynamic Media & Clock HUD",
            shortcut: "Super + M",
            icon: "\uf001",
            color: TitanTheme.mauve,
            rx: 0.50, ry: 0.18,
            desc: "Waybar's central island works alongside titan-media-hud (Super+M) to display live MPRIS2 album art, track progress, and instant playback controls.",
            actionLabel: "Toggle Media Island HUD",
            trigger: function() { tourCtrl.toggleMediaHud(); }
        },
        {
            id: "TOP-RIGHT HOTZONE (top_right)",
            title: "Stepped Bottleneck Control Center",
            shortcut: "180ms Dwell • Super + N",
            icon: "\uf1de",
            color: TitanTheme.info,
            rx: 0.84, ry: 0.18,
            desc: "Dwell at the top-right corner for 180ms or press Super+N to open the Stepped Bottleneck Control Center: Wi-Fi, Bluetooth, PipeWire Audio, Display & Edit Mode.",
            actionLabel: "Open Control Center",
            trigger: function() { tourCtrl.toggleControlCenter(); }
        },
        {
            id: "LEFT-CENTER HOTZONE (left_center)",
            title: "Titan System Monitor HUD",
            shortcut: "180ms Left-Edge Dwell",
            icon: "\uf080",
            color: TitanTheme.success,
            rx: 0.16, ry: 0.52,
            desc: "Rest your pointer along the left screen edge for 180ms to slide out titan-sysmon: GPU-rendered CPU/RAM/Temp rings, per-core bars, and THM v3 telemetry.",
            actionLabel: "Toggle System Monitor",
            trigger: function() { tourCtrl.toggleSysmon(); }
        },
        {
            id: "RIGHT-CENTER & WORKSPACE HUD",
            title: "10-Workspace Matrix & Edge Slide",
            shortcut: "Super + Tab • Right-Edge",
            icon: "\uf009",
            color: TitanTheme.teal,
            rx: 0.84, ry: 0.52,
            desc: "Dwell at the right edge to advance workspaces (e+1), swipe with 3 fingers on your touchpad, or press Super+Tab to open titan-workspace-hud.",
            actionLabel: "Toggle 10-Workspace HUD",
            trigger: function() { tourCtrl.toggleWorkspaceHud(); }
        },
        {
            id: "BOTTOM-RIGHT HOTZONE (bottom_right)",
            title: "Notification & Media Hub",
            shortcut: "180ms Bottom-Right Dwell",
            icon: "\uf0f3",
            color: TitanTheme.warning,
            rx: 0.84, ry: 0.82,
            desc: "Dwell at the bottom-right corner for 180ms to open the expanded dual-panel Notification Center & MPRIS Media Hub.",
            actionLabel: "Open Notification Hub",
            trigger: function() { tourCtrl.openNotifications(); }
        }
    ]

    RowLayout {
        anchors.fill: parent
        anchors.margins: 26
        spacing: 24

        // Left Column: Interactive 16:9 Vector Screen Radar Matching hotzones.toml
        Rectangle {
            Layout.preferredWidth: 450
            Layout.fillHeight: true
            radius: 20
            color: Qt.rgba(TitanTheme.crust.r, TitanTheme.crust.g, TitanTheme.crust.b, 0.72)
            border.width: 1
            border.color: Qt.rgba(TitanTheme.info.r, TitanTheme.info.g, TitanTheme.info.b, 0.30)

            TitanReticle {
                anchors.fill: parent
                anchors.margins: 10
                color: TitanTheme.info
                bracketLength: 14
                bracketThickness: 2
                opacity: 0.5
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "TITAN-HOTZONES // /ETC/ARCHTITAN/HOTZONES.TOML"
                        color: TitanTheme.info
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.9
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "180ms DWELL"
                        color: TitanTheme.accent
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }

                // Miniature 16:9 Screen Viewport with ZoneOsd Frame
                Rectangle {
                    id: radarScreen
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 14
                    color: Qt.rgba(0.03, 0.05, 0.09, 0.95)
                    border.width: 2
                    border.color: TitanTheme.accent
                    clip: true

                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.strokeStyle = "rgba(56, 189, 248, 0.07)";
                            ctx.lineWidth = 1;
                            var step = 28;
                            for (var x = step; x < width; x += step) {
                                ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke();
                            }
                            for (var y = step; y < height; y += step) {
                                ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke();
                            }
                        }
                    }

                    // Simulated Waybar Top Strip inside Radar
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 8
                        height: 22
                        radius: 11
                        color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.9)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.1)
                    }

                    // Interactive Hotzone Target Nodes inside Radar
                    Repeater {
                        model: root.zones

                        delegate: Item {
                            required property var modelData
                            required property int index
                            readonly property bool active: index === root.selectedZone

                            x: radarScreen.width * modelData.rx - width / 2
                            y: radarScreen.height * modelData.ry - height / 2
                            width: 112
                            height: 44

                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: parent.active
                                    ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.26)
                                    : Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.80)
                                border.width: parent.active ? 2 : 1
                                border.color: parent.active ? modelData.color : Qt.rgba(1, 1, 1, 0.16)

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Item {
                                        width: 24; height: 24
                                        TitanArcItem {
                                            anchors.fill: parent
                                            color: modelData.color
                                            trackColor: Qt.rgba(1, 1, 1, 0.1)
                                            lineWidth: 2.5
                                            startAngle: -90
                                            sweepAngle: parent.parent.parent.active ? 360 : 240
                                            showTrack: true
                                            roundCaps: true
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.icon
                                            color: modelData.color
                                            font.family: TitanTheme.monoFamily
                                            font.pixelSize: 10
                                        }
                                    }

                                    ColumnLayout {
                                        spacing: 0
                                        Text {
                                            text: "ZONE 0" + (index + 1)
                                            color: TitanTheme.textLow
                                            font.family: TitanTheme.monoFamily
                                            font.pixelSize: 8
                                            font.weight: Font.Bold
                                        }
                                        Text {
                                            text: modelData.title.split(" ")[0]
                                            color: TitanTheme.textHigh
                                            font.family: TitanTheme.monoFamily
                                            font.pixelSize: 10
                                            font.weight: Font.Bold
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    tourCtrl.playSound("step");
                                    root.selectedZone = index;
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Notice the steady blue-violet Workspace Frame & 6 ZoneOsd pills around your real screen!"
                    color: TitanTheme.textMid
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Right Column: Selected Hotzone Inspector & Live Trigger Deck
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            RowLayout {
                spacing: 10
                Rectangle {
                    height: 24
                    width: actLbl.implicitWidth + 16
                    radius: 12
                    color: Qt.rgba(TitanTheme.info.r, TitanTheme.info.g, TitanTheme.info.b, 0.16)
                    border.width: 1
                    border.color: Qt.rgba(TitanTheme.info.r, TitanTheme.info.g, TitanTheme.info.b, 0.45)

                    Text {
                        id: actLbl
                        anchors.centerIn: parent
                        text: "ACT 02 // TITAN-HOTZONES & ZONE-OSD"
                        color: TitanTheme.info
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "180ms Pointer Dwell Hot-Zones"
                color: TitanTheme.textHigh
                font.family: TitanTheme.fontFamily
                font.pixelSize: 26
                font.weight: Font.Black
            }

            // Selected Zone Detailed Card
            Rectangle {
                Layout.fillWidth: true
                height: 170
                radius: 18
                color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.65)
                border.width: 1.5
                border.color: Qt.rgba(root.zones[root.selectedZone].color.r,
                                      root.zones[root.selectedZone].color.g,
                                      root.zones[root.selectedZone].color.b, 0.55)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Item {
                            width: 44; height: 44
                            TitanArcItem {
                                anchors.fill: parent
                                color: root.zones[root.selectedZone].color
                                trackColor: Qt.rgba(1, 1, 1, 0.1)
                                lineWidth: 3.5
                                startAngle: -90
                                sweepAngle: 310
                                showTrack: true
                                roundCaps: true
                            }
                            Text {
                                anchors.centerIn: parent
                                text: root.zones[root.selectedZone].icon
                                color: root.zones[root.selectedZone].color
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 16
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: root.zones[root.selectedZone].id
                                color: root.zones[root.selectedZone].color
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                font.letterSpacing: 0.8
                            }
                            Text {
                                text: root.zones[root.selectedZone].title
                                color: TitanTheme.textHigh
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 17
                                font.weight: Font.Bold
                            }
                        }

                        Rectangle {
                            height: 26
                            width: keyText.implicitWidth + 16
                            radius: 8
                            color: Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.14)
                            Text {
                                id: keyText
                                anchors.centerIn: parent
                                text: root.zones[root.selectedZone].shortcut
                                color: TitanTheme.info
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: root.zones[root.selectedZone].desc
                        color: TitanTheme.textMid
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 12
                        lineHeight: 1.35
                        wrapMode: Text.WordWrap
                    }

                    TitanButton {
                        Layout.alignment: Qt.AlignRight
                        implicitHeight: 34
                        implicitWidth: 220
                        text: root.zones[root.selectedZone].actionLabel
                        glyph: "\uf0e7"
                        variant: "primary"
                        onClicked: root.zones[root.selectedZone].trigger()
                    }
                }
            }

            // Quick Selector Grid for All 6 Hotzones
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                Repeater {
                    model: root.zones

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool isSel: index === root.selectedZone

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10
                        color: isSel
                            ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.18)
                            : Qt.rgba(1, 1, 1, 0.03)
                        border.width: 1
                        border.color: isSel ? modelData.color : Qt.rgba(1, 1, 1, 0.08)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: modelData.icon
                                color: modelData.color
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 13
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    color: isSel ? TitanTheme.textHigh : TitanTheme.textMid
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: isSel ? Font.Bold : Font.Medium
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.shortcut
                                    color: TitanTheme.textLow
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                tourCtrl.playSound("step");
                                root.selectedZone = index;
                            }
                        }
                    }
                }
            }
        }
    }
}
