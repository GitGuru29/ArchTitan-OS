import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * PerformanceWidget — Real-Time Hardware Resource Bento Monitor.
 *
 * Super-round 24px card displaying live CPU & RAM usage percentages
 * with concentric capsule progress bars and Catppuccin accents.
 */
Rectangle {
    id: perfRoot
    Layout.fillWidth: true
    implicitHeight: perfCol.implicitHeight + 22
    radius: TitanTheme.radiusCard // 24px super-round
    color: TitanTheme.bgOneUICard
    border.color: TitanTheme.borderGlass
    border.width: 1
    clip: true

    readonly property int cpuVal: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.cpuUsage : 15
    readonly property int ramVal: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.ramUsage : 42

    ColumnLayout {
        id: perfCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // ── 1. CPU Resource Row ─────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // CPU Icon Medallion
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: Qt.rgba(0, 0.82, 1, 0.15)
                border.color: Qt.rgba(0, 0.82, 1, 0.3)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "\uf2db" // microchip / cpu
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 12
                    color: TitanTheme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "CPU"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: TitanTheme.textPrimary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: perfRoot.cpuVal + "%"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: perfRoot.cpuVal > 80 ? TitanTheme.red : TitanTheme.accent
                    }
                }

                // CPU Capsule Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 8
                    radius: 4
                    color: TitanTheme.bgInset
                    clip: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * (perfRoot.cpuVal / 100.0)
                        radius: 4
                        color: perfRoot.cpuVal > 80 ? TitanTheme.red : TitanTheme.accent

                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                    }
                }
            }
        }

        // ── 2. Memory / RAM Resource Row ────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // RAM Icon Medallion
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: Qt.rgba(0.79, 0.53, 0.98, 0.15)
                border.color: Qt.rgba(0.79, 0.53, 0.98, 0.3)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "\uf538" // memory
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 12
                    color: TitanTheme.lavender
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Memory"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: TitanTheme.textPrimary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: perfRoot.ramVal + "%"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: perfRoot.ramVal > 85 ? TitanTheme.red : TitanTheme.lavender
                    }
                }

                // RAM Capsule Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 8
                    radius: 4
                    color: TitanTheme.bgInset
                    clip: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * (perfRoot.ramVal / 100.0)
                        radius: 4
                        color: perfRoot.ramVal > 85 ? TitanTheme.red : TitanTheme.lavender

                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                    }
                }
            }
        }
    }
}
