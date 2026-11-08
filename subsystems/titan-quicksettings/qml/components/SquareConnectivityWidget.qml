import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * SquareConnectivityWidget — Super-Round Apple-style Connectivity Hub.
 *
 * Dimensions: 172x168 pebble card with 28px corner radius.
 * Features:
 * - 3 connectivity rows: Wi-Fi, Bluetooth, TitanDrop
 * - 100% circular 30px icon badges (radius: 15px) with active blue/accent glow
 * - Super-round row hover highlights (radius: 16px)
 * - Flyout chevrons for network & device selection
 */
Rectangle {
    id: connRoot
    Layout.fillWidth: true
    Layout.preferredHeight: 168
    radius: TitanTheme.radiusBento // 28px super-round
    color: TitanTheme.bgOneUICard
    border.color: TitanTheme.borderGlass
    border.width: 1
    clip: true

    signal openWifiRequested()
    signal openBluetoothRequested()

    gradient: Gradient {
        GradientStop {
            position: 0.0
            color: TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.65)
        }
        GradientStop {
            position: 1.0
            color: TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(1, 1, 1, 0.40)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 3

        // ── 1. Wi-Fi Row ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 16
            color: wifiMa.pressed ? TitanTheme.bgPressed : (wifiMa.containsMouse ? TitanTheme.bgHover : "transparent")
            Behavior on color { ColorAnimation { duration: 110 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 8
                spacing: 8

                // 30px 100% Circular Badge
                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: 15
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
                        font.pixelSize: 13
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
                    if (mouse.x > parent.width - 28) {
                        connRoot.openWifiRequested();
                    } else if (typeof networkCtrl !== "undefined" && networkCtrl) {
                        networkCtrl.wifiEnabled = !networkCtrl.wifiEnabled;
                    }
                }
            }
        }

        // ── 2. Bluetooth Row ────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 16
            color: btMa.pressed ? TitanTheme.bgPressed : (btMa.containsMouse ? TitanTheme.bgHover : "transparent")
            Behavior on color { ColorAnimation { duration: 110 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 8
                spacing: 8

                // 30px 100% Circular Badge
                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: 15
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
                        font.pixelSize: 13
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
                    if (mouse.x > parent.width - 28) {
                        connRoot.openBluetoothRequested();
                    } else if (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl) {
                        bluetoothCtrl.bluetoothEnabled = !bluetoothCtrl.bluetoothEnabled;
                    }
                }
            }
        }

        // ── 3. TitanDrop Row ────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 16
            color: dropMa.pressed ? TitanTheme.bgPressed : (dropMa.containsMouse ? TitanTheme.bgHover : "transparent")
            Behavior on color { ColorAnimation { duration: 110 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 8
                spacing: 8

                // 30px 100% Circular Badge
                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: 15
                    color: Qt.rgba(1, 1, 1, 0.12)
                    border.color: Qt.rgba(255, 255, 255, 0.16)
                    border.width: 1

                    scale: dropMa.pressed ? 0.90 : 1.0
                    Behavior on scale { NumberAnimation { duration: 110 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf1e0" // share-alt
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 12
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
}
