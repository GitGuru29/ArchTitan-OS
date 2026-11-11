import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * UnifiedConnectivityModule — macOS Control Center 3-Row Connectivity Stack.
 *
 * Implements the authentic macOS 2x2 Connectivity Bento Card:
 * - Row 1: Wi-Fi (Circular power button on left, SSID + '>' picker trigger on right)
 * - Row 2: Bluetooth (Circular power button on left, status + '>' trigger on right)
 * - Row 3: Titan Share (Circular cyan-blue button on left, mode + '>' trigger on right)
 */
Rectangle {
    id: connRoot
    Layout.fillWidth: true
    implicitHeight: 148
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                  ? TitanTheme.accent
                  : TitanTheme.borderHairline
    border.width: 1

    signal openWifiRequested()
    signal openBluetoothRequested()

    property int shareModeIndex: 0 // 0: "Everyone", 1: "Contacts Only", 2: "Off"
    readonly property var shareModes: ["Everyone", "Contacts Only", "Off"]
    readonly property bool shareActive: shareModeIndex < 2

    readonly property bool wifiOn: (typeof networkCtrl !== "undefined" && networkCtrl) ? networkCtrl.wifiEnabled : true
    readonly property string wifiSubtitle: {
        if (typeof networkCtrl === "undefined" || !networkCtrl) return "ArchTitan-5G";
        if (!networkCtrl.wifiEnabled) return "Off";
        var ssid = networkCtrl.activeSsid;
        return (ssid && ssid.length > 0) ? ssid : "ArchTitan-5G";
    }

    readonly property bool btOn: (typeof btCtrl !== "undefined" && btCtrl) ? btCtrl.bluetoothEnabled : true
    readonly property string btSubtitle: {
        if (typeof btCtrl === "undefined" || !btCtrl) return "Connected";
        if (!btCtrl.bluetoothEnabled) return "Off";
        var dev = btCtrl.connectedDeviceName;
        return (dev && dev.length > 0) ? dev : "Connected";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 6

        // ═════════════════════════════════════════════════════════════════════
        //  ROW 1: Wi-Fi (Left circle = power toggle, Right row = network list)
        // ═════════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: wifiRowMa.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

            RowLayout {
                anchors.fill: parent
                spacing: 10

                // Circular Icon Toggle Button
                Rectangle {
                    id: wifiCircle
                    width: 32
                    height: 32
                    radius: 16
                    color: connRoot.wifiOn ? "#0A84FF" : Qt.rgba(1, 1, 1, 0.14)
                    scale: wifiCircleMa.pressed ? 0.90 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    // Subtle inner specular rim
                    border.color: connRoot.wifiOn ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "\uf1eb" // wifi
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 13
                        color: connRoot.wifiOn ? "#FFFFFF" : TitanTheme.textMuted
                    }

                    MouseArea {
                        id: wifiCircleMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) return;
                            if (typeof networkCtrl !== "undefined" && networkCtrl)
                                networkCtrl.toggleWifi();
                        }
                    }
                }

                // Title + Active SSID Subtitle + Chevron
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.fill: parent
                        spacing: 4

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: "Wi-Fi"
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: TitanTheme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: connRoot.wifiSubtitle
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 10
                                color: connRoot.wifiOn ? TitanTheme.textSecondary : TitanTheme.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            text: "\uf054" // chevron-right
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 9
                            color: wifiRowMa.containsMouse ? TitanTheme.textPrimary : TitanTheme.textMuted
                        }
                    }

                    MouseArea {
                        id: wifiRowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) return;
                            connRoot.openWifiRequested();
                        }
                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════════════
        //  ROW 2: Bluetooth (Left circle = power toggle, Right row = devices)
        // ═════════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: btRowMa.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

            RowLayout {
                anchors.fill: parent
                spacing: 10

                // Circular Icon Toggle Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: connRoot.btOn ? "#0A84FF" : Qt.rgba(1, 1, 1, 0.14)
                    scale: btCircleMa.pressed ? 0.90 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    border.color: connRoot.btOn ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "\uf293" // bluetooth
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 13
                        color: connRoot.btOn ? "#FFFFFF" : TitanTheme.textMuted
                    }

                    MouseArea {
                        id: btCircleMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) return;
                            if (typeof btCtrl !== "undefined" && btCtrl)
                                btCtrl.toggleBluetooth();
                        }
                    }
                }

                // Title + Status Subtitle + Chevron
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.fill: parent
                        spacing: 4

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: "Bluetooth"
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: TitanTheme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: connRoot.btSubtitle
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 10
                                color: connRoot.btOn ? TitanTheme.textSecondary : TitanTheme.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            text: "\uf054" // chevron-right
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 9
                            color: btRowMa.containsMouse ? TitanTheme.textPrimary : TitanTheme.textMuted
                        }
                    }

                    MouseArea {
                        id: btRowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) return;
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.openBluetoothSettings();
                        }
                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════════════
        //  ROW 3: Titan Share (Cyan-Blue AirDrop-style local file sharing)
        // ═════════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: shareRowMa.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

            RowLayout {
                anchors.fill: parent
                spacing: 10

                // Circular Icon Toggle Button (Electric Cyan-Blue like mockup)
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: connRoot.shareActive ? "#00C2FF" : Qt.rgba(1, 1, 1, 0.14)
                    scale: shareCircleMa.pressed ? 0.90 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    border.color: connRoot.shareActive ? Qt.rgba(1, 1, 1, 0.32) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "\uf1e0" // share-alt
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 13
                        color: connRoot.shareActive ? "#FFFFFF" : TitanTheme.textMuted
                    }

                    MouseArea {
                        id: shareCircleMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) return;
                            connRoot.shareModeIndex = (connRoot.shareModeIndex + 1) % 3;
                        }
                    }
                }

                // Title + Mode Subtitle + Chevron
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.fill: parent
                        spacing: 4

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: "Titan Share"
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: TitanTheme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: connRoot.shareModes[connRoot.shareModeIndex]
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 10
                                color: connRoot.shareActive ? TitanTheme.textSecondary : TitanTheme.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            text: "\uf054" // chevron-right
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 9
                            color: shareRowMa.containsMouse ? TitanTheme.textPrimary : TitanTheme.textMuted
                        }
                    }

                    MouseArea {
                        id: shareRowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) return;
                            connRoot.shareModeIndex = (connRoot.shareModeIndex + 1) % 3;
                        }
                    }
                }
            }
        }
    }
}
