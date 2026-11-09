import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * SquareConnectivityWidget — 3 Separated Super-Round Connectivity Cards.
 *
 * Each connectivity control (Wi-Fi, Bluetooth, TitanDrop) is an independent,
 * dedicated pebble card with its own border, frosted background, and hover dynamics.
 */
ColumnLayout {
    id: connRoot
    Layout.fillWidth: true
    Layout.preferredHeight: 168
    spacing: 8

    signal openWifiRequested()
    signal openBluetoothRequested()

    // ── 1. Separated Wi-Fi Card ─────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 18 // Super-round pebble card
        color: wifiMa.pressed ? TitanTheme.bgPressed : (wifiMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUICard)
        border.color: wifiMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass
        border.width: 1
        clip: true

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 10

            // 32px 100% Circular Badge
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                       ? TitanTheme.accent
                       : Qt.rgba(1, 1, 1, 0.12)
                border.color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                              ? TitanTheme.borderActive
                              : Qt.rgba(255, 255, 255, 0.16)
                border.width: 1

                scale: wifiMa.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: 110 } }
                Behavior on color { ColorAnimation { duration: 140 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf1eb" // wifi
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 14
                    color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                           ? "#0F141C"
                           : TitanTheme.textSecondary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Wi-Fi"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: TitanTheme.textPrimary
                }

                Text {
                    text: (typeof networkCtrl !== "undefined" && networkCtrl)
                          ? (networkCtrl.activeSsid ? networkCtrl.activeSsid : (networkCtrl.wifiEnabled ? "Enabled" : "Off"))
                          : "Connected"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: TitanTheme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Text {
                text: "\uf054" // chevron right
                font.family: TitanTheme.monoFamily
                font.pixelSize: 8
                color: TitanTheme.textSubtle
            }
        }

        MouseArea {
            id: wifiMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (mouse.x < 46) {
                    if (typeof networkCtrl !== "undefined" && networkCtrl) {
                        networkCtrl.wifiEnabled = !networkCtrl.wifiEnabled;
                    }
                } else {
                    connRoot.openWifiRequested();
                }
            }
        }
    }

    // ── 2. Separated Bluetooth Card ─────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 18 // Super-round pebble card
        color: btMa.pressed ? TitanTheme.bgPressed : (btMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUICard)
        border.color: btMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass
        border.width: 1
        clip: true

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 10

            // 32px 100% Circular Badge
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.bluetoothEnabled)
                       ? TitanTheme.accent
                       : Qt.rgba(1, 1, 1, 0.12)
                border.color: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.bluetoothEnabled)
                              ? TitanTheme.borderActive
                              : Qt.rgba(255, 255, 255, 0.16)
                border.width: 1

                scale: btMa.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: 110 } }
                Behavior on color { ColorAnimation { duration: 140 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf294" // bluetooth
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 14
                    color: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.bluetoothEnabled)
                           ? "#0F141C"
                           : TitanTheme.textSecondary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Bluetooth"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: TitanTheme.textPrimary
                }

                Text {
                    text: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl)
                          ? (bluetoothCtrl.connectedDeviceName ? bluetoothCtrl.connectedDeviceName : (bluetoothCtrl.bluetoothEnabled ? "On" : "Off"))
                          : "Off"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: TitanTheme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Text {
                text: "\uf054" // chevron right
                font.family: TitanTheme.monoFamily
                font.pixelSize: 8
                color: TitanTheme.textSubtle
            }
        }

        MouseArea {
            id: btMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (mouse.x > parent.width - 32) {
                    connRoot.openBluetoothRequested();
                } else if (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl) {
                    bluetoothCtrl.bluetoothEnabled = !bluetoothCtrl.bluetoothEnabled;
                }
            }
        }
    }

    // ── 3. Separated TitanDrop Card ─────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 18 // Super-round pebble card
        color: dropMa.pressed ? TitanTheme.bgPressed : (dropMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUICard)
        border.color: dropMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass
        border.width: 1
        clip: true

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 10

            // 32px 100% Circular Badge
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: Qt.rgba(1, 1, 1, 0.12)
                border.color: Qt.rgba(255, 255, 255, 0.16)
                border.width: 1

                scale: dropMa.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: 110 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf1e0" // share-alt
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 13
                    color: TitanTheme.textSecondary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "TitanDrop"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: TitanTheme.textPrimary
                }

                Text {
                    text: "Contacts Only"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: TitanTheme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        MouseArea {
            id: dropMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }
}
