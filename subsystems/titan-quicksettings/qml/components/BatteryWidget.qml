import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * BatteryWidget — Power Management & Energy Profile Bento.
 *
 * Displays live battery status, charging state, and 1-click power profile toggling.
 */
Rectangle {
    id: batRoot
    Layout.fillWidth: true
    implicitHeight: batCol.implicitHeight + 22
    radius: TitanTheme.radiusCard // 24px super-round
    color: TitanTheme.bgOneUICard
    border.color: TitanTheme.borderGlass
    border.width: 1
    clip: true

    readonly property int batPercent: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.batteryPercent : 94
    readonly property bool isCharging: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.batteryCharging : false
    readonly property bool hasBat: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.hasBattery : true

    ColumnLayout {
        id: batCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Battery Icon Medallion
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: batRoot.isCharging ? Qt.rgba(0.65, 0.89, 0.63, 0.20) : Qt.rgba(1, 1, 1, 0.08)
                border.color: batRoot.isCharging ? TitanTheme.green : TitanTheme.borderGlass
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: batRoot.isCharging ? "\uf0e7" : (batRoot.batPercent > 20 ? "\uf240" : "\uf244")
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 13
                    color: batRoot.isCharging ? TitanTheme.green : (batRoot.batPercent > 20 ? TitanTheme.textPrimary : TitanTheme.red)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: batRoot.hasBat ? "Battery" : "Power Source"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: TitanTheme.textPrimary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: batRoot.hasBat ? (batRoot.batPercent + "%" + (batRoot.isCharging ? " · Charging" : "")) : "AC Connected"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: batRoot.isCharging ? TitanTheme.green : TitanTheme.textPrimary
                    }
                }

                // Battery Level Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 8
                    radius: 4
                    color: TitanTheme.bgInset
                    clip: true
                    visible: batRoot.hasBat

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * (batRoot.batPercent / 100.0)
                        radius: 4
                        color: batRoot.isCharging ? TitanTheme.green : (batRoot.batPercent > 20 ? TitanTheme.accent : TitanTheme.red)

                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                    }
                }
            }
        }
    }
}
