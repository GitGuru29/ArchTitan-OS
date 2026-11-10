import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanPulseModule — ArchTitan Signature Hardware Intelligence Bento Module.
 *
 * Implements the Titan Pulse card:
 * - Header: "Titan Pulse" with options badge
 * - Dual glowing circular / horseshoe gauge meters (CPU % + Temp, RAM %)
 * - Power Profile Selector: Efficiency | Balanced | Performance in Sapphire Cyan
 */
Rectangle {
    id: pulseRoot
    Layout.fillWidth: true
    implicitHeight: 136
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                  ? TitanTheme.accent
                  : (pulseMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)
    border.width: 1

    readonly property int cpuVal: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.cpuUsage : 33
    readonly property int ramVal: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.ramUsage : 49
    readonly property int cpuTemp: 46
    property string activeProfile: "Performance"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        // ── Card Header ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Titan Pulse"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: TitanTheme.textPrimary
            }

            Item { Layout.fillWidth: true }

            // System Monitor / Telemetry settings button
            Rectangle {
                width: 22
                height: 22
                radius: 11
                color: pulseOptMa.containsMouse ? TitanTheme.bgHover : Qt.rgba(1, 1, 1, 0.06)

                Text {
                    anchors.centerIn: parent
                    text: "\uf080" // chart-bar / telemetry
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 10
                    color: pulseOptMa.containsMouse ? TitanTheme.accent : TitanTheme.textMuted
                }

                MouseArea {
                    id: pulseOptMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof systemCtrl !== "undefined" && systemCtrl)
                            systemCtrl.openSettings();
                    }
                }
            }
        }

        // ── Dual Circular Horseshoe Gauge Meters ────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Gauge 1: CPU % + Temp
            Item {
                Layout.fillWidth: true
                height: 48

                Canvas {
                    id: cpuCanvas
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var cx = width / 2;
                        var cy = height / 2;
                        var radius = Math.min(cx, cy) - 4;
                        var startAngle = 0.75 * Math.PI;
                        var endAngle = 2.25 * Math.PI;
                        var sweep = endAngle - startAngle;

                        // Background track
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, startAngle, endAngle);
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08);
                        ctx.lineWidth = 4;
                        ctx.lineCap = "round";
                        ctx.stroke();

                        // Progress arc
                        var progress = Math.max(0.05, Math.min(1.0, pulseRoot.cpuVal / 100.0));
                        var activeAngle = startAngle + sweep * progress;
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, startAngle, activeAngle);
                        ctx.strokeStyle = "#0A84FF";
                        ctx.lineWidth = 4;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }
                }

                Connections {
                    target: pulseRoot
                    function onCpuValChanged() { cpuCanvas.requestPaint(); }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: -2

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: pulseRoot.cpuVal + "%"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: TitanTheme.textPrimary
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: pulseRoot.cpuTemp + "°C"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 8
                        font.weight: Font.Medium
                        color: TitanTheme.textMuted
                    }
                }
            }

            // Gauge 2: RAM % + Label
            Item {
                Layout.fillWidth: true
                height: 48

                Canvas {
                    id: ramCanvas
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var cx = width / 2;
                        var cy = height / 2;
                        var radius = Math.min(cx, cy) - 4;
                        var startAngle = 0.75 * Math.PI;
                        var endAngle = 2.25 * Math.PI;
                        var sweep = endAngle - startAngle;

                        // Background track
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, startAngle, endAngle);
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08);
                        ctx.lineWidth = 4;
                        ctx.lineCap = "round";
                        ctx.stroke();

                        // Progress arc
                        var progress = Math.max(0.05, Math.min(1.0, pulseRoot.ramVal / 100.0));
                        var activeAngle = startAngle + sweep * progress;
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, startAngle, activeAngle);
                        ctx.strokeStyle = "#0A84FF";
                        ctx.lineWidth = 4;
                        ctx.lineCap = "round";
                        ctx.stroke();
                    }
                }

                Connections {
                    target: pulseRoot
                    function onRamValChanged() { ramCanvas.requestPaint(); }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: -2

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: pulseRoot.ramVal + "%"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: TitanTheme.textPrimary
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "RAM"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        font.letterSpacing: 0.5
                        color: TitanTheme.textMuted
                    }
                }
            }
        }

        // ── Power Profile Selector: Efficiency | Balanced | Performance ─────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            radius: 12
            color: TitanTheme.bgInset
            border.color: TitanTheme.borderHairline
            border.width: 1
            clip: true

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // 1. Efficiency
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 9
                    color: pulseRoot.activeProfile === "Efficiency" ? Qt.rgba(0.04, 0.52, 1.0, 0.20) : "transparent"
                    border.color: pulseRoot.activeProfile === "Efficiency" ? TitanTheme.accent : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Efficiency"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 8
                        font.weight: pulseRoot.activeProfile === "Efficiency" ? Font.Bold : Font.Normal
                        color: pulseRoot.activeProfile === "Efficiency" ? TitanTheme.accent : TitanTheme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pulseRoot.activeProfile = "Efficiency"
                    }
                }

                Rectangle { width: 1; height: 10; color: TitanTheme.borderHairline; Layout.alignment: Qt.AlignVCenter }

                // 2. Balanced
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 9
                    color: pulseRoot.activeProfile === "Balanced" ? Qt.rgba(0.04, 0.52, 1.0, 0.20) : "transparent"
                    border.color: pulseRoot.activeProfile === "Balanced" ? TitanTheme.accent : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Balanced"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 8
                        font.weight: pulseRoot.activeProfile === "Balanced" ? Font.Bold : Font.Normal
                        color: pulseRoot.activeProfile === "Balanced" ? TitanTheme.accent : TitanTheme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pulseRoot.activeProfile = "Balanced"
                    }
                }

                Rectangle { width: 1; height: 10; color: TitanTheme.borderHairline; Layout.alignment: Qt.AlignVCenter }

                // 3. Performance
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 9
                    color: pulseRoot.activeProfile === "Performance" ? Qt.rgba(0.04, 0.52, 1.0, 0.20) : "transparent"
                    border.color: pulseRoot.activeProfile === "Performance" ? TitanTheme.accent : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Performance"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 8
                        font.weight: pulseRoot.activeProfile === "Performance" ? Font.Bold : Font.Normal
                        color: pulseRoot.activeProfile === "Performance" ? TitanTheme.accent : TitanTheme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pulseRoot.activeProfile = "Performance"
                    }
                }
            }
        }
    }

    MouseArea {
        id: pulseMa
        anchors.fill: parent
        hoverEnabled: true
        z: -1
    }
}
