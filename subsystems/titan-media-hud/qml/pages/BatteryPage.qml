import QtQuick
import QtQuick.Layouts
import ArchTitan.Media 1.0
import ArchTitan.TitanUI

/**
 * BatteryPage — Hardware Battery Status & Temperature
 * Displays capacity percentage, charge status, temperature, and battery health.
 */
Item {
    id: batteryPageRoot
    anchors.fill: parent

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        spacing: 14

        // ── ICON BADGE ───────────────────────────────────────────────────
        Rectangle {
            Layout.preferredWidth: 46
            Layout.preferredHeight: 46
            radius: 12
            color: Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.09)
            border.color: Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.25)
            border.width: 1.5

            Text {
                anchors.centerIn: parent
                text: "🔋"
                font.pixelSize: 22
                color: TitanTheme.warning
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: parent.radius + 3
                color: "transparent"
                border.color: Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.19)
                border.width: 1
            }
        }

        // ── DETAILS ──────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            RowLayout {
                spacing: 6

                Rectangle {
                    height: 14
                    width: tagText.implicitWidth + 10
                    radius: 7
                    color: Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.13)
                    border.color: Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.25)
                    border.width: 1

                    Text {
                        id: tagText
                        anchors.centerIn: parent
                        text: "BATTERY STATUS"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        font.letterSpacing: 0.8
                        color: TitanTheme.warning
                    }
                }

                Text {
                    text: (System ? System.batteryPercent : 92) + "%"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                }

                Text {
                    text: "• " + (System ? System.batteryTempFormatted : "37°C")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: TitanTheme.textHigh
                }
            }

            Text {
                Layout.fillWidth: true
                text: (System ? System.batteryStatus : "Discharging") + " • " + (System ? System.batteryHealth : "Good health")
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                color: TitanTheme.textMid
                elide: Text.ElideRight
            }
        }
    }
}
