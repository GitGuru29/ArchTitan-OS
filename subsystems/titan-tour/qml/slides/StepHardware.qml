import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

Item {
    id: root

    readonly property var profiles: [
        {
            id: "power-saver",
            title: "Power Saver (Eco)",
            tag: "SILENT & COOL",
            icon: "\uf06c",
            color: TitanTheme.success,
            desc: "Caps aggressive turbo boost spikes, parks idle cores early, and optimizes background daemons for maximum battery endurance."
        },
        {
            id: "balanced",
            title: "Balanced (Adaptive)",
            tag: "DEFAULT // THM v3",
            icon: "\uf24e",
            color: TitanTheme.info,
            desc: "Continuous PSI memory & CPU regulation. Dynamically scales cgroups v2 weights to ensure the Wayland desktop stays locked at 60-144Hz."
        },
        {
            id: "performance",
            title: "Performance",
            tag: "UNLEASHED BOOST",
            icon: "\uf0e7",
            color: TitanTheme.warning,
            desc: "Locks CPU frequency scaling to peak boost states, unlocks maximum thermal limits, and prioritizes GPU render pipelines for heavy compiles & games."
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        // ── Top: Detected Hardware Header ───────────────────────────────────────
        ColumnLayout {
            spacing: 2
            Text {
                text: "SYSTEM HARDWARE & TELEMETRY"
                color: TitanTheme.accent
                font.family: TitanTheme.monoFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.0
            }
            Text {
                text: "Hardware auto-detected and managed by the Titan Hardware Manager v3 daemon."
                color: TitanTheme.textLow
                font.family: TitanTheme.fontFamily
                font.pixelSize: 12
            }
        }

        // ── Real Hardware Telemetry Grid (4 Badges) ─────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // CPU Chip
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 48
                radius: 8
                color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.6)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Text { text: "\uf2db"; color: TitanTheme.accent; font.family: TitanTheme.monoFamily; font.pixelSize: 14 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text { text: "PROCESSOR"; color: TitanTheme.textLow; font.family: TitanTheme.monoFamily; font.pixelSize: 9 }
                        Text { text: tourCtrl.cpuName; color: TitanTheme.textHigh; font.family: TitanTheme.fontFamily; font.pixelSize: 11; font.weight: 600; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                }
            }

            // RAM Chip
            Rectangle {
                Layout.preferredWidth: 160
                implicitHeight: 48
                radius: 8
                color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.6)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Text { text: "\uf080"; color: TitanTheme.teal; font.family: TitanTheme.monoFamily; font.pixelSize: 14 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text { text: "SYSTEM RAM"; color: TitanTheme.textLow; font.family: TitanTheme.monoFamily; font.pixelSize: 9 }
                        Text { text: tourCtrl.ramTotal; color: TitanTheme.textHigh; font.family: TitanTheme.fontFamily; font.pixelSize: 11; font.weight: 600 }
                    }
                }
            }

            // GPU Chip
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 48
                radius: 8
                color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.6)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Text { text: "\uf108"; color: TitanTheme.info; font.family: TitanTheme.monoFamily; font.pixelSize: 14 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text { text: "GRAPHICS"; color: TitanTheme.textLow; font.family: TitanTheme.monoFamily; font.pixelSize: 9 }
                        Text { text: tourCtrl.gpuName; color: TitanTheme.textHigh; font.family: TitanTheme.fontFamily; font.pixelSize: 11; font.weight: 600; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                }
            }

            // Kernel Chip
            Rectangle {
                Layout.preferredWidth: 160
                implicitHeight: 48
                radius: 8
                color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.6)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    Text { text: "\uf17c"; color: TitanTheme.mauve; font.family: TitanTheme.monoFamily; font.pixelSize: 14 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text { text: "LINUX KERNEL"; color: TitanTheme.textLow; font.family: TitanTheme.monoFamily; font.pixelSize: 9 }
                        Text { text: tourCtrl.kernelVersion; color: TitanTheme.textHigh; font.family: TitanTheme.fontFamily; font.pixelSize: 11; font.weight: 600; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                }
            }
        }

        // ── Performance Profile Selector (Interactive 3 Cards) ──────────────────
        Text {
            text: "SELECT PERFORMANCE GOVERNOR"
            color: TitanTheme.textMid
            font.family: TitanTheme.monoFamily
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 0.8
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Repeater {
                model: root.profiles

                Rectangle {
                    id: profCard
                    property bool isSelected: tourCtrl.activeProfile === modelData.id
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: isSelected ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.14)
                                      : (profMouse.containsMouse ? Qt.rgba(TitanTheme.surface1.r, TitanTheme.surface1.g, TitanTheme.surface1.b, 0.6)
                                                                 : Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.45))
                    border.width: isSelected ? 1.5 : 1
                    border.color: isSelected ? modelData.color
                                             : (profMouse.containsMouse ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.4)
                                                                        : Qt.rgba(1, 1, 1, 0.08))

                    Behavior on color { ColorAnimation { duration: 150 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 6
                                color: Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.18)
                                border.width: 1
                                border.color: modelData.color
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: modelData.color
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 13
                                }
                            }

                            Text {
                                text: modelData.title
                                color: TitanTheme.textHigh
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                color: profCard.isSelected ? modelData.color : "transparent"
                                border.width: 1
                                border.color: profCard.isSelected ? modelData.color : Qt.rgba(1, 1, 1, 0.25)
                                Text {
                                    visible: profCard.isSelected
                                    anchors.centerIn: parent
                                    text: "\uf00c"
                                    color: TitanTheme.crust
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 8
                                }
                            }
                        }

                        Text {
                            text: modelData.desc
                            color: TitanTheme.textLow
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            lineHeight: 1.3
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            wrapMode: Text.WordWrap
                        }
                    }

                    MouseArea {
                        id: profMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            tourCtrl.activeProfile = modelData.id;
                        }
                    }
                }
            }
        }
    }
}
