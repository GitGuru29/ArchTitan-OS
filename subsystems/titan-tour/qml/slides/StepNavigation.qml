import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI
import "../components"

Item {
    id: root

    property int selectedZone: 0

    readonly property var zones: [
        {
            title: "Spotlight Launcher",
            shortcut: "Super + Space",
            keys: ["SUPER", "SPACE"],
            icon: "\uf002",
            color: TitanTheme.warning,
            desc: "Sub-millisecond fuzzy search for apps, system commands, files, and web search. Floats directly at the center of your screen.",
            actionText: "Launch Spotlight",
            trigger: function() { tourCtrl.toggleSpotlight(); }
        },
        {
            title: "Control Center",
            shortcut: "Super + N",
            keys: ["SUPER", "N"],
            icon: "\uf1de",
            color: TitanTheme.info,
            desc: "Stepped bottleneck control center for Wi-Fi networks, Bluetooth audio, PipeWire volume, display brightness, and power management.",
            actionText: "Open Control Center",
            trigger: function() { tourCtrl.toggleControlCenter(); }
        },
        {
            title: "TitanFocus Mode",
            shortcut: "Super + Alt + F",
            keys: ["SUPER", "ALT", "F"],
            icon: "\uf06e",
            color: TitanTheme.accent,
            desc: "Top-edge Zen focus pill. Tracks focus sessions, silences non-urgent desktop notifications, and helps deep work flow.",
            actionText: "Toggle TitanFocus",
            trigger: function() { tourCtrl.toggleFocus(); }
        },
        {
            title: "System Monitor",
            shortcut: "Super + M",
            keys: ["SUPER", "M"],
            icon: "\uf080",
            color: TitanTheme.success,
            desc: "Real-time telemetry HUD for CPU, Memory, Linux PSI pressure, and dynamic cgroups status with live THM v3 governor badges.",
            actionText: "Open Sysmon",
            trigger: function() { tourCtrl.toggleSysmon(); }
        },
        {
            title: "Application Menu",
            shortcut: "Super",
            keys: ["SUPER"],
            icon: "\uf009",
            color: TitanTheme.mauve,
            desc: "Top-left launcher capsule listing installed software categorized by development, multimedia, utilities, and settings.",
            actionText: "Open App Menu",
            trigger: function() { tourCtrl.toggleMenu(); }
        }
    ]

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // ── Left: Interactive Desktop Schematic ─────────────────────────────────
        Rectangle {
            Layout.preferredWidth: 440
            Layout.fillHeight: true
            radius: 12
            color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.5)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.09)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: "INTERACTIVE DESKTOP MAP"
                    color: TitanTheme.accent
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.0
                }

                // Desktop Monitor Canvas
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: Qt.rgba(0.04, 0.06, 0.10, 0.95)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    clip: true

                    // Top Bar Mockup
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 28
                        color: Qt.rgba(0.08, 0.10, 0.16, 0.95)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.06)

                        // Top-Left: Menu Pill
                        HotspotPill {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            label: "Menu"
                            icon: "\uf009"
                            hotspotColor: TitanTheme.mauve
                            isSelected: root.selectedZone === 4
                            onClicked: { tourCtrl.playSound("tap"); root.selectedZone = 4; }
                        }

                        // Top-Center: Focus Pill
                        HotspotPill {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            label: "TitanFocus"
                            icon: "\uf06e"
                            hotspotColor: TitanTheme.accent
                            isSelected: root.selectedZone === 2
                            onClicked: { tourCtrl.playSound("tap"); root.selectedZone = 2; }
                        }

                        // Top-Right: Control Center
                        HotspotPill {
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            label: "Control"
                            icon: "\uf1de"
                            hotspotColor: TitanTheme.info
                            isSelected: root.selectedZone === 1
                            onClicked: { tourCtrl.playSound("tap"); root.selectedZone = 1; }
                        }
                    }

                    // Left Edge: Sysmon
                    HotspotPill {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        label: "Sysmon"
                        icon: "\uf080"
                        hotspotColor: TitanTheme.success
                        isSelected: root.selectedZone === 3
                        onClicked: { tourCtrl.playSound("tap"); root.selectedZone = 3; }
                    }

                    // Center: Spotlight Launcher
                    HotspotPill {
                        anchors.centerIn: parent
                        label: "Spotlight (Super+Space)"
                        icon: "\uf002"
                        hotspotColor: TitanTheme.warning
                        isSelected: root.selectedZone === 0
                        onClicked: { tourCtrl.playSound("tap"); root.selectedZone = 0; }
                    }
                }

                Text {
                    text: "Click any component on the map above to inspect its shortcut and role."
                    color: TitanTheme.textLow
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // ── Right: Selected Component Detail ────────────────────────────────────
        Rectangle {
            id: detailCard
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.6)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            readonly property var activeZone: root.zones[root.selectedZone]

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // Header badge
                RowLayout {
                    spacing: 10
                    Rectangle {
                        width: 38
                        height: 38
                        radius: 8
                        color: Qt.rgba(detailCard.activeZone.color.r, detailCard.activeZone.color.g, detailCard.activeZone.color.b, 0.18)
                        border.width: 1
                        border.color: Qt.rgba(detailCard.activeZone.color.r, detailCard.activeZone.color.g, detailCard.activeZone.color.b, 0.4)

                        Text {
                            anchors.centerIn: parent
                            text: detailCard.activeZone.icon
                            color: detailCard.activeZone.color
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 16
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: detailCard.activeZone.title
                            color: TitanTheme.textHigh
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                        Text {
                            text: "Global Hyprland Hotzone"
                            color: TitanTheme.textLow
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                        }
                    }
                }

                // Keyboard Shortcut Badges
                Row {
                    spacing: 6
                    Repeater {
                        model: detailCard.activeZone.keys
                        Keycap {
                            text: modelData
                            isAccent: true
                        }
                    }
                }

                // Description
                Text {
                    text: detailCard.activeZone.desc
                    color: TitanTheme.textMid
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 13
                    lineHeight: 1.35
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    wrapMode: Text.WordWrap
                }

                // Live Action Button
                Rectangle {
                    id: triggerBtn
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 8
                    color: triggerMouse.pressed ? Qt.rgba(detailCard.activeZone.color.r, detailCard.activeZone.color.g, detailCard.activeZone.color.b, 0.3)
                                                : (triggerMouse.containsMouse ? Qt.rgba(detailCard.activeZone.color.r, detailCard.activeZone.color.g, detailCard.activeZone.color.b, 0.22)
                                                                              : Qt.rgba(detailCard.activeZone.color.r, detailCard.activeZone.color.g, detailCard.activeZone.color.b, 0.14))
                    border.width: 1
                    border.color: detailCard.activeZone.color

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: detailCard.activeZone.icon
                            color: detailCard.activeZone.color
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: detailCard.activeZone.actionText
                            color: TitanTheme.textHigh
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: triggerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            detailCard.activeZone.trigger();
                        }
                    }
                }
            }
        }
    }
}
