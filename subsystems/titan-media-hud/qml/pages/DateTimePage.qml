import QtQuick
import QtQuick.Layouts
import ArchTitan.Media 1.0
import ArchTitan.TitanUI

/**
 * DateTimePage — System Date, Time & Contextual Day Status
 * Displays day, full date, live clock, and ArchTitan contextual greeting.
 */
Item {
    id: dateTimePageRoot
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
            color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.09)
            border.color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.25)
            border.width: 1.5

            Text {
                anchors.centerIn: parent
                text: "📅"
                font.pixelSize: 22
                color: TitanTheme.success
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: parent.radius + 3
                color: "transparent"
                border.color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.19)
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
                    color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.13)
                    border.color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.25)
                    border.width: 1

                    Text {
                        id: tagText
                        anchors.centerIn: parent
                        text: "DATE & TIME"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        font.letterSpacing: 0.8
                        color: TitanTheme.success
                    }
                }

                Text {
                    text: System ? System.timeFormatted : "21:55"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                }

                Text {
                    text: "• " + (System ? System.dateFormatted : "Sunday, 30 August 2024")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: TitanTheme.textHigh
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.fillWidth: true
                text: System ? System.greetingText : "Have a productive day! ☀️"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                color: TitanTheme.textMid
                elide: Text.ElideRight
            }
        }
    }
}
