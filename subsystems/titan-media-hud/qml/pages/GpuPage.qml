import QtQuick
import QtQuick.Layouts
import ArchTitan.Media 1.0
import ArchTitan.TitanUI

/**
 * GpuPage — GPU Hardware Telemetry & Utilization
 * Displays GPU model name, temperature, and usage percentage.
 */
Item {
    id: gpuPageRoot
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
            color: Qt.rgba(TitanTheme.mauve.r, TitanTheme.mauve.g, TitanTheme.mauve.b, 0.09)
            border.color: Qt.rgba(TitanTheme.mauve.r, TitanTheme.mauve.g, TitanTheme.mauve.b, 0.25)
            border.width: 1.5

            Text {
                anchors.centerIn: parent
                text: "🖥"
                font.pixelSize: 22
                color: TitanTheme.mauve
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: parent.radius + 3
                color: "transparent"
                border.color: Qt.rgba(TitanTheme.mauve.r, TitanTheme.mauve.g, TitanTheme.mauve.b, 0.19)
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
                    color: Qt.rgba(TitanTheme.mauve.r, TitanTheme.mauve.g, TitanTheme.mauve.b, 0.13)
                    border.color: Qt.rgba(TitanTheme.mauve.r, TitanTheme.mauve.g, TitanTheme.mauve.b, 0.25)
                    border.width: 1

                    Text {
                        id: tagText
                        anchors.centerIn: parent
                        text: "GPU STATUS"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        font.letterSpacing: 0.8
                        color: TitanTheme.mauve
                    }
                }

                Text {
                    text: System ? System.gpuModel : "Discrete GPU"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.fillWidth: true
                text: (System ? System.gpuTempFormatted : "48°C") + " • " + (System ? System.gpuUsage : 34) + "% utilization"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                color: TitanTheme.textMid
                elide: Text.ElideRight
            }
        }
    }
}
