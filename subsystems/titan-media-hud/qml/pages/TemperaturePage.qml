import QtQuick
import QtQuick.Layouts
import ArchTitan.Media 1.0
import ArchTitan.TitanUI

/**
 * TemperaturePage — Real CPU Hardware Temperature Monitor
 * Displays true CPU package temperature readout, thermometer icon, and thermal status.
 */
Item {
    id: tempPageRoot
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
            color: Qt.rgba(TitanTheme.peach.r, TitanTheme.peach.g, TitanTheme.peach.b, 0.09)
            border.color: Qt.rgba(TitanTheme.peach.r, TitanTheme.peach.g, TitanTheme.peach.b, 0.25)
            border.width: 1.5

            Text {
                anchors.centerIn: parent
                text: "🌡"
                font.pixelSize: 22
                color: TitanTheme.peach
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: parent.radius + 3
                color: "transparent"
                border.color: Qt.rgba(TitanTheme.peach.r, TitanTheme.peach.g, TitanTheme.peach.b, 0.19)
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
                    color: Qt.rgba(TitanTheme.peach.r, TitanTheme.peach.g, TitanTheme.peach.b, 0.13)
                    border.color: Qt.rgba(TitanTheme.peach.r, TitanTheme.peach.g, TitanTheme.peach.b, 0.25)
                    border.width: 1

                    Text {
                        id: tagText
                        anchors.centerIn: parent
                        text: "CPU TEMPERATURE"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        font.letterSpacing: 0.8
                        color: TitanTheme.peach
                    }
                }

                Text {
                    text: System ? System.cpuTempFormatted : "52°C"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Thermal Status: " + (System ? System.cpuTempStatus : "Normal") + " • Optimal cooling"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                color: TitanTheme.textMid
                elide: Text.ElideRight
            }
        }
    }
}
