import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanPulseModule — ArchTitan Signature Hardware Intelligence Bento Module.
 *
 * Exposes real-time CPU % & Memory % telemetry alongside interactive
 * system Power Profile switching (Efficiency | Balanced | Performance).
 */
Rectangle {
    id: pulseRoot
    Layout.fillWidth: true
    implicitHeight: pulseCol.implicitHeight + 20
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: TitanTheme.borderHairline
    border.width: 1

    readonly property int cpuVal: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.cpuUsage : 18
    readonly property int ramVal: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.ramUsage : 52
    property string activeProfile: "Balanced"

    ColumnLayout {
        id: pulseCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // ── Header: TITAN PULSE · LIVE ──────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            RowLayout {
                spacing: 6
                Text {
                    text: "\uf2db" // microchip
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 11
                    color: TitanTheme.accent
                }

                Text {
                    text: "TITAN PULSE"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                    color: TitanTheme.textPrimary
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 5

                // Pulsing Orange Beacon
                Rectangle {
                    width: 7
                    height: 7
                    radius: 4
                    color: TitanTheme.accent

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.3; to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.0; to: 0.3; duration: 900; easing.type: Easing.InOutQuad }
                    }
                }

                Text {
                    text: "LIVE"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: TitanTheme.accent
                }
            }
        }

        // ── 2-Column Telemetry: CPU & RAM ───────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // CPU Metric Box
            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: TitanTheme.radiusTile
                color: TitanTheme.bgInset
                border.color: TitanTheme.borderHairline
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "CPU"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: TitanTheme.textSecondary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: pulseRoot.cpuVal + "%"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: pulseRoot.cpuVal > 80 ? TitanTheme.red : TitanTheme.accent
                        }
                    }

                    // CPU Capsule Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.08)
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * (pulseRoot.cpuVal / 100.0)
                            radius: 3
                            color: pulseRoot.cpuVal > 80 ? TitanTheme.red : TitanTheme.accent
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                        }
                    }
                }
            }

            // RAM Metric Box
            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: TitanTheme.radiusTile
                color: TitanTheme.bgInset
                border.color: TitanTheme.borderHairline
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Memory"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: TitanTheme.textSecondary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: pulseRoot.ramVal + "%"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: pulseRoot.ramVal > 85 ? TitanTheme.red : TitanTheme.accent
                        }
                    }

                    // RAM Capsule Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.08)
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * (pulseRoot.ramVal / 100.0)
                            radius: 3
                            color: pulseRoot.ramVal > 85 ? TitanTheme.red : TitanTheme.accent
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                        }
                    }
                }
            }
        }

        // ── Power Profiles Row ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: ["Efficiency", "Balanced", "Performance"]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 26
                    radius: 8
                    property bool isSelected: pulseRoot.activeProfile === modelData

                    color: isSelected
                           ? TitanTheme.accent
                           : (profMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgInset)
                    border.color: isSelected ? TitanTheme.borderActive : TitanTheme.borderHairline
                    border.width: 1

                    scale: profMa.pressed ? 0.94 : 1.0
                    Behavior on scale { NumberAnimation { duration: 110 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        font.weight: parent.isSelected ? Font.Bold : Font.Medium
                        color: parent.isSelected ? "#0D1017" : TitanTheme.textSecondary
                    }

                    MouseArea {
                        id: profMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pulseRoot.activeProfile = modelData;
                        }
                    }
                }
            }
        }
    }
}

