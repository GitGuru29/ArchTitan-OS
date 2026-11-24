import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import ArchTitan.TitanUI

/**
 * BreakOverlay — compact top-center break countdown pill.
 * Uses ArchTitan.TitanUI tokens exclusively (zero hardcoded colours).
 */
Window {
    id: root
    title: "titan-focus-break"
    width: 310
    height: 64

    flags: Qt.FramelessWindowHint
    color: "transparent"
    visible: false

    Rectangle {
        anchors.fill: parent
        radius: TitanTheme.radiusWindow
        color: TitanTheme.glass
        border.width: 1
        border.color: TitanTheme.success

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: TitanTheme.space4
            anchors.rightMargin: TitanTheme.space3
            spacing: TitanTheme.space3

            Item {
                width: 36; height: 36

                TitanArcItem {
                    anchors.fill: parent
                    lineWidth: 4
                    startAngle: -90
                    sweepAngle: Math.max(8, focusCtrl.breakProgress * 360)
                    color: TitanTheme.success
                    trackColor: TitanTheme.surface1
                    showTrack: true
                    roundCaps: true
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰅶"
                    color: TitanTheme.success
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 13
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Break · " + focusCtrl.breakRemainingFormatted
                    color: TitanTheme.textHigh
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: TitanTheme.sizeBody
                    font.weight: TitanTheme.weightBold
                }
                Text {
                    text: "Rest your eyes and stretch"
                    color: TitanTheme.textLow
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                }
            }

            TitanButton {
                implicitHeight: 28
                text: "Skip"
                variant: "ghost"
                onClicked: focusCtrl.endBreak()
            }
        }
    }
}
