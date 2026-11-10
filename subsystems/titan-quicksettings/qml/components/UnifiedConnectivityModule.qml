import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * UnifiedConnectivityModule — ArchTitan macOS-style Connectivity Bento Card.
 *
 * Implements the ArchTitan bento card with:
 * - Header: "Connectivity" + live SSID badge
 * - 3 Squircle Buttons: Wi-Fi, Bluetooth, Titan Share
 * - Clean squircle buttons (no power icons)
 * - Left click on Wi-Fi directly opens Wi-Fi Networks Picker
 * - Sapphire Cyan accents
 */
Rectangle {
    id: connRoot
    Layout.fillWidth: true
    implicitHeight: 140
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                  ? TitanTheme.accent
                  : (connMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)
    border.width: 1

    signal openWifiRequested()
    signal openBluetoothRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // ── Card Header ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Connectivity"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: TitanTheme.textPrimary
            }

            Item { Layout.fillWidth: true }

            // Wi-Fi SSID / Network status badge
            Text {
                text: {
                    if (typeof networkCtrl === "undefined" || !networkCtrl) return "Offline";
                    if (!networkCtrl.wifiEnabled) return "Disabled";
                    var ssid = networkCtrl.activeSsid;
                    return (ssid && ssid.length > 0) ? ssid : "Connected";
                }
                font.family: TitanTheme.fontFamily
                font.pixelSize: 9
                font.weight: Font.Medium
                color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                       ? TitanTheme.accent
                       : TitanTheme.textMuted
                elide: Text.ElideRight
                Layout.maximumWidth: 100
            }
        }

        // ── 3 Squircle Buttons Row ──────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // 1. Wi-Fi Button (Clean squircle - opens Network Picker)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: wifiBtnMa.pressed ? TitanTheme.bgPressed : (wifiBtnMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgInset)
                border.color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                              ? Qt.rgba(0.04, 0.52, 1.0, 0.45)
                              : TitanTheme.borderHairline
                border.width: 1

                // Active Sapphire Status Dot (Top-Right)
                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 7
                    anchors.rightMargin: 7
                    color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                           ? TitanTheme.accent
                           : "transparent"
                    visible: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)

                    Rectangle {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        radius: 5
                        color: TitanTheme.accentGlow
                        z: -1
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf1eb" // wifi
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 18
                        color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                               ? TitanTheme.accent
                               : TitanTheme.textMuted
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Wi-Fi"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                               ? TitanTheme.textPrimary
                               : TitanTheme.textSecondary
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            if (typeof networkCtrl === "undefined" || !networkCtrl) return "Off";
                            if (!networkCtrl.wifiEnabled) return "Disabled";
                            var ssid = networkCtrl.activeSsid;
                            return (ssid && ssid.length > 0) ? ssid : "Select Network";
                        }
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 8
                        color: TitanTheme.textMuted
                        elide: Text.ElideRight
                        Layout.maximumWidth: parent.width - 10
                    }
                }

                MouseArea {
                    id: wifiBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    // Clicking Wi-Fi button opens the network selection list!
                    onClicked: connRoot.openWifiRequested()
                }
            }

            // 2. Bluetooth Button
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: btBtnMa.pressed ? TitanTheme.bgPressed : (btBtnMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgInset)
                border.color: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered)
                              ? Qt.rgba(0.04, 0.52, 1.0, 0.45)
                              : TitanTheme.borderHairline
                border.width: 1

                // Active Sapphire Status Dot (Top-Right)
                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 7
                    anchors.rightMargin: 7
                    color: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered)
                           ? TitanTheme.accent
                           : "transparent"
                    visible: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered)

                    Rectangle {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        radius: 5
                        color: TitanTheme.accentGlow
                        z: -1
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf293" // bluetooth
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 18
                        color: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered)
                               ? TitanTheme.accent
                               : TitanTheme.textMuted
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Bluetooth"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered)
                               ? TitanTheme.textPrimary
                               : TitanTheme.textSecondary
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered) ? "Enabled" : "Off"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 8
                        color: TitanTheme.textMuted
                    }
                }

                MouseArea {
                    id: btBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl)
                            bluetoothCtrl.toggleBluetooth();
                    }
                }
            }

            // 3. Titan Share Button (formerly TitanDrop)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: dropBtnMa.pressed ? TitanTheme.bgPressed : (dropBtnMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgInset)
                border.color: titanShareActive ? Qt.rgba(0.04, 0.52, 1.0, 0.45) : TitanTheme.borderHairline
                border.width: 1

                property bool titanShareActive: true

                // Active Sapphire Status Dot (Top-Right)
                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 7
                    anchors.rightMargin: 7
                    color: parent.titanShareActive ? TitanTheme.accent : "transparent"

                    Rectangle {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        radius: 5
                        color: TitanTheme.accentGlow
                        z: -1
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf1e0" // share-nodes / air-share
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 18
                        color: parent.parent.titanShareActive ? TitanTheme.accent : TitanTheme.textMuted
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Titan Share"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: parent.parent.titanShareActive ? TitanTheme.textPrimary : TitanTheme.textSecondary
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: parent.parent.titanShareActive ? "Ready" : "Off"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 8
                        color: TitanTheme.textMuted
                    }
                }

                MouseArea {
                    id: dropBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        parent.titanShareActive = !parent.titanShareActive;
                    }
                }
            }
        }
    }

    MouseArea {
        id: connMa
        anchors.fill: parent
        hoverEnabled: true
        z: -1
    }
}
