import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

Item {
    id: root

    property real spinAngle1: 0
    property real spinAngle2: 360
    property int diagnosticIndex: 5
    property bool sweepRunning: false

    NumberAnimation on spinAngle1 {
        from: 0; to: 360; duration: 16000; loops: Animation.Infinite; running: true
    }
    NumberAnimation on spinAngle2 {
        from: 360; to: 0; duration: 11000; loops: Animation.Infinite; running: true
    }

    Timer {
        id: diagTimer
        interval: 240
        repeat: true
        onTriggered: {
            if (root.diagnosticIndex < 5) {
                root.diagnosticIndex++;
                tourCtrl.playSound("step");
            } else {
                root.sweepRunning = false;
                diagTimer.stop();
                tourCtrl.playSound("complete");
            }
        }
    }

    function runDiagnosticSweep() {
        root.diagnosticIndex = 0;
        root.sweepRunning = true;
        tourCtrl.playSound("click");
        diagTimer.restart();
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 26
        spacing: 24

        // Left Column: Triple-Ring GPU Reactor & Live Telemetry Gauges
        Rectangle {
            Layout.preferredWidth: 336
            Layout.fillHeight: true
            radius: 20
            color: Qt.rgba(TitanTheme.crust.r, TitanTheme.crust.g, TitanTheme.crust.b, 0.58)
            border.width: 1
            border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.28)

            TitanReticle {
                anchors.fill: parent
                anchors.margins: 10
                color: TitanTheme.info
                bracketLength: 12
                bracketThickness: 2
                opacity: 0.45
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "LIQUID GLASS ENGINE // TDL 2.0"
                        color: TitanTheme.info
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.1
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: TitanTheme.success
                    }
                    Text {
                        text: "ACTIVE"
                        color: TitanTheme.success
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                // Center Triple-Concentric GPU Arc Reactor
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    width: 204
                    height: 204

                    Rectangle {
                        anchors.centerIn: parent
                        width: 176; height: 176; radius: 88
                        color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(TitanTheme.info.r, TitanTheme.info.g, TitanTheme.info.b, 0.18)
                    }

                    TitanArcItem {
                        anchors.fill: parent
                        rotation: root.spinAngle1
                        color: TitanTheme.accent
                        trackColor: Qt.rgba(1, 1, 1, 0.06)
                        lineWidth: 4
                        startAngle: -90.0
                        sweepAngle: 260.0
                        showTrack: true
                        roundCaps: true
                    }

                    TitanArcItem {
                        anchors.centerIn: parent
                        width: 168
                        height: 168
                        rotation: root.spinAngle2
                        color: TitanTheme.info
                        trackColor: Qt.rgba(1, 1, 1, 0.05)
                        lineWidth: 3
                        startAngle: 0.0
                        sweepAngle: 210.0
                        showTrack: true
                        roundCaps: true
                    }

                    TitanArcItem {
                        anchors.centerIn: parent
                        width: 134
                        height: 134
                        color: TitanTheme.success
                        trackColor: Qt.rgba(1, 1, 1, 0.06)
                        lineWidth: 5
                        startAngle: -90.0
                        sweepAngle: 360.0 * Math.max(0.12, tourCtrl.cpuUsage)
                        showTrack: true
                        roundCaps: true
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 94
                        height: 94
                        radius: 47
                        color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.94)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.16)

                        Image {
                            anchors.centerIn: parent
                            width: 62
                            height: 62
                            source: tourCtrl.logoUrl
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                }

                // Live 3-Mini Gauge Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { label: "CPU LOAD", value: Math.round(tourCtrl.cpuUsage * 100) + "%", col: TitanTheme.accent },
                            { label: "MEMORY",   value: Math.round(tourCtrl.ramUsage * 100) + "%", col: TitanTheme.info },
                            { label: "THERMAL",  value: tourCtrl.cpuTemp + "°C", col: TitanTheme.success }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 62
                            radius: 12
                            color: Qt.rgba(1, 1, 1, 0.03)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.08)

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.value
                                    color: modelData.col
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 15
                                    font.weight: Font.Black
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    color: TitanTheme.textLow
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                }
                            }
                        }
                    }
                }

                TitanButton {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    text: root.sweepRunning ? "Verifying Daemons..." : "Verify Native Daemons"
                    glyph: "\uf0e7"
                    variant: "secondary"
                    onClicked: root.runDiagnosticSweep()
                }
            }
        }

        // Right Column: ArchTitan OS Architecture & Live Subsystem Matrix
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            RowLayout {
                spacing: 10
                Rectangle {
                    height: 24
                    width: actTag.implicitWidth + 16
                    radius: 12
                    color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.18)
                    border.width: 1
                    border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.45)

                    Text {
                        id: actTag
                        anchors.centerIn: parent
                        text: "ACT 01 // ARCHTITAN GENESIS"
                        color: TitanTheme.accent
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }
                }

                Text {
                    text: "Click any peripheral beacon at your screen edges to test live!"
                    color: TitanTheme.info
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 11
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Native C++20 Liquid Glass Workstation"
                color: TitanTheme.textHigh
                font.family: TitanTheme.fontFamily
                font.pixelSize: 27
                font.weight: Font.Black
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                text: "ArchTitan combines Hyprland's Lua compositor engine (>= 0.55) with a custom suite of zero-overhead C++20 & Qt6 LayerShell subsystems, Dual-Kawase frosted blur, and sandboxing via titan-sandboxd."
                color: TitanTheme.textMid
                font.family: TitanTheme.fontFamily
                font.pixelSize: 13
                lineHeight: 1.35
                wrapMode: Text.WordWrap
            }

            // 2x2 Hardware Probe Bento Grid
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: [
                        { icon: "\uf2db", label: "PROCESSOR",      value: tourCtrl.cpuName,       accent: TitanTheme.accent },
                        { icon: "\uf108", label: "GRAPHICS STACK", value: tourCtrl.gpuName,       accent: TitanTheme.info },
                        { icon: "\uf538", label: "SYSTEM MEMORY",  value: tourCtrl.ramTotal + " RAM", accent: TitanTheme.mauve },
                        { icon: "\uf17c", label: "KERNEL ENGINE",  value: "Linux " + tourCtrl.kernelVersion, accent: TitanTheme.success }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 58
                        radius: 14
                        color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.58)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: 26
                            radius: 1.5
                            color: modelData.accent
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 12
                            spacing: 12

                            Rectangle {
                                width: 34; height: 34; radius: 10
                                color: Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.15)
                                border.width: 1
                                border.color: Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.38)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: modelData.accent
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 14
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: modelData.label
                                    color: TitanTheme.textLow
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.8
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.value
                                    color: TitanTheme.textHigh
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            // Native Subsystem Diagnostic Strip (Click any daemon card to trigger it!)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: Qt.rgba(TitanTheme.crust.r, TitanTheme.crust.g, TitanTheme.crust.b, 0.62)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "ARCHTITAN LAYER-SHELL DAEMON SUITE (CLICK ANY CARD TO LAUNCH)"
                            color: TitanTheme.textLow
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 0.8
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: (root.diagnosticIndex + 1) + "/6 ONLINE"
                            color: TitanTheme.success
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 3
                        rowSpacing: 8
                        columnSpacing: 8

                        Repeater {
                            model: [
                                { name: "titan-spotlight",     role: "Super Tap • Fuzzy & Clip", icon: "\uf002", act: function() { tourCtrl.toggleSpotlight(); } },
                                { name: "titan-quicksettings", role: "Super+N • Stepped Bento",  icon: "\uf1de", act: function() { tourCtrl.toggleControlCenter(); } },
                                { name: "titan-menu",          role: "Super+/ • Command Grid",   icon: "\uf009", act: function() { tourCtrl.toggleMenu(); } },
                                { name: "titan-sysmon",        role: "Left-Edge • PSI Telemetry",icon: "\uf080", act: function() { tourCtrl.toggleSysmon(); } },
                                { name: "titan-workspace-hud", role: "Super+Tab • 10-WS Matrix", icon: "\uf2d0", act: function() { tourCtrl.toggleWorkspaceHud(); } },
                                { name: "titan-media-hud",     role: "Super+M • Dynamic Island", icon: "\uf001", act: function() { tourCtrl.toggleMediaHud(); } }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool verified: index <= root.diagnosticIndex

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 10
                                color: dMouse.containsMouse
                                    ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.22)
                                    : (verified
                                        ? Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.09)
                                        : Qt.rgba(1, 1, 1, 0.02))
                                border.width: 1
                                border.color: dMouse.containsMouse
                                    ? TitanTheme.accent
                                    : (verified
                                        ? Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.35)
                                        : Qt.rgba(1, 1, 1, 0.06))

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Text {
                                        text: verified ? "\uf00c" : modelData.icon
                                        color: dMouse.containsMouse ? TitanTheme.accent : (verified ? TitanTheme.success : TitanTheme.textLow)
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 12
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.name
                                            color: TitanTheme.textHigh
                                            font.family: TitanTheme.monoFamily
                                            font.pixelSize: 10
                                            font.weight: Font.Bold
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.role
                                            color: TitanTheme.textLow
                                            font.family: TitanTheme.fontFamily
                                            font.pixelSize: 9
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                MouseArea {
                                    id: dMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.act()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
