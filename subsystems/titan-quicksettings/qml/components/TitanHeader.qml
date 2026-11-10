import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanHeader — ArchTitan Control Center Top Navigation & Status Header.
 *
 * Displays "TITAN CONTROL CENTER" with refined typography, system hub tagline,
 * and quick utility buttons (Settings, Power Menu, and Customize Editor).
 */
Rectangle {
    id: headerRoot
    Layout.fillWidth: true
    implicitHeight: 46
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: TitanTheme.borderHairline
    border.width: 1

    signal editRequested()
    signal settingsRequested()
    signal powerRequested()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 12
        spacing: 10

        // Titan Flame Brand Icon Medallion
        Rectangle {
            width: 26
            height: 26
            radius: 13
            color: TitanTheme.accentGlow
            border.color: TitanTheme.borderActive
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "\uf0e7" // bolt / power
                font.family: TitanTheme.monoFamily
                font.pixelSize: 11
                color: TitanTheme.accent
            }
        }

        // Title & System Subtitle
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: "TITAN CONTROL CENTER"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 0.8
                color: TitanTheme.textPrimary
            }

            Text {
                text: "ARCHTITAN OS · SYSTEM HUB"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 0.5
                color: TitanTheme.textMuted
            }
        }

        // Action Buttons Row
        RowLayout {
            spacing: 6

            // 1. Customize / Edit Mode Button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: editMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
                border.color: editMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline
                border.width: 1

                scale: editMa.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 110 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf044" // edit
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 11
                    color: editMa.containsMouse ? TitanTheme.accent : TitanTheme.textMuted
                }

                MouseArea {
                    id: editMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: headerRoot.editRequested()
                }
            }

            // 2. Settings Button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: settMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
                border.color: settMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline
                border.width: 1

                scale: settMa.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 110 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf013" // cog / settings
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 11
                    color: settMa.containsMouse ? TitanTheme.accent : TitanTheme.textMuted
                }

                MouseArea {
                    id: settMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: headerRoot.settingsRequested()
                }
            }

            // 3. Power Menu Button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: powerMa.containsMouse ? Qt.rgba(0.94, 0.27, 0.27, 0.20) : TitanTheme.bgOneUIPill
                border.color: powerMa.containsMouse ? TitanTheme.red : TitanTheme.borderHairline
                border.width: 1

                scale: powerMa.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 110 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf011" // power-off
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 11
                    color: powerMa.containsMouse ? TitanTheme.red : TitanTheme.textMuted
                }

                MouseArea {
                    id: powerMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: headerRoot.powerRequested()
                }
            }
        }
    }
}

