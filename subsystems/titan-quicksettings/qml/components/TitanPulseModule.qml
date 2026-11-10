import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanPulseModule — ArchTitan Signature Hardware Intelligence Bento Module.
 *
 * Implements the approved mockup Titan Pulse card:
 * - Header: "Titan Pulse" with options badge
 * - Dual glowing circular / horseshoe gauge meters (CPU % + Temp, RAM %)
 * - Power Profile Selector: Efficiency | Balanced | Performance
 * - In-place corner resize handle
 */
Rectangle {
    id: pulseRoot
    Layout.fillWidth: true
    implicitHeight: 148
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                  ? TitanTheme.accent
                  : (pulseMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)
    border.width: 1

    readonly property int cpuVal: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.cpuUsage : 32
    readonly property int ramVal: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.ramUsage : 38
    readonly property int cpuTemp: 46
    property string activeProfile: "Performance"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

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

            // Triple dot options pill
            Rectangle {
                width: 20
                height: 14
                radius: 7
                color: Qt.rgba(1, 1, 1, 0.06)

                Text {
                    anchors.centerIn: parent
                    text: "•••"
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: TitanTheme.textMuted
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
                height: 64

                Canvas {
                    id: cpuCanvas
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var cx = width / 2;
                        var cy = height / 2 - 2;
                        var radius = Math.min(cx, cy) - 5;
                        var startAngle = 0.75 * Math.PI;
                        var endAngle = 2.25 * Math.PI;
                        var sweep = endAngle - startAngle;

                        // Background track
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, startAngle, endAngle);
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08);
                        ctx.lineWidth = 5;
                        ctx.lineCap = "round";
                        ctx.stroke();

                        // Progress arc
                        var progress = Math.max(0.05, Math.min(1.0, pulseRoot.cpuVal / 100.0));
                        var activeAngle = startAngle + sweep * progress;
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, startAngle, activeAngle);
                        ctx.strokeStyle = "#FF6B00";
                        ctx.lineWidth = 5;
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
                        font.pixelSize: 13
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
                height: 64

                Canvas {
                    id: ramCanvas
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var cx = width / 2;
                        var cy = height / 2 - 2;
                        var radius = Math.min(cx, cy) - 5;
                        var startAngle = 0.75 * Math.PI;
                        var endAngle = 2.25 * Math.PI;
                        var sweep = endAngle - startAngle;

                        // Background track
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, startAngle, endAngle);
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08);
                        ctx.lineWidth = 5;
                        ctx.lineCap = "round";
                        ctx.stroke();

                        // Progress arc
                        var progress = Math.max(0.05, Math.min(1.0, pulseRoot.ramVal / 100.0));
                        var activeAngle = startAngle + sweep * progress;
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, startAngle, activeAngle);
                        ctx.strokeStyle = "#FF6B00";
                        ctx.lineWidth = 5;
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
                        font.pixelSize: 13
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
            height: 24
            radius: 12
            color: TitanTheme.bgInset
            border.color: TitanTheme.borderHairline
            border.width: 1

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // 1. Efficiency
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: pulseRoot.activeProfile === "Efficiency" ? Qt.rgba(1.0, 0.42, 0.0, 0.15) : "transparent"
                    border.color: pulseRoot.activeProfile === "Efficiency" ? TitanTheme.accent : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Efficiency"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 9
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

                Rectangle { width: 1; height: 12; color: TitanTheme.borderHairline; Layout.alignment: Qt.AlignVCenter }

                // 2. Balanced
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: pulseRoot.activeProfile === "Balanced" ? Qt.rgba(1.0, 0.42, 0.0, 0.15) : "transparent"
                    border.color: pulseRoot.activeProfile === "Balanced" ? TitanTheme.accent : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Balanced"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 9
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

                Rectangle { width: 1; height: 12; color: TitanTheme.borderHairline; Layout.alignment: Qt.AlignVCenter }

                // 3. Performance
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: pulseRoot.activeProfile === "Performance" ? Qt.rgba(1.0, 0.42, 0.0, 0.15) : "transparent"
                    border.color: pulseRoot.activeProfile === "Performance" ? TitanTheme.accent : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Performance"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 9
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

    // ── In-Place Corner Resize Handle ───────────────────────────────────────
    Rectangle {
        id: resizeHandle
        width: 18
        height: 18
        radius: 4
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 3
        color: resizeMa.containsMouse ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.12)
        visible: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
        z: 10

        Text {
            anchors.centerIn: parent
            text: "⤡"
            font.pixelSize: 12
            color: resizeMa.containsMouse ? "#0D1017" : TitanTheme.accent
        }

        MouseArea {
            id: resizeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            onClicked: {
                if (typeof systemCtrl !== "undefined" && systemCtrl)
                    systemCtrl.toggleWidgetSize("pulse");
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
