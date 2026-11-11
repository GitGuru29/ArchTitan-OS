import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

Item {
    id: root

    property int selectedZone: 2

    readonly property var zones: [
        {
            id: "TOP-LEFT CORNER",
            title: "Titan App Menu & Workspaces",
            shortcut: "Super",
            icon: "\uf009",
            color: TitanTheme.accent,
            rx: 0.14, ry: 0.16,
            desc: "Click the ArchTitan emblem at the top-left of your bar or press Super to open the categorized Application Launcher. Adjacent pills show active Hyprland workspaces 1..10.",
            actionLabel: "Trigger App Menu Live",
            trigger: function() { tourCtrl.toggleMenu(); }
        },
        {
            id: "TOP-CENTER PILL",
            title: "Dynamic Media & Clock Island",
            shortcut: "MPRIS2 Live",
            icon: "\uf001",
            color: TitanTheme.mauve,
            rx: 0.50, ry: 0.16,
            desc: "Morphs fluidly when music or browser media plays—displaying real-time album art, artist metadata, and equalizer bars with instant play/pause and track skip controls.",
            actionLabel: "Test Audio Signal",
            trigger: function() { tourCtrl.testAudio(); }
        },
        {
            id: "TOP-RIGHT CORNER",
            title: "Stepped Bottleneck Control Center",
            shortcut: "Super + N",
            icon: "\uf1de",
            color: TitanTheme.info,
            rx: 0.86, ry: 0.16,
            desc: "Click the system tray capsule at top-right or press Super+N to summon the customizable TDL 2.0 Control Center: Wi-Fi, Bluetooth, Display, PipeWire Audio, MPRIS, and Power Dock.",
            actionLabel: "Summon Control Center",
            trigger: function() { tourCtrl.toggleControlCenter(); }
        },
        {
            id: "LEFT-EDGE HUD",
            title: "Titan System Monitor Cockpit",
            shortcut: "Super + M",
            icon: "\uf080",
            color: TitanTheme.success,
            rx: 0.14, ry: 0.54,
            desc: "Real-time GPU arc gauges for CPU, Memory, Thermal sensors, and Linux PSI (Pressure Stall Information) telemetry with one-click THM v3 governor switching.",
            actionLabel: "Toggle System Monitor",
            trigger: function() { tourCtrl.toggleSysmon(); }
        },
        {
            id: "CENTER STAGE",
            title: "Titan Spotlight Command Bar",
            shortcut: "Super + Space",
            icon: "\uf002",
            color: TitanTheme.warning,
            rx: 0.50, ry: 0.54,
            desc: "Instant sub-millisecond fuzzy launcher for desktop apps, shell commands, math expressions, and system actions—floating directly at the center of your screen.",
            actionLabel: "Launch Titan Spotlight",
            trigger: function() { tourCtrl.toggleSpotlight(); }
        }
    ]

    RowLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 26

        // Left Column: Interactive 16:9 Vector Screen Radar
        Rectangle {
            Layout.preferredWidth: 460
            Layout.fillHeight: true
            radius: 20
            color: Qt.rgba(TitanTheme.crust.r, TitanTheme.crust.g, TitanTheme.crust.b, 0.72)
            border.width: 1
            border.color: Qt.rgba(TitanTheme.info.r, TitanTheme.info.g, TitanTheme.info.b, 0.28)

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
                        text: "INTERACTIVE DESKTOP TOPOLOGY // 1920x1080"
                        color: TitanTheme.info
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "CLICK ANY NODE OR SCREEN EDGE"
                        color: TitanTheme.textLow
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }

                // Miniature 16:9 Screen Viewport
                Rectangle {
                    id: radarScreen
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 14
                    color: Qt.rgba(0.03, 0.05, 0.09, 0.95)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    clip: true

                    // Grid & Crosshair Vector Canvas
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
                        anchors.margins: 10
                        height: 26
                        radius: 13
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
                            width: 108
                            height: 44

                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: parent.active
                                    ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.24)
                                    : Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.75)
                                border.width: parent.active ? 2 : 1
                                border.color: parent.active ? modelData.color : Qt.rgba(1, 1, 1, 0.15)

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: modelData.icon
                                        color: modelData.color
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 13
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
                                            text: modelData.shortcut
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

                    // Bottom Status Strip in Radar
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 10
                        height: 28
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.03)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.06)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            Text {
                                text: "ACTIVE BEACON: " + root.zones[root.selectedZone].id
                                color: root.zones[root.selectedZone].color
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "LOOK AT YOUR REAL SCREEN CORNERS ↗"
                                color: TitanTheme.textMid
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 9
                            }
                        }
                    }
                }
            }
        }

        // Right Column: Selected Hotzone Inspector & Live Trigger Deck
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

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
                        text: "ACT 02 // SPATIAL PERIPHERAL HUD"
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
                text: "Every Screen Edge Is an Instrument"
                color: TitanTheme.textHigh
                font.family: TitanTheme.fontFamily
                font.pixelSize: 26
                font.weight: Font.Black
            }

            // Selected Zone Detailed Card
            Rectangle {
                Layout.fillWidth: true
                height: 175
                radius: 18
                color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.65)
                border.width: 1
                border.color: Qt.rgba(root.zones[root.selectedZone].color.r,
                                      root.zones[root.selectedZone].color.g,
                                      root.zones[root.selectedZone].color.b, 0.5)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            width: 42; height: 42; radius: 12
                            color: Qt.rgba(root.zones[root.selectedZone].color.r,
                                           root.zones[root.selectedZone].color.g,
                                           root.zones[root.selectedZone].color.b, 0.18)
                            border.width: 1
                            border.color: root.zones[root.selectedZone].color

                            Text {
                                anchors.centerIn: parent
                                text: root.zones[root.selectedZone].icon
                                color: root.zones[root.selectedZone].color
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 18
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
                                font.letterSpacing: 1.0
                            }
                            Text {
                                text: root.zones[root.selectedZone].title
                                color: TitanTheme.textHigh
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 18
                                font.weight: Font.Bold
                            }
                        }

                        Rectangle {
                            height: 28
                            width: keyText.implicitWidth + 18
                            radius: 8
                            color: Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.15)
                            Text {
                                id: keyText
                                anchors.centerIn: parent
                                text: root.zones[root.selectedZone].shortcut
                                color: TitanTheme.info
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 11
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
                        implicitWidth: 210
                        text: root.zones[root.selectedZone].actionLabel
                        glyph: "\uf0e7"
                        variant: "primary"
                        onClicked: root.zones[root.selectedZone].trigger()
                    }
                }
            }

            // Quick Selector Strip for All 5 Hotzones
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6

                Text {
                    text: "SELECT A SPATIAL HOTZONE TO INSPECT OR TRIGGER:"
                    color: TitanTheme.textLow
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                }

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
                            Layout.columnSpan: index === 4 ? 2 : 1
                            radius: 10
                            color: isSel
                                ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.16)
                                : Qt.rgba(1, 1, 1, 0.03)
                            border.width: 1
                            border.color: isSel ? modelData.color : Qt.rgba(1, 1, 1, 0.07)

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

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    color: isSel ? TitanTheme.textHigh : TitanTheme.textMid
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: isSel ? Font.Bold : Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.shortcut
                                    color: TitanTheme.textLow
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 10
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
}
