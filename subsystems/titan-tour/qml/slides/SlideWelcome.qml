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
        interval: 260
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
        anchors.margins: 28
        spacing: 28

        // Left Column: Triple-Ring GPU Reactor & Live Telemetry Gauges
        Rectangle {
            Layout.preferredWidth: 340
            Layout.fillHeight: true
            radius: 20
            color: Qt.rgba(TitanTheme.crust.r, TitanTheme.crust.g, TitanTheme.crust.b, 0.55)
            border.width: 1
            border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.22)

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
                anchors.margins: 20
                spacing: 14

                // Top Reactor Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "CORE REACTOR // TDL 2.0"
                        color: TitanTheme.info
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: TitanTheme.success
                    }
                    Text {
                        text: "ONLINE"
                        color: TitanTheme.success
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                // Center Triple-Concentric GPU Arc Reactor
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    width: 210
                    height: 210

                    // Ambient Radial Glow
                    Rectangle {
                        anchors.centerIn: parent
                        width: 180; height: 180; radius: 90
                        color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(TitanTheme.info.r, TitanTheme.info.g, TitanTheme.info.b, 0.16)
                    }

                    // Outer Rotating Arc
                    TitanArcItem {
                        anchors.fill: parent
                        rotation: root.spinAngle1
                        color: TitanTheme.accent
                        trackColor: Qt.rgba(1, 1, 1, 0.05)
                        lineWidth: 3.5
                        startAngle: -90.0
                        sweepAngle: 260.0
                        showTrack: true
                        roundCaps: true
                    }

                    // Middle Counter-Rotating Cyan Arc
                    TitanArcItem {
                        anchors.centerIn: parent
                        width: 174
                        height: 174
                        rotation: root.spinAngle2
                        color: TitanTheme.info
                        trackColor: Qt.rgba(1, 1, 1, 0.04)
                        lineWidth: 3.0
                        startAngle: 0.0
                        sweepAngle: 210.0
                        showTrack: true
                        roundCaps: true
                    }

                    // Inner Live CPU Load Ring
                    TitanArcItem {
                        anchors.centerIn: parent
                        width: 140
                        height: 140
                        color: TitanTheme.success
                        trackColor: Qt.rgba(1, 1, 1, 0.06)
                        lineWidth: 4.5
                        startAngle: -90.0
                        sweepAngle: 360.0 * Math.max(0.12, tourCtrl.cpuUsage)
                        showTrack: true
                        roundCaps: true
                    }

                    // Inner Core Emblem
                    Rectangle {
                        anchors.centerIn: parent
                        width: 98
                        height: 98
                        radius: 49
                        color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.92)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.14)

                        Image {
                            anchors.centerIn: parent
                            width: 64
                            height: 64
                            source: tourCtrl.logoUrl
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }
                    }
                }

                // Live 3-Mini Gauge Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { label: "CPU LOAD", value: Math.round(tourCtrl.cpuUsage * 100) + "%", prog: tourCtrl.cpuUsage, col: TitanTheme.accent },
                            { label: "RAM USED", value: Math.round(tourCtrl.ramUsage * 100) + "%", prog: tourCtrl.ramUsage, col: TitanTheme.info },
                            { label: "THERMAL",  value: tourCtrl.cpuTemp + "°C", prog: Math.min(1.0, tourCtrl.cpuTemp / 100.0), col: TitanTheme.success }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 68
                            radius: 12
                            color: Qt.rgba(1, 1, 1, 0.03)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.07)

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

                // Interactive Diagnostic Trigger Button
                TitanButton {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    text: root.sweepRunning ? "Scanning Subsystems..." : "Run Subsystem Diagnostic"
                    glyph: "\uf0e7"
                    variant: "secondary"
                    onClicked: root.runDiagnosticSweep()
                }
            }
        }

        // Right Column: Hero Mission Briefing + Hardware Bento Grid + Subsystem Matrix
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // Act Eyebrow Pill
            RowLayout {
                spacing: 10
                Rectangle {
                    height: 24
                    width: actTag.implicitWidth + 16
                    radius: 12
                    color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.16)
                    border.width: 1
                    border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.45)

                    Text {
                        id: actTag
                        anchors.centerIn: parent
                        text: "ACT 01 // GENESIS ARCHITECTURE"
                        color: TitanTheme.accent
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }
                }

                Text {
                    text: "Notice the live spatial HUD beacons around your screen edges"
                    color: TitanTheme.info
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 11
                }
            }

            // Title & Description
            Text {
                Layout.fillWidth: true
                text: "Precision-Engineered Wayland Workstation"
                color: TitanTheme.textHigh
                font.family: TitanTheme.fontFamily
                font.pixelSize: 28
                font.weight: Font.Black
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                text: "ArchTitan replaces bloated web-wrapped shells with a zero-compromise C++20 & Qt6 QML desktop ecosystem. Every panel, HUD overlay, and hardware governor runs natively on Wayland LayerShell."
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
                        { icon: "\uf538", label: "SYSTEM MEMORY",  value: tourCtrl.ramTotal + " LPDDR/DDR", accent: TitanTheme.mauve },
                        { icon: "\uf17c", label: "KERNEL ENGINE",  value: "Linux " + tourCtrl.kernelVersion, accent: TitanTheme.success }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 62
                        radius: 14
                        color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.55)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        // Left accent rim
                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: 28
                            radius: 1.5
                            color: modelData.accent
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 12
                            spacing: 12

                            Rectangle {
                                width: 36; height: 36; radius: 10
                                color: Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.14)
                                border.width: 1
                                border.color: Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.35)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: modelData.accent
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 15
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

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

            // Native Subsystem Diagnostic Strip (6 C++20 Daemons)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: Qt.rgba(TitanTheme.crust.r, TitanTheme.crust.g, TitanTheme.crust.b, 0.6)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "NATIVE C++20 / QT6 LAYER-SHELL SUBSYSTEMS"
                            color: TitanTheme.textLow
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 1.0
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: (root.diagnosticIndex + 1) + "/6 VERIFIED"
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
                                { name: "titan-shell",         role: "Top Bar & Island",     icon: "\uf2d0" },
                                { name: "titan-quicksettings", role: "Stepped Bento CC",     icon: "\uf1de" },
                                { name: "titan-spotlight",     role: "Fuzzy App Launcher",   icon: "\uf002" },
                                { name: "titan-sysmon",        role: "Telemetry HUD",        icon: "\uf080" },
                                { name: "titan-nc",            role: "Notification Daemon",  icon: "\uf0f3" },
                                { name: "titan-thm",           role: "Thermal/PSI Governor", icon: "\uf0e7" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool verified: index <= root.diagnosticIndex

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 10
                                color: verified
                                    ? Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.09)
                                    : Qt.rgba(1, 1, 1, 0.02)
                                border.width: 1
                                border.color: verified
                                    ? Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.35)
                                    : Qt.rgba(1, 1, 1, 0.06)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Text {
                                        text: verified ? "\uf00c" : modelData.icon
                                        color: verified ? TitanTheme.success : TitanTheme.textLow
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
                            }
                        }
                    }
                }
            }
        }
    }
}
