import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanFooterBar — macOS Control Center Bottom Status & Action Strip.
 *
 * Replaces the bulky top header with a sleek macOS Sequoia/Tahoe footer bar:
 * - Left: Battery indicator + percentage + charging bolt
 * - Center: "Edit Controls" capsule button (morphs into glowing "✓ Done" in edit mode)
 * - Right: Settings gear button & Power menu button
 */
Item {
    id: footerRoot
    Layout.fillWidth: true
    implicitHeight: 34

    property bool inPlaceEditMode: (typeof rootWindow !== "undefined" && rootWindow) ? rootWindow.inPlaceEditMode : false
    readonly property int batteryPct: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.batteryPercent > 0)
                                      ? systemCtrl.batteryPercent : 94
    readonly property bool isCharging: (typeof systemCtrl !== "undefined" && systemCtrl)
                                       ? systemCtrl.batteryCharging : false

    readonly property string batteryGlyph: {
        if (batteryPct >= 85) return "\uf240"; // battery-full
        if (batteryPct >= 60) return "\uf241"; // battery-three-quarters
        if (batteryPct >= 35) return "\uf242"; // battery-half
        if (batteryPct >= 15) return "\uf243"; // battery-quarter
        return "\uf244";                       // battery-empty
    }

    signal editRequested()
    signal settingsRequested()
    signal powerRequested()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 8

        // ── Left: Battery Icon + Percentage + Bolt (only when charging!) ────
        RowLayout {
            spacing: 5

            Text {
                text: footerRoot.batteryGlyph
                font.family: TitanTheme.monoFamily
                font.pixelSize: 13
                color: footerRoot.isCharging ? TitanTheme.green : (footerRoot.batteryPct <= 20 ? TitanTheme.red : TitanTheme.textSecondary)
            }

            Text {
                text: footerRoot.batteryPct + "%"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Bold
                color: TitanTheme.textPrimary
            }

            Text {
                visible: footerRoot.isCharging
                text: "\uf0e7" // bolt — hidden immediately when charger is unplugged!
                font.family: TitanTheme.monoFamily
                font.pixelSize: 10
                color: TitanTheme.green
            }
        }

        Item { Layout.fillWidth: true }

        // ── Center: "Edit Controls" / "✓ Done" Capsule Pill ─────────────────
        Rectangle {
            Layout.preferredWidth: footerRoot.inPlaceEditMode ? 88 : 98
            Layout.preferredHeight: 28
            radius: 14
            color: footerRoot.inPlaceEditMode
                   ? "#0A84FF"
                   : (editPillMa.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.10))
            border.color: footerRoot.inPlaceEditMode
                          ? Qt.rgba(1, 1, 1, 0.35)
                          : Qt.rgba(1, 1, 1, 0.16)
            border.width: 1
            scale: editPillMa.pressed ? 0.94 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: footerRoot.inPlaceEditMode ? "✓ Done" : "Edit Controls"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: "#FFFFFF"
            }

            MouseArea {
                id: editPillMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: footerRoot.editRequested()
            }
        }

        Item { Layout.fillWidth: true }

        // ── Right: Settings Gear & Power Menu Circular Buttons ──────────────
        RowLayout {
            spacing: 6

            // Settings Button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: settingsMa.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.10)
                border.color: Qt.rgba(1, 1, 1, 0.14)
                border.width: 1
                scale: settingsMa.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: 90 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf013" // gear
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 12
                    color: TitanTheme.textPrimary
                }

                MouseArea {
                    id: settingsMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: footerRoot.settingsRequested()
                }
            }

            // Power Button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: powerMa.containsMouse ? Qt.rgba(0.94, 0.27, 0.27, 0.28) : Qt.rgba(1, 1, 1, 0.10)
                border.color: powerMa.containsMouse ? TitanTheme.red : Qt.rgba(1, 1, 1, 0.14)
                border.width: 1
                scale: powerMa.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: 90 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf011" // power-off
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 12
                    color: powerMa.containsMouse ? TitanTheme.red : TitanTheme.textPrimary
                }

                MouseArea {
                    id: powerMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: footerRoot.powerRequested()
                }
            }
        }
    }
}

