import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * QuickToggleGrid — Samsung One UI 9.0 Bento-Box Quick Settings cluster.
 *
 * Squircles, thick pill sliders, and circular action toggles with live
 * PipeWire, NetworkManager, BlueZ, and Backlight integration.
 */
ColumnLayout {
    id: bentoRoot
    Layout.fillWidth: true
    spacing: 12

    // ── 1. Top Connectivity Bento (Dual Squircles) ──────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        OneUIConnectivityTile {
            active: (typeof networkCtrl !== "undefined" && networkCtrl) ? networkCtrl.wifiEnabled : false
            iconGlyph: "\uf1eb"
            title: "Wi-Fi"
            subtitle: (typeof networkCtrl !== "undefined" && networkCtrl)
                      ? networkCtrl.ssid : "Disconnected"
            onClicked: {
                if (typeof networkCtrl !== "undefined" && networkCtrl)
                    networkCtrl.toggleWifi()
            }
        }

        OneUIConnectivityTile {
            active: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl) ? bluetoothCtrl.powered : false
            iconGlyph: "\uf294"
            title: "Bluetooth"
            subtitle: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl)
                      ? bluetoothCtrl.statusText : "Off"
            onClicked: {
                if (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl)
                    bluetoothCtrl.toggleBluetooth()
            }
        }
    }

    // ── 2. Thick Pill Sliders Bento (Brightness & Sound) ────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: sliderCol.implicitHeight + 20
        radius: TitanTheme.radiusBento
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1

        ColumnLayout {
            id: sliderCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Sound Volume Slider
            OneUISlider {
                iconGlyph: {
                    if (muted) return "\uf026";
                    if (value <= 30) return "\uf027";
                    return "\uf028";
                }
                from: 0
                to: 150
                value: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sinkVolume : 60
                muted: typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sinkMuted
                fillAccent: TitanTheme.accentBlue
                onChanged: (v) => {
                    if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.setVolume(v)
                }
            }

            // Display Brightness Slider
            OneUISlider {
                iconGlyph: "\uf185" // sun
                from: 0
                to: 100
                value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.brightness : 80
                fillAccent: TitanTheme.yellow
                onChanged: (v) => {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setBrightness(v)
                }
            }
        }
    }

    // ── 3. Circular Quick Action Toggles (4x2 Grid) ─────────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: gridCol.implicitHeight + 22
        radius: TitanTheme.radiusBento
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1

        ColumnLayout {
            id: gridCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // Row 1
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    height: 74
                    OneUICircleButton {
                        anchors.centerIn: parent
                        iconGlyph: "\uf186" // moon
                        label: "Dark mode"
                        active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.themeDark : true
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.themeDark = !systemCtrl.themeDark
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: 74
                    OneUICircleButton {
                        anchors.centerIn: parent
                        iconGlyph: "\uf06e" // eye comfort / night light
                        label: "Eye shield"
                        active: (typeof nightLightCtrl !== "undefined" && nightLightCtrl) ? nightLightCtrl.active : false
                        activeColor: TitanTheme.peach
                        onClicked: {
                            if (typeof nightLightCtrl !== "undefined" && nightLightCtrl)
                                nightLightCtrl.toggleNightLight()
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: 74
                    OneUICircleButton {
                        anchors.centerIn: parent
                        iconGlyph: "\uf0f4" // caffeine
                        label: "Awake"
                        active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.caffeineActive : false
                        activeColor: TitanTheme.yellow
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.caffeineActive = !systemCtrl.caffeineActive
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: 74
                    OneUICircleButton {
                        anchors.centerIn: parent
                        iconGlyph: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted) ? "\uf131" : "\uf130"
                        label: "Mic mute"
                        active: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sourceMuted : false
                        activeColor: TitanTheme.red
                        onClicked: {
                            if (typeof audioCtrl !== "undefined" && audioCtrl)
                                audioCtrl.toggleSourceMute()
                        }
                    }
                }
            }

            // Row 2
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    height: 74
                    OneUICircleButton {
                        anchors.centerIn: parent
                        iconGlyph: "\uf030" // camera
                        label: "Capture"
                        active: false
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.takeScreenshot()
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: 74
                    OneUICircleButton {
                        anchors.centerIn: parent
                        iconGlyph: "\uf1fb" // color picker
                        label: "Color pick"
                        active: false
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.pickColor()
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: 74
                    OneUICircleButton {
                        anchors.centerIn: parent
                        iconGlyph: "\uf11b" // game mode
                        label: "Game mode"
                        active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.gameModeActive : false
                        activeColor: TitanTheme.green
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.gameModeActive = !systemCtrl.gameModeActive
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: 74
                    OneUICircleButton {
                        anchors.centerIn: parent
                        iconGlyph: "\uf023" // VPN lock
                        label: "VPN"
                        active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.vpnActive : false
                        activeColor: TitanTheme.lavender
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.vpnActive = !systemCtrl.vpnActive
                        }
                    }
                }
            }
        }
    }

    // ── 4. Bottom Device & Media Control Pills ──────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            height: 44
            radius: 22
            color: medMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUICard
            border.color: TitanTheme.borderGlass
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    text: "\uf001" // music
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 13
                    color: TitanTheme.accentBlue
                }
                Text {
                    text: "Media Output"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: TitanTheme.textPrimary
                }
            }

            MouseArea {
                id: medMa
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                        systemCtrl.openMediaWidget()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 44
            radius: 22
            color: kbdMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUICard
            border.color: TitanTheme.borderGlass
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    text: "\uf11c" // keyboard
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 13
                    color: TitanTheme.textSecondary
                }
                Text {
                    text: "Virtual Input"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: TitanTheme.textPrimary
                }
            }

            MouseArea {
                id: kbdMa
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                        systemCtrl.toggleVirtualKeyboard()
                }
            }
        }
    }
}