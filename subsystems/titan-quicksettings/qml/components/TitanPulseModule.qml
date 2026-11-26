import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanPulseModule — macOS Control Center Hardware Telemetry Bento Card.
 *
 * Matches the concept mockup:
 * - Header: "Titan Pulse"
 * - Two crisp 52x52 circular ring gauges ("CPU XX%" and "RAM XX%")
 * - Glowing Sapphire "Performance" / "Balanced" / "Efficiency" power profile pill
 */
Rectangle {
    id: pulseRoot
    Layout.fillWidth: true
    implicitHeight: 108
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                  ? TitanTheme.accent
                  : TitanTheme.borderHairline
    border.width: 1

    readonly property int cpuVal: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.cpuUsage : 18
    readonly property int ramVal: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.ramUsage : 42

    property int profileIdx: 0
    readonly property var profiles: ["Performance", "Balanced", "Efficiency"]
    readonly property string activeProfile: profiles[profileIdx]

    onCpuValChanged: cpuRing.requestPaint()
    onRamValChanged: ramRing.requestPaint()

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 8
        anchors.bottomMargin: 10
        spacing: 6

        // ── Card Header ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Titan Pulse"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                color: TitanTheme.textPrimary
            }

            Item { Layout.fillWidth: true }
        }

        // ── Gauges + Power Profile Pill Row ─────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // 1. CPU Ring Gauge (52x52)
            Item {
                width: 52
                height: 52

                Canvas {
                    id: cpuRing
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var cx = width / 2;
                        var cy = height / 2;
                        var r = Math.min(cx, cy) - 3.5;
                        var startA = -0.5 * Math.PI;
                        var fullSweep = 2.0 * Math.PI;

                        // Background ring track
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, fullSweep, false);
                        ctx.lineWidth = 4.2;
                        ctx.strokeStyle = "rgba(255, 255, 255, 0.12)";
                        ctx.stroke();

                        // Sapphire progress arc
                        var pct = Math.max(0.05, Math.min(1.0, pulseRoot.cpuVal / 100.0));
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, startA, startA + fullSweep * pct, false);
                        ctx.lineWidth = 4.2;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = "#0A84FF";
                        ctx.stroke();
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: -1

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "CPU"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        color: TitanTheme.textMuted
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: pulseRoot.cpuVal + "%"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                    }
                }
            }

            // 2. RAM Ring Gauge (52x52)
            Item {
                width: 52
                height: 52

                Canvas {
                    id: ramRing
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var cx = width / 2;
                        var cy = height / 2;
                        var r = Math.min(cx, cy) - 3.5;
                        var startA = -0.5 * Math.PI;
                        var fullSweep = 2.0 * Math.PI;

                        // Background ring track
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, fullSweep, false);
                        ctx.lineWidth = 4.2;
                        ctx.strokeStyle = "rgba(255, 255, 255, 0.12)";
                        ctx.stroke();

                        // Sapphire progress arc
                        var pct = Math.max(0.05, Math.min(1.0, pulseRoot.ramVal / 100.0));
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, startA, startA + fullSweep * pct, false);
                        ctx.lineWidth = 4.2;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = "#0A84FF";
                        ctx.stroke();
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: -1

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "RAM"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        color: TitanTheme.textMuted
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: pulseRoot.ramVal + "%"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                    }
                }
            }

            // 3. Power Profile Capsule Pill (Right side, matching mockup)
            Rectangle {
                Layout.fillWidth: true
                height: 24
                radius: 12
                color: pulseRoot.profileIdx === 0
                       ? "#0A84FF"
                       : (pulseRoot.profileIdx === 1 ? Qt.rgba(0.04, 0.52, 1.0, 0.32) : Qt.rgba(1, 1, 1, 0.14))
                border.color: Qt.rgba(1, 1, 1, 0.20)
                border.width: 1
                scale: profMa.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: 90 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: pulseRoot.activeProfile
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, parent.width - 8)
                    horizontalAlignment: Text.AlignHCenter
                }

                MouseArea {
                    id: profMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) return;
                        pulseRoot.profileIdx = (pulseRoot.profileIdx + 1) % 3;
                    }
                }
            }
        }
    }
}
