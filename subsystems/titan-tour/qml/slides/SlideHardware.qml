import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

Item {
    id: root

    Connections {
        target: tourCtrl
        function onTelemetryChanged() {
            waveCanvas.requestPaint();
        }
    }

    readonly property var profiles: [
        {
            id: "power-saver",
            title: "EFFICIENCY // ECO",
            sub: "Max Battery & Silent Acoustics",
            icon: "\uf06c",
            color: TitanTheme.success,
            epp: "EPP: power / powersave",
            psi: "PSI Guard: Aggressive (>15%)",
            desc: "Caps turbo boost spikes, parks idle cores early, and reduces background compositor blur passes for silent thermals."
        },
        {
            id: "balanced",
            title: "BALANCED // ADAPTIVE",
            sub: "Dynamic PSI-Aware Governor (Default)",
            icon: "\uf24e",
            color: TitanTheme.info,
            epp: "EPP: balance_performance",
            psi: "PSI Guard: Dynamic (>25%)",
            desc: "Monitors /proc/pressure/{cpu,memory,io} every 500ms—boosting interactive Wayland threads while throttling runaway background builds."
        },
        {
            id: "performance",
            title: "PERFORMANCE // UNLEASHED",
            sub: "Zero-Latency Peak Clock Locks",
            icon: "\uf0e7",
            color: TitanTheme.warning,
            epp: "EPP: performance (Max Boost)",
            psi: "PSI Guard: Real-time Priority",
            desc: "Locks CPU frequency scaling to peak boost clocks, prioritizes GPU render queues, and disables USB/PCIe runtime autosuspend."
        }
    ]

    RowLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 26

        // Left Column: GPU Arc Instrument Cluster + Real-Time Scrolling Waveform
        Rectangle {
            Layout.preferredWidth: 440
            Layout.fillHeight: true
            radius: 20
            color: Qt.rgba(TitanTheme.crust.r, TitanTheme.crust.g, TitanTheme.crust.b, 0.72)
            border.width: 1
            border.color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.3)

            TitanReticle {
                anchors.fill: parent
                anchors.margins: 10
                color: TitanTheme.success
                bracketLength: 14
                bracketThickness: 2
                opacity: 0.45
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "LIVE KERNEL TELEMETRY // /PROC/STAT + PSI"
                        color: TitanTheme.success
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "800ms SAMPLE"
                        color: TitanTheme.textLow
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }

                // 3 GPU-Rendered TitanArcItem Gauges
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Repeater {
                        model: [
                            { label: "CPU UTIL", val: Math.round(tourCtrl.cpuUsage * 100) + "%", prog: tourCtrl.cpuUsage, col: TitanTheme.accent, sub: "Zen Scheduler" },
                            { label: "MEMORY",   val: Math.round(tourCtrl.ramUsage * 100) + "%", prog: tourCtrl.ramUsage, col: TitanTheme.info, sub: tourCtrl.ramTotal },
                            { label: "THERMAL",  val: tourCtrl.cpuTemp + "°C", prog: Math.min(1.0, tourCtrl.cpuTemp / 100.0), col: TitanTheme.success, sub: "Package Sensor" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 146
                            radius: 14
                            color: Qt.rgba(1, 1, 1, 0.03)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.07)

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 86
                                    height: 86

                                    TitanArcItem {
                                        anchors.fill: parent
                                        color: modelData.col
                                        trackColor: Qt.rgba(1, 1, 1, 0.07)
                                        lineWidth: 5.5
                                        startAngle: -90.0
                                        sweepAngle: 360.0 * Math.max(0.06, modelData.prog)
                                        showTrack: true
                                        roundCaps: true
                                    }

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 0
                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: modelData.val
                                            color: TitanTheme.textHigh
                                            font.family: TitanTheme.monoFamily
                                            font.pixelSize: 16
                                            font.weight: Font.Black
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: modelData.label
                                            color: TitanTheme.textLow
                                            font.family: TitanTheme.monoFamily
                                            font.pixelSize: 8
                                            font.weight: Font.Bold
                                        }
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.sub
                                    color: modelData.col
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                }
                            }
                        }
                    }
                }

                // Real-Time Scrolling Waveform Canvas
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 14
                    color: Qt.rgba(0.02, 0.04, 0.08, 0.95)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    clip: true

                    Canvas {
                        id: waveCanvas
                        anchors.fill: parent
                        anchors.margins: 8
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            // Subtle horizontal grid lines
                            ctx.strokeStyle = "rgba(255, 255, 255, 0.05)";
                            ctx.lineWidth = 1;
                            for (var g = 1; g <= 3; g++) {
                                var gy = (height / 4) * g;
                                ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(width, gy); ctx.stroke();
                            }

                            var hist = tourCtrl.cpuHistory;
                            if (!hist || hist.length < 2) return;

                            var stepX = width / (hist.length - 1);

                            // Fill area under waveform
                            var grad = ctx.createLinearGradient(0, 0, 0, height);
                            grad.addColorStop(0.0, "rgba(56, 189, 248, 0.36)");
                            grad.addColorStop(1.0, "rgba(56, 189, 248, 0.01)");

                            ctx.beginPath();
                            ctx.moveTo(0, height);
                            for (var i = 0; i < hist.length; i++) {
                                var val = Math.max(0.04, Math.min(0.96, hist[i]));
                                var px = i * stepX;
                                var py = height - val * (height - 14) - 4;
                                ctx.lineTo(px, py);
                            }
                            ctx.lineTo(width, height);
                            ctx.closePath();
                            ctx.fillStyle = grad;
                            ctx.fill();

                            // Stroke top waveform line
                            ctx.beginPath();
                            for (var j = 0; j < hist.length; j++) {
                                var v2 = Math.max(0.04, Math.min(0.96, hist[j]));
                                var x2 = j * stepX;
                                var y2 = height - v2 * (height - 14) - 4;
                                if (j === 0) ctx.moveTo(x2, y2);
                                else ctx.lineTo(x2, y2);
                            }
                            ctx.strokeStyle = "#38BDF8";
                            ctx.lineWidth = 2.2;
                            ctx.stroke();
                        }
                    }

                    RowLayout {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 10
                        Text {
                            text: "CPU & PSI REALTIME WAVEFORM"
                            color: TitanTheme.info
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "PSI MEM: " + tourCtrl.psiMemory.toFixed(2) + "%"
                            color: TitanTheme.success
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }
                }

                TitanButton {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    text: "Toggle Titan System Monitor HUD (Super+M)"
                    glyph: "\uf080"
                    variant: "secondary"
                    onClicked: tourCtrl.toggleSysmon()
                }
            }
        }

        // Right Column: THM v3 Autonomous Power Governor Selector
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            RowLayout {
                spacing: 10
                Rectangle {
                    height: 24
                    width: thmTag.implicitWidth + 16
                    radius: 12
                    color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.16)
                    border.width: 1
                    border.color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.45)

                    Text {
                        id: thmTag
                        anchors.centerIn: parent
                        text: "ACT 05 // TITAN HARDWARE MANAGER v3"
                        color: TitanTheme.success
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "PSI-Aware Kernel Telemetry & Power"
                color: TitanTheme.textHigh
                font.family: TitanTheme.fontFamily
                font.pixelSize: 26
                font.weight: Font.Black
            }

            Text {
                Layout.fillWidth: true
                text: "Select a live hardware profile below. Titan Hardware Manager (THM v3) tunes CPU frequency scaling, energy performance preference (EPP), and Linux PSI memory stall guards on the fly."
                color: TitanTheme.textMid
                font.family: TitanTheme.fontFamily
                font.pixelSize: 12
                lineHeight: 1.3
                wrapMode: Text.WordWrap
            }

            // 3 Interactive Power Governor Cards
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                Repeater {
                    model: root.profiles

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isCurrent: tourCtrl.activeProfile === modelData.id

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 16
                        color: isCurrent
                            ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.15)
                            : Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.55)
                        border.width: isCurrent ? 2 : 1
                        border.color: isCurrent ? modelData.color : Qt.rgba(1, 1, 1, 0.08)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    width: 34; height: 34; radius: 10
                                    color: Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.2)
                                    border.width: 1
                                    border.color: modelData.color

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        color: modelData.color
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 15
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: modelData.title
                                        color: TitanTheme.textHigh
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 13
                                        font.weight: Font.Black
                                    }
                                    Text {
                                        text: modelData.sub
                                        color: modelData.color
                                        font.family: TitanTheme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                    }
                                }

                                Rectangle {
                                    height: 24
                                    width: stateLbl.implicitWidth + 16
                                    radius: 12
                                    color: isCurrent ? modelData.color : Qt.rgba(1, 1, 1, 0.06)
                                    Text {
                                        id: stateLbl
                                        anchors.centerIn: parent
                                        text: isCurrent ? "ACTIVE GOVERNOR" : "ACTIVATE"
                                        color: isCurrent ? TitanTheme.crust : TitanTheme.textMid
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 9
                                        font.weight: Font.Black
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.desc
                                color: TitanTheme.textMid
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 11
                                lineHeight: 1.25
                                wrapMode: Text.WordWrap
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Text {
                                    text: modelData.epp
                                    color: TitanTheme.textLow
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                }
                                Text { text: "•"; color: TitanTheme.textLow }
                                Text {
                                    text: modelData.psi
                                    color: TitanTheme.textLow
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                tourCtrl.setPowerProfile(modelData.id);
                            }
                        }
                    }
                }
            }
        }
    }
}
