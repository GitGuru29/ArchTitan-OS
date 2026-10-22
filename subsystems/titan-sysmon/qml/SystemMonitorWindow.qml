import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Effects
import ArchTitan.TitanUI
import "components"

/**
 * titan-sysmon — ArchTitan left-edge system monitor.
 *
 * A compact, glassy overlay anchored to the left edge and vertically centred,
 * summarising CPU / memory / GPU / storage / thermals and the Titan Hardware
 * Manager v3 state. Toggled by the left-middle hot zone.
 *
 * Blur is supplied compositor-side (see the `titan-sysmon` layer rule). The
 * surface spans the full screen height but the frosted card only occupies the
 * left strip, so `ignore_alpha` keeps the blur confined to the card.
 */
Window {
    id: root

    width: 420
    height: 1080

    flags: Qt.FramelessWindowHint
    color: "transparent"
    visible: false
    title: "titan-sysmon"

    property bool panelOpen: false

    function openPanel() {
        panelOpen = true;
        root.visible = true;
        root.requestActivate();
    }
    function closePanel() {
        panelOpen = false;
        closeTimer.start();
    }
    function togglePanel() {
        if (panelOpen) closePanel();
        else openPanel();
    }

    function tempColor(t) {
        if (t >= 85) return TitanTheme.danger;
        if (t >= 70) return TitanTheme.warning;
        if (t >= 50) return TitanTheme.peach;
        return TitanTheme.success;
    }
    function pressureColor(p) {
        var s = (p || "").toString().toUpperCase();
        if (s.indexOf("CRIT") >= 0 || s.indexOf("HIGH") >= 0) return TitanTheme.danger;
        if (s.indexOf("ELEV") >= 0) return TitanTheme.warning;
        return TitanTheme.success;
    }

    Timer {
        id: closeTimer
        interval: 260
        onTriggered: if (!root.panelOpen) root.visible = false
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.closePanel()
    }

    // ── Slide-in container ───────────────────────────────────────────────────
    Item {
        id: container
        anchors.fill: parent
        x: root.panelOpen ? 0 : -width
        opacity: root.panelOpen ? 1.0 : 0.0
        Behavior on x { NumberAnimation { duration: TitanTheme.durSlow; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // ── Frosted glass background ─────────────────────────────────────────
        Rectangle {
            id: glassCard
            anchors.fill: parent
            anchors.margins: 10
            radius: TitanTheme.radiusWindow
            color: "transparent"
            border.width: 1
            border.color: TitanTheme.border

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: TitanTheme.isDark ? "#B0000000" : "#1A000000"
                shadowBlur: 0.8
                shadowVerticalOffset: TitanTheme.isDark ? 12 : 6
                shadowHorizontalOffset: 0
                autoPaddingEnabled: true
            }

            // Staged fill: vertical gradient, mantle → base
            Rectangle {
                anchors.fill: parent
                radius: glassCard.radius
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: TitanTheme.isDark ? Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.74)
                                                 : Qt.rgba(1, 1, 1, 0.88)
                    }
                    GradientStop {
                        position: 1.0
                        color: TitanTheme.isDark ? Qt.rgba(TitanTheme.base.r, TitanTheme.base.g, TitanTheme.base.b, 0.56)
                                                 : Qt.rgba(1, 1, 1, 0.78)
                    }
                }
            }

            // Inner hairline
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: glassCard.radius - 1
                color: "transparent"
                border.width: 1
                border.color: TitanTheme.borderSubtle
            }

            // Top specular highlight
            Rectangle {
                x: glassCard.radius
                y: 0
                width: glassCard.width - glassCard.radius * 2
                height: 1
                color: TitanTheme.isDark ? "#14FFFFFF" : "#60FFFFFF"
            }

            // Faint accent edge glow along the left rim
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 1
                anchors.verticalCenter: parent.verticalCenter
                width: 2
                height: parent.height - glassCard.radius * 2
                radius: 1
                opacity: 0.35
                color: TitanTheme.accent
            }

            // Film grain (inset so it never reaches the rounded corners)
            Image {
                anchors.fill: parent
                anchors.margins: 22
                source: "qrc:/assets/noise.png"
                fillMode: Image.Tile
                opacity: 0.03
            }
        }

        // ── Scrolling content ────────────────────────────────────────────────
        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 10
            contentWidth: width
            contentHeight: contentColumn.implicitHeight + 28
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contentColumn
                x: 14
                y: 14
                width: flick.width - 28
                spacing: 12

                // ── Header ───────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: TitanTheme.success
                        Layout.alignment: Qt.AlignVCenter
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0;  duration: 900; easing.type: Easing.InOutSine }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: "System Monitor"
                            color: TitanTheme.textHigh
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: TitanTheme.sizeTitle
                            font.weight: TitanTheme.weightBold
                        }
                        Text {
                            text: sysmon.cpuModel
                            color: TitanTheme.textLow
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 9
                            elide: Text.ElideRight
                            Layout.preferredWidth: parent.width
                        }
                    }

                    // THM governor pill
                    Rectangle {
                        visible: sysmon.thmAvailable
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: govText.implicitWidth + 16
                        implicitHeight: 22
                        radius: 9
                        color: TitanTheme.accentSoft
                        border.width: 1
                        border.color: TitanTheme.accentEdge
                        Text {
                            id: govText
                            anchors.centerIn: parent
                            text: (sysmon.thmGovernor || "").toString().toUpperCase()
                            color: TitanTheme.accent
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 9
                            font.weight: TitanTheme.weightSemiBold
                            font.letterSpacing: 0.5
                        }
                    }

                    // Close button
                    Rectangle {
                        id: closeBtn
                        Layout.alignment: Qt.AlignVCenter
                        width: 26; height: 26; radius: 9
                        color: closeArea.containsMouse ? TitanTheme.bg4 : "transparent"
                        border.width: 1
                        border.color: closeArea.containsMouse ? TitanTheme.borderHover : "transparent"
                        TitanIcon {
                            anchors.centerIn: parent
                            glyph: "\uf00d"
                            size: 12
                            color: closeArea.containsMouse ? TitanTheme.textHigh : TitanTheme.textMid
                        }
                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.closePanel()
                        }
                    }
                }

                // ── Hero gauges ──────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Repeater {
                        model: [
                            { cap: "CPU", value: sysmon.cpuUsage / 100.0,
                              disp: Math.round(sysmon.cpuUsage) + "%",
                              col: TitanTheme.info },
                            { cap: "MEM", value: sysmon.ramUsedPct / 100.0,
                              disp: Math.round(sysmon.ramUsedPct) + "%",
                              col: TitanTheme.teal },
                            { cap: "TEMP",
                              value: sysmon.hasAnyTemp ? Math.min(1, sysmon.highestTemp / 100.0) : 0,
                              disp: sysmon.hasAnyTemp ? (Math.round(sysmon.highestTemp) + "°") : "—",
                              col: root.tempColor(sysmon.highestTemp) }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 118
                            radius: TitanTheme.radiusCard
                            color: TitanTheme.glassCard
                            border.width: 1
                            border.color: TitanTheme.borderSubtle

                            GaugeRing {
                                anchors.centerIn: parent
                                width: Math.min(parent.width - 20, 92)
                                height: width
                                value: modelData.value
                                display: modelData.disp
                                caption: modelData.cap
                                ringColor: modelData.col
                            }
                        }
                    }
                }

                // ── CPU ──────────────────────────────────────────────────────
                Section {
                    title: "Processor"
                    glyph: "\uf2db"
                    subtitle: sysmon.cpuCores + " threads"

                    MeterRow {
                        Layout.fillWidth: true
                        label: "Total load"
                        valueText: sysmon.cpuUsage.toFixed(1) + "%"
                        pct: sysmon.cpuUsage
                        barColor: sysmon.cpuUsage >= 85 ? TitanTheme.danger
                                : sysmon.cpuUsage >= 60 ? TitanTheme.warning
                                : TitanTheme.accent
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: "Freq"
                            color: TitanTheme.textLow
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 9
                        }
                        Text {
                            text: sysmon.cpuFreqMhz > 0
                                  ? (sysmon.cpuFreqMhz / 1000).toFixed(2) + " GHz"
                                  : "—"
                            color: TitanTheme.textMid
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Load " + (sysmon.loadAvg || "—")
                            color: TitanTheme.textMid
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                        }
                    }

                    Sparkline {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        points: sysmon.cpuHistory
                        lineColor: TitanTheme.accent
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        Text {
                            text: "Per-core"
                            color: TitanTheme.textLow
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 9
                        }
                        Row {
                            id: coreRow
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 26
                            spacing: 3
                            readonly property int n: sysmon.cpuCoreUsage.length
                            Repeater {
                                model: sysmon.cpuCoreUsage
                                delegate: Item {
                                    width: coreRow.n > 0
                                           ? (coreRow.width - (coreRow.n - 1) * coreRow.spacing) / coreRow.n
                                           : 0
                                    height: coreRow.height
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 2
                                        color: TitanTheme.bgInset
                                    }
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        radius: 2
                                        color: TitanTheme.accent
                                        height: Math.max(2, Math.min(1, modelData / 100.0) * parent.height)
                                        Behavior on height { NumberAnimation { duration: TitanTheme.durBase } }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Memory ───────────────────────────────────────────────────
                Section {
                    title: "Memory"
                    glyph: "\uf538"
                    subtitle: sysmon.ramUsedGb.toFixed(1) + " / " + sysmon.ramTotalGb.toFixed(1) + " GB"

                    MeterRow {
                        Layout.fillWidth: true
                        label: "RAM"
                        valueText: sysmon.ramUsedPct.toFixed(1) + "%"
                        pct: sysmon.ramUsedPct
                        barColor: sysmon.ramUsedPct >= 90 ? TitanTheme.danger
                                : sysmon.ramUsedPct >= 75 ? TitanTheme.warning
                                : TitanTheme.teal
                    }

                    MeterRow {
                        Layout.fillWidth: true
                        visible: sysmon.hasSwap
                        label: "Swap"
                        valueText: sysmon.swapUsedGb.toFixed(1) + " / " + sysmon.swapTotalGb.toFixed(1) + " GB"
                        pct: sysmon.swapUsedPct
                        barColor: TitanTheme.mauve
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: "Pressure"
                            color: TitanTheme.textLow
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 9
                        }
                        Rectangle {
                            implicitWidth: presText.implicitWidth + 14
                            implicitHeight: 18
                            radius: 7
                            color: Qt.rgba(root.pressureColor(sysmon.pressureLevel).r,
                                           root.pressureColor(sysmon.pressureLevel).g,
                                           root.pressureColor(sysmon.pressureLevel).b, 0.16)
                            border.width: 1
                            border.color: Qt.rgba(root.pressureColor(sysmon.pressureLevel).r,
                                                  root.pressureColor(sysmon.pressureLevel).g,
                                                  root.pressureColor(sysmon.pressureLevel).b, 0.4)
                            Text {
                                id: presText
                                anchors.centerIn: parent
                                text: (sysmon.pressureLevel || "—").toString()
                                color: root.pressureColor(sysmon.pressureLevel)
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 9
                                font.weight: TitanTheme.weightSemiBold
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "PSI " + sysmon.memPressure.toFixed(1)
                            color: TitanTheme.textMid
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                        }
                    }

                    Sparkline {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        points: sysmon.ramHistory
                        lineColor: TitanTheme.teal
                    }
                }

                // ── GPU ──────────────────────────────────────────────────────
                Section {
                    title: "Graphics"
                    glyph: "\uf1b3"
                    subtitle: gpuModel.count > 0 ? (gpuModel.count + (gpuModel.count === 1 ? " device" : " devices")) : ""
                    visible: gpuModel.count > 0

                    Repeater {
                        model: gpuModel
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: model.name
                                    color: TitanTheme.textHigh
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: TitanTheme.sizeLabel
                                    font.weight: TitanTheme.weightSemiBold
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: model.vendor
                                    color: TitanTheme.textLow
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 9
                                }
                            }

                            MeterRow {
                                Layout.fillWidth: true
                                label: "Utilisation"
                                valueText: model.util.toFixed(0) + "%"
                                pct: model.util
                                barColor: model.util >= 90 ? TitanTheme.danger : TitanTheme.info
                            }

                            MeterRow {
                                Layout.fillWidth: true
                                visible: model.hasMem
                                label: "VRAM"
                                valueText: model.memUsed + " / " + model.memTotal + " MB"
                                pct: model.memPct
                                barColor: TitanTheme.mauve
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: model.hasTemp
                                Text {
                                    text: "Temperature"
                                    color: TitanTheme.textLow
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 9
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: model.temp + "°C"
                                    color: root.tempColor(model.temp)
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 10
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                visible: index < gpuModel.count - 1
                                height: 1
                                color: TitanTheme.borderSubtle
                            }
                        }
                    }
                }

                // ── Storage ──────────────────────────────────────────────────
                Section {
                    title: "Storage"
                    glyph: "\uf0a0"
                    subtitle: sysmon.diskName !== "" ? sysmon.diskName : "/"

                    MeterRow {
                        Layout.fillWidth: true
                        label: "Root filesystem"
                        valueText: sysmon.diskUsedGb.toFixed(1) + " / " + sysmon.diskTotalGb.toFixed(1) + " GB"
                        pct: sysmon.diskUsedPct
                        barColor: sysmon.diskUsedPct >= 90 ? TitanTheme.danger
                                : sysmon.diskUsedPct >= 75 ? TitanTheme.warning
                                : TitanTheme.success
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: "Free"
                            color: TitanTheme.textLow
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 9
                        }
                        Text {
                            text: sysmon.diskFreeGb.toFixed(1) + " GB"
                            color: TitanTheme.textMid
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "R " + sysmon.diskReadMbs.toFixed(1) + "  W " + sysmon.diskWriteMbs.toFixed(1) + " MB/s"
                            color: TitanTheme.textMid
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                        }
                    }
                }

                // ── Thermals ─────────────────────────────────────────────────
                Section {
                    title: "Thermals"
                    glyph: "\uf2c9"
                    subtitle: sysmon.hasAnyTemp ? sysmon.tempStatus : ""

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Repeater {
                            model: [
                                { label: "CPU", has: sysmon.hasCpuTemp, value: sysmon.cpuTemp },
                                { label: "GPU", has: sysmon.hasGpuTemp, value: sysmon.gpuTemp }
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 58
                                radius: TitanTheme.radiusMd
                                color: TitanTheme.isDark ? TitanTheme.bgInset : Qt.rgba(0, 0, 0, 0.04)
                                border.width: 1
                                border.color: TitanTheme.borderSubtle

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 0
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.has ? (Math.round(modelData.value) + "°C") : "—"
                                        color: modelData.has ? root.tempColor(modelData.value) : TitanTheme.textLow
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 20
                                        font.weight: TitanTheme.weightBold
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.label
                                        color: TitanTheme.textLow
                                        font.family: TitanTheme.fontFamily
                                        font.pixelSize: 9
                                        font.weight: TitanTheme.weightMedium
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: sysmon.hasFan
                        Text {
                            text: "Fans"
                            color: TitanTheme.textLow
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 9
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: sysmon.fanRpm + " RPM"
                            color: TitanTheme.textMid
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                        }
                    }

                    Sparkline {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        points: sysmon.tempHistory
                        lineColor: root.tempColor(sysmon.highestTemp)
                        minValue: 0.0
                        maxValue: 1.0
                    }
                }

                // ── Titan Hardware Manager ───────────────────────────────────
                Section {
                    title: "Titan Hardware Manager"
                    glyph: "\uf0e7"
                    subtitle: sysmon.thmAvailable
                              ? (sysmon.thmWorkloadCount + " workloads")
                              : "offline"

                    // Offline state
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: !sysmon.thmAvailable
                        spacing: 4
                        Text {
                            text: "THM v3 telemetry unavailable"
                            color: TitanTheme.textMid
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: TitanTheme.sizeLabel
                        }
                        Text {
                            text: "Start titan-hwm.service to see pressure, governor and live workload decisions."
                            color: TitanTheme.textLow
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 9
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    // Online state
                    RowLayout {
                        Layout.fillWidth: true
                        visible: sysmon.thmAvailable
                        spacing: 8

                        Rectangle {
                            implicitWidth: lpText.implicitWidth + 14
                            implicitHeight: 18
                            radius: 7
                            color: Qt.rgba(root.pressureColor(sysmon.thmPressure).r,
                                           root.pressureColor(sysmon.thmPressure).g,
                                           root.pressureColor(sysmon.thmPressure).b, 0.16)
                            border.width: 1
                            border.color: Qt.rgba(root.pressureColor(sysmon.thmPressure).r,
                                                  root.pressureColor(sysmon.thmPressure).g,
                                                  root.pressureColor(sysmon.thmPressure).b, 0.4)
                            Text {
                                id: lpText
                                anchors.centerIn: parent
                                text: (sysmon.thmPressure || "—") + " pressure"
                                color: root.pressureColor(sysmon.thmPressure)
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 9
                                font.weight: TitanTheme.weightSemiBold
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: sysmon.thmActiveWorkloads + " active / " + sysmon.thmWorkloadCount
                            color: TitanTheme.textMid
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                        }
                    }

                    Sparkline {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        visible: sysmon.thmAvailable
                        points: sysmon.thmPressureHistory
                        lineColor: TitanTheme.mauve
                        fillTop: Qt.rgba(TitanTheme.mauve.r, TitanTheme.mauve.g, TitanTheme.mauve.b, 0.24)
                        fillBottom: Qt.rgba(TitanTheme.mauve.r, TitanTheme.mauve.g, TitanTheme.mauve.b, 0.0)
                    }

                    Repeater {
                        model: sysmon.thmAvailable ? sysmon.thmWorkloads : []
                        delegate: WorkloadRow {
                            Layout.fillWidth: true
                            workload: modelData
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: sysmon.thmAvailable && sysmon.thmLastAction !== ""
                        spacing: 6
                        Text {
                            text: "Last action"
                            color: TitanTheme.textLow
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 9
                        }
                        Text {
                            Layout.fillWidth: true
                            text: sysmon.thmLastAction + " · " + sysmon.thmLastActionTarget
                            color: TitanTheme.textMid
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                            elide: Text.ElideMiddle
                        }
                    }
                }

                Item { implicitHeight: 4; Layout.fillWidth: true }
            }
        }
    }
}
