import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import ArchTitanSettings
import ArchTitan.TitanUI

ScrollView {
    id: root
    contentWidth: -1
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    property color textHigh: TitanTheme.textHigh
    property color textMid:  TitanTheme.textMid
    property color textSub:  TitanTheme.textLow
    property color textLow:  TitanTheme.textLow
    property color accent:   TitanTheme.accent
    property color green:    TitanTheme.success
    property color orange:   TitanTheme.warning
    property color red:      TitanTheme.danger

    readonly property var screenOffOptions: [
        { label: "1m",  val: 60 },
        { label: "2m",  val: 120 },
        { label: "5m",  val: 300 },
        { label: "10m", val: 600 },
        { label: "15m", val: 900 },
        { label: "30m", val: 1800 }
    ]

    readonly property var activeScreenOffModel: {
        var opts = screenOffOptions.slice();
        var current = SettingsBackend.screenTimeout;
        var found = false;
        for (var i = 0; i < opts.length; i++) {
            if (opts[i].val === current) {
                found = true;
                break;
            }
        }
        if (!found) {
            var lbl = current >= 60 ? Math.round(current / 60) + "m" : current + "s";
            opts.push({ label: lbl, val: current });
            opts.sort(function(a, b) { return a.val - b.val; });
        }
        return opts;
    }

    readonly property var suspendOptions: [
        { label: "Never", val: 99999 },
        { label: "5m",  val: 300 },
        { label: "10m", val: 600 },
        { label: "15m", val: 900 },
        { label: "30m", val: 1800 },
        { label: "1h",  val: 3600 },
        { label: "2h",  val: 7200 }
    ]

    readonly property var activeSuspendModel: {
        var opts = suspendOptions.slice();
        var current = SettingsBackend.suspendTimeout;
        var found = false;
        for (var i = 0; i < opts.length; i++) {
            if (opts[i].val === current) {
                found = true;
                break;
            }
        }
        if (!found) {
            var lbl = current >= 3600 ? Math.round(current / 3600) + "h" : Math.round(current / 60) + "m";
            opts.push({ label: lbl, val: current });
            opts.sort(function(a, b) {
                if (a.val === 99999) return -1;
                if (b.val === 99999) return 1;
                return a.val - b.val;
            });
        }
        return opts;
    }

    ColumnLayout {
        width: root.availableWidth
        spacing: 0

        Item { height: 20 }

        // ── Page Header ──────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            spacing: 4

            Text {
                text: "Power"
                font { pixelSize: 22; family: "Inter" }
                font.weight: Font.Bold
                color: root.textHigh
            }
        }

        Item { height: 20 }

        // ── Top Stats Bar ──────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            height: 76; radius: 10
            color: TitanTheme.bg3
            border.width: 1; border.color: globalBorder1

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // BATTERY
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 16
                    spacing: 4

                    Text {
                        text: "BATTERY"
                        font { pixelSize: 9; family: "Inter" }
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                        color: root.textSub
                    }

                    Row {
                        spacing: 2
                        Text {
                            text: SystemInfo.batteryLevel
                            font { pixelSize: 22; family: "Inter" }
                            font.weight: Font.Bold
                            color: SystemInfo.batteryLevel > 40 ? root.green
                                 : SystemInfo.batteryLevel > 20 ? root.orange : root.red
                            anchors.baseline: percentText1.baseline
                        }
                        Text {
                            id: percentText1
                            text: "%"
                            font { pixelSize: 13; family: "Inter" }
                            color: root.textMid
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3
                        }
                    }
                }

                Rectangle { width: 1; height: 44; color: globalBorder1 }

                // HEALTH
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 16
                    spacing: 4

                    Text {
                        text: "HEALTH"
                        font { pixelSize: 9; family: "Inter" }
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                        color: root.textSub
                    }

                    Row {
                        spacing: 2
                        Text {
                            text: SystemInfo.batteryHealth >= 0 ? SystemInfo.batteryHealth : "N/A"
                            font { pixelSize: 22; family: "Inter" }
                            font.weight: Font.Bold
                            color: root.textHigh
                            anchors.baseline: percentText2.baseline
                        }
                        Text {
                            id: percentText2
                            text: "%"
                            font { pixelSize: 13; family: "Inter" }
                            color: root.textMid
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3
                            visible: SystemInfo.batteryHealth >= 0
                        }
                    }
                }

                Rectangle { width: 1; height: 44; color: globalBorder1 }

                // CYCLES
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 16
                    spacing: 4

                    Text {
                        text: "CYCLES"
                        font { pixelSize: 9; family: "Inter" }
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                        color: root.textSub
                    }

                    Text {
                        text: SystemInfo.batteryCycles >= 0 ? SystemInfo.batteryCycles : "N/A"
                        font { pixelSize: 22; family: "Inter" }
                        font.weight: Font.Bold
                        color: root.orange
                    }
                }

                Rectangle { width: 1; height: 44; color: globalBorder1 }

                // CONDITION
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 16; Layout.rightMargin: 16
                    spacing: 4

                    Text {
                        text: "CONDITION"
                        font { pixelSize: 9; family: "Inter" }
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                        color: root.textSub
                    }

                    Text {
                        text: {
                            var h = SystemInfo.batteryHealth
                            if (h < 0) return "Unknown"
                            if (h >= 90) return "Excellent"
                            if (h >= 80) return "Good"
                            if (h >= 60) return "Fair"
                            return "Poor"
                        }
                        font { pixelSize: 18; family: "Inter" }
                        font.weight: Font.Bold
                        color: root.green
                    }
                }
            }
        }

        Item { height: 24 }

        // ── 2-Column Main Section ──────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            spacing: 24
            Layout.alignment: Qt.AlignTop

            // Left Column (Power Mode, Timeouts, Live Draw)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 580
                spacing: 24
                Layout.alignment: Qt.AlignTop

                // POWER MODE
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "POWER MODE"
                        font { pixelSize: 10; family: "Inter" }
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                        color: root.textSub
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Repeater {
                            model: [
                                { name: "Power Saver", label: "Power saver", desc: "Maximize battery", accent: TitanTheme.success },
                                { name: "Balanced",    label: "Balanced",    desc: "Smart performance", accent: TitanTheme.info },
                                { name: "Performance", label: "Performance", desc: "Max CPU",           accent: TitanTheme.danger }
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 96
                                radius: 8
                                property bool sel: SettingsBackend.powerProfile === modelData.name

                                color: sel 
                                       ? Qt.tint(TitanTheme.bg3, Qt.rgba(Qt.color(modelData.accent).r, Qt.color(modelData.accent).g, Qt.color(modelData.accent).b, 0.25)) 
                                       : TitanTheme.bg4
                                border.width: sel ? 2 : 1
                                border.color: sel ? modelData.accent : globalBorder0
                                Behavior on color       { ColorAnimation { duration: TitanTheme.durBase } }
                                Behavior on border.color{ ColorAnimation { duration: TitanTheme.durBase } }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: modelData.label
                                        font { pixelSize: 14; family: "Inter" }
                                        font.weight: Font.Medium
                                        color: root.textHigh
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Text {
                                        text: modelData.desc
                                        font { pixelSize: 11; family: "Inter" }
                                        color: root.textSub
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SettingsBackend.applyPowerProfileNow(modelData.name)
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: globalBorder1 }

                // TIMEOUTS
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "TIMEOUTS"
                        font { pixelSize: 10; family: "Inter" }
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                        color: root.textSub
                    }

                    // Screen Off
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Screen off after"
                            font { pixelSize: 14; family: "Inter" }
                            color: root.textHigh
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: root.activeScreenOffModel
                                delegate: Rectangle {
                                    height: 32
                                    width: optLabel1.implicitWidth + 32
                                    radius: 8
                                    property bool sel: SettingsBackend.screenTimeout === modelData.val
                                    color: sel ? root.accent : TitanTheme.surface0
                                    border.width: 1
                                    border.color: sel ? root.accent : globalBorder0
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        id: optLabel1
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font { pixelSize: 13; family: "Inter" }
                                        font.weight: sel ? Font.Medium : Font.Normal
                                        color: sel ? TitanTheme.accentFg : root.textMid
                                    }

                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: SettingsBackend.applyScreenTimeoutNow(modelData.val)
                                    }
                                }
                            }
                        }
                    }

                    Item { height: 8 }

                    // Suspend
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Suspend after"
                            font { pixelSize: 14; family: "Inter" }
                            color: root.textHigh
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: root.activeSuspendModel
                                delegate: Rectangle {
                                    height: 32
                                    width: optLabel2.implicitWidth + 32
                                    radius: 8
                                    property bool sel: SettingsBackend.suspendTimeout === modelData.val
                                    color: sel ? root.accent : TitanTheme.surface0
                                    border.width: 1
                                    border.color: sel ? root.accent : globalBorder0
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        id: optLabel2
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font { pixelSize: 13; family: "Inter" }
                                        font.weight: sel ? Font.Medium : Font.Normal
                                        color: sel ? TitanTheme.accentFg : root.textMid
                                    }

                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: SettingsBackend.applySuspendTimeoutNow(modelData.val)
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: globalBorder1 }

                // LIVE DRAW
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "LIVE DRAW"
                        font { pixelSize: 10; family: "Inter" }
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                        color: root.textSub
                    }

                    Row {
                        spacing: 6
                        Text {
                            text: {
                                var w = SystemInfo.powerNow / 1000000
                                return w > 0 ? w.toFixed(1) : "—"
                            }
                            font { pixelSize: 24; family: "Inter" }
                            font.weight: Font.Bold
                            color: root.textHigh
                            anchors.baseline: wText.baseline
                        }
                        Text {
                            id: wText
                            text: "W draw"
                            font { pixelSize: 13; family: "Inter" }
                            color: root.textSub
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3
                            visible: (SystemInfo.powerNow / 1000000) > 0
                        }
                    }
                }
            }

            // Right Column (Charging State, Battery Settings)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 360
                spacing: 24
                Layout.alignment: Qt.AlignTop

                // CHARGING STATE
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "CHARGING STATE"
                        font { pixelSize: 10; family: "Inter" }
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                        color: root.textSub
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 80; radius: 8
                        color: SystemInfo.batteryCharging 
                                ? Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.15)
                                : TitanTheme.bg4
                        border.width: 1
                        border.color: SystemInfo.batteryCharging 
                                ? TitanTheme.success 
                                : globalBorder0
                        Behavior on color { ColorAnimation { duration: TitanTheme.durSlow } }
                        Behavior on border.color { ColorAnimation { duration: TitanTheme.durSlow } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: SystemInfo.batteryCharging ? "Charging" : (SystemInfo.acConnected ? "Plugged In" : "On Battery")
                                font { pixelSize: 15; family: "Inter" }
                                font.weight: Font.Medium
                                color: root.textHigh
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "Battery at " + SystemInfo.batteryLevel + "%"
                                font { pixelSize: 12; family: "Inter" }
                                color: root.textSub
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }

                // BATTERY SETTINGS
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Text {
                        text: "BATTERY SETTINGS"
                        font { pixelSize: 10; family: "Inter" }
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                        color: root.textSub
                    }

                    // Battery Protection
                    RowLayout {
                        Layout.fillWidth: true
                        visible: SystemInfo.chargeProtectionSupported

                        ColumnLayout {
                            spacing: 4
                            Layout.fillWidth: true

                            Text {
                                text: "Battery protection"
                                font { pixelSize: 14; family: "Inter" }
                                color: root.textHigh
                            }
                            Text {
                                text: "Caps charge at 80% when plugged in all day."
                                font { pixelSize: 12; family: "Inter" }
                                color: root.textSub
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                        Item { width: 8 }
                        TitanSwitch {
                            onColor: root.accent
                            checked: SystemInfo.chargeProtectionEnabled
                            onCheckedChanged: SystemInfo.setChargeProtection(checked)
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: globalBorder1; visible: SystemInfo.chargeProtectionSupported && SystemInfo.rapidChargeSupported }

                    // Rapid Charge
                    RowLayout {
                        Layout.fillWidth: true
                        visible: SystemInfo.rapidChargeSupported

                        ColumnLayout {
                            spacing: 4
                            Layout.fillWidth: true

                            Text {
                                text: "Rapid charge"
                                font { pixelSize: 14; family: "Inter" }
                                color: root.textHigh
                            }
                            Text {
                                text: "Faster charging, generates more heat."
                                font { pixelSize: 12; family: "Inter" }
                                color: root.textSub
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                        Item { width: 8 }
                        TitanSwitch {
                            onColor: root.accent
                            checked: SystemInfo.rapidChargeEnabled
                            onCheckedChanged: SystemInfo.setRapidCharge(checked)
                        }
                    }
                }
            }
        }

        Item { height: 28 }
    }
}
