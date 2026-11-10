import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * UnifiedConnectivityModule — ArchTitan macOS-style Connectivity Bento Card.
 *
 * Implements the approved ArchTitan bento card with:
 * - Header: "Connectivity"
 * - 3 Squircle Buttons: Wi-Fi, Bluetooth, TitanDrop
 * - Top-right glowing Titan Orange status dots
 * - Integrated in-place edit affordances (Drag & Drop + Corner Resize handle)
 */
Rectangle {
    id: connRoot
    Layout.fillWidth: true
    implicitHeight: 112
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                  ? TitanTheme.accent
                  : (connMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)
    border.width: 1

    property bool isExpanded: false
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
                    return (ssid && ssid.length > 0) ? ssid : "Active";
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

            // 1. Wi-Fi Button
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: wifiBtnMa.pressed ? TitanTheme.bgPressed : (wifiBtnMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgInset)
                border.color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                              ? Qt.rgba(1.0, 0.42, 0.0, 0.35)
                              : TitanTheme.borderHairline
                border.width: 1

                // Active Orange Status Dot (Top-Right)
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
                        color: Qt.rgba(1.0, 0.42, 0.0, 0.30)
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
                        font.pixelSize: 16
                        color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                               ? TitanTheme.textPrimary
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
                }

                MouseArea {
                    id: wifiBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            connRoot.openWifiRequested();
                        } else {
                            if (typeof networkCtrl !== "undefined" && networkCtrl)
                                networkCtrl.toggleWifi();
                        }
                    }
                    onDoubleClicked: connRoot.openWifiRequested()
                }
            }

            // 2. Bluetooth Button
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: btBtnMa.pressed ? TitanTheme.bgPressed : (btBtnMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgInset)
                border.color: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered)
                              ? Qt.rgba(1.0, 0.42, 0.0, 0.35)
                              : TitanTheme.borderHairline
                border.width: 1

                // Active Orange Status Dot (Top-Right)
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
                        color: Qt.rgba(1.0, 0.42, 0.0, 0.30)
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
                        font.pixelSize: 16
                        color: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered)
                               ? TitanTheme.textPrimary
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

            // 3. TitanDrop Button
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: dropBtnMa.pressed ? TitanTheme.bgPressed : (dropBtnMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgInset)
                border.color: titanDropActive ? Qt.rgba(1.0, 0.42, 0.0, 0.35) : TitanTheme.borderHairline
                border.width: 1

                property bool titanDropActive: true

                // Active Orange Status Dot (Top-Right)
                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 7
                    anchors.rightMargin: 7
                    color: parent.titanDropActive ? TitanTheme.accent : "transparent"

                    Rectangle {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        radius: 5
                        color: Qt.rgba(1.0, 0.42, 0.0, 0.30)
                        z: -1
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf0ee" // cloud-upload / air-share
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 16
                        color: parent.parent.titanDropActive ? TitanTheme.textPrimary : TitanTheme.textMuted
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "TitanDrop"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: parent.parent.titanDropActive ? TitanTheme.textPrimary : TitanTheme.textSecondary
                    }
                }

                MouseArea {
                    id: dropBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        parent.titanDropActive = !parent.titanDropActive;
                    }
                }
            }
        }
    }

    // ── In-Place Corner Resize Handle ───────────────────────────────────────
    Rectangle {
        id: resizeHandle
        width: 18
        height: 18
        radius: 4
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 3
        color: resizeMa.containsMouse ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.12)
        visible: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
        z: 10

        Text {
            anchors.centerIn: parent
            text: "⤡"
            font.pixelSize: 12
            color: resizeMa.containsMouse ? "#0D1017" : TitanTheme.accent
        }

        MouseArea {
            id: resizeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            onClicked: {
                if (typeof systemCtrl !== "undefined" && systemCtrl)
                    systemCtrl.toggleWidgetSize("connectivity");
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
