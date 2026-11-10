import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * UnifiedConnectivityModule — macOS-style Unified Connectivity Bento Card.
 *
 * Houses Wi-Fi, Bluetooth, and TitanDrop in a single dark titanium card
 * with active orange indicator badges and smooth inline expansion hooks.
 */
Rectangle {
    id: connRoot
    Layout.fillWidth: true
    implicitHeight: connCol.implicitHeight + 16
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: TitanTheme.borderHairline
    border.width: 1

    signal openWifiRequested()
    signal openBluetoothRequested()

    ColumnLayout {
        id: connCol
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        // ── 1. Wi-Fi Row ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 42
            radius: TitanTheme.radiusTile
            color: wifiMa.pressed ? TitanTheme.bgPressed : (wifiMa.containsMouse ? TitanTheme.bgHover : "transparent")

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10

                // 28px Medallion
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                           ? TitanTheme.accent
                           : Qt.rgba(1, 1, 1, 0.08)
                    border.color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                                  ? TitanTheme.borderActive
                                  : TitanTheme.borderHairline
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "\uf1eb" // wifi
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 12
                        color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                               ? "#0D1017"
                               : TitanTheme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof networkCtrl !== "undefined" && networkCtrl)
                                networkCtrl.toggleWifi();
                        }
                    }
                }

                // Labels
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "Wi-Fi"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: TitanTheme.textPrimary
                    }

                    Text {
                        text: {
                            if (typeof networkCtrl === "undefined" || !networkCtrl) return "Off";
                            if (!networkCtrl.wifiEnabled) return "Disabled";
                            var ssid = networkCtrl.activeSsid;
                            return (ssid && ssid.length > 0) ? ssid : "Connected";
                        }
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 9
                        color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                               ? TitanTheme.textSecondary
                               : TitanTheme.textMuted
                        elide: Text.ElideRight
                        Layout.maximumWidth: 90
                    }
                }

                // Chevron
                Text {
                    text: "\uf054"
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 9
                    color: TitanTheme.textMuted
                }
            }

            MouseArea {
                id: wifiMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: connRoot.openWifiRequested()
            }
        }

        // ── 2. Bluetooth Row ────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 42
            radius: TitanTheme.radiusTile
            color: btMa.pressed ? TitanTheme.bgPressed : (btMa.containsMouse ? TitanTheme.bgHover : "transparent")

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10

                // 28px Medallion
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered)
                           ? TitanTheme.accent
                           : Qt.rgba(1, 1, 1, 0.08)
                    border.color: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered)
                                  ? TitanTheme.borderActive
                                  : TitanTheme.borderHairline
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "\uf294" // bluetooth
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 12
                        color: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered)
                               ? "#0D1017"
                               : TitanTheme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl)
                                bluetoothCtrl.togglePower();
                        }
                    }
                }

                // Labels
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "Bluetooth"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: TitanTheme.textPrimary
                    }

                    Text {
                        text: {
                            if (typeof bluetoothCtrl === "undefined" || !bluetoothCtrl) return "Off";
                            if (!bluetoothCtrl.powered) return "Off";
                            var dev = bluetoothCtrl.connectedDeviceName;
                            return (dev && dev.length > 0) ? dev : "On";
                        }
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 9
                        color: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered)
                               ? TitanTheme.textSecondary
                               : TitanTheme.textMuted
                        elide: Text.ElideRight
                        Layout.maximumWidth: 90
                    }
                }

                // Chevron
                Text {
                    text: "\uf054"
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 9
                    color: TitanTheme.textMuted
                }
            }

            MouseArea {
                id: btMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: connRoot.openBluetoothRequested()
            }
        }

        // ── 3. TitanDrop Row ────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 42
            radius: TitanTheme.radiusTile
            color: dropMa.pressed ? TitanTheme.bgPressed : (dropMa.containsMouse ? TitanTheme.bgHover : "transparent")

            property int dropState: 1 // 0: Off, 1: Contacts, 2: Everyone

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10

                // 28px Medallion
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: parent.parent.dropState > 0 ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.08)
                    border.color: parent.parent.dropState > 0 ? TitanTheme.borderActive : TitanTheme.borderHairline
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "\uf1e0" // share-alt
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 11
                        color: parent.parent.parent.dropState > 0 ? "#0D1017" : TitanTheme.textMuted
                    }
                }

                // Labels
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "TitanDrop"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: TitanTheme.textPrimary
                    }

                    Text {
                        text: parent.parent.parent.dropState === 2 ? "Everyone" : (parent.parent.parent.dropState === 1 ? "Ready" : "Off")
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 9
                        color: parent.parent.parent.dropState > 0 ? TitanTheme.textSecondary : TitanTheme.textMuted
                    }
                }

                // Chevron
                Text {
                    text: "\uf054"
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 9
                    color: TitanTheme.textMuted
                }
            }

            MouseArea {
                id: dropMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    parent.dropState = (parent.dropState + 1) % 3;
                }
            }
        }
    }
}

