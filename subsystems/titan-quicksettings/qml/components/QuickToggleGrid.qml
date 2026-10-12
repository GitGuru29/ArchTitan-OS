import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * QuickToggleGrid — Samsung One UI 9.0 Bento-Box Quick Settings cluster.
 *
 * Squircles, thick pill sliders, and circular action toggles matching the One UI 9.0 design.
 */
ColumnLayout {
    id: bentoRoot
    Layout.fillWidth: true
    spacing: 12

    // ── 1. Top Connectivity Bento (Wi-Fi & Bluetooth) ────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        OneUIConnectivityTile {
            active: (typeof networkCtrl !== "undefined" && networkCtrl) ? networkCtrl.wifiEnabled : false
            iconGlyph: "\uf1eb"
            title: "Wi-Fi"
            subtitle: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
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
            subtitle: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered)
                      ? bluetoothCtrl.statusText : "Off"
            onClicked: {
                if (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl)
                    bluetoothCtrl.toggleBluetooth()
            }
        }
    }

    // ── 2. Primary 4-Toggle Card (Dark mode, Eye shield, DND, Mic mute) ──────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: primaryCol.implicitHeight + 20
        radius: TitanTheme.radiusBento
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true

        RowLayout {
            id: primaryCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 0

            // Dark Mode
            Item {
                Layout.fillWidth: true
                height: 72
                OneUICircleButton {
                    anchors.centerIn: parent
                    iconGlyph: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.themeDark)
                               ? "\uf186" // moon
                               : "\uf185" // sun
                    label: "Dark mode"
                    statusText: active ? "On" : "Off"
                    active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.themeDark : true
                    onClicked: {
                        if (typeof systemCtrl !== "undefined" && systemCtrl)
                            systemCtrl.themeDark = !systemCtrl.themeDark
                    }
                }
            }

            // Eye Shield
            Item {
                Layout.fillWidth: true
                height: 72
                OneUICircleButton {
                    anchors.centerIn: parent
                    iconGlyph: "\uf06e" // eye
                    label: "Eye shield"
                    statusText: active ? "On" : "Off"
                    active: (typeof nightLightCtrl !== "undefined" && nightLightCtrl) ? nightLightCtrl.active : false
                    activeColor: TitanTheme.accentBlue
                    onClicked: {
                        if (typeof nightLightCtrl !== "undefined" && nightLightCtrl)
                            nightLightCtrl.toggleNightLight()
                    }
                }
            }

            // Do Not Disturb
            Item {
                Layout.fillWidth: true
                height: 72
                OneUICircleButton {
                    anchors.centerIn: parent
                    iconGlyph: "\uf05e" // ban / dnd
                    label: "Do not disturb"
                    statusText: active ? "On" : "Off"
                    active: (typeof notifServer !== "undefined" && notifServer) ? notifServer.dndActive : false
                    activeColor: TitanTheme.accentBlue
                    onClicked: {
                        if (typeof notifServer !== "undefined" && notifServer)
                            notifServer.toggleDnd()
                    }
                }
            }

            // Mic Mute
            Item {
                Layout.fillWidth: true
                height: 72
                OneUICircleButton {
                    anchors.centerIn: parent
                    iconGlyph: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted) ? "\uf131" : "\uf130"
                    label: "Mic mute"
                    statusText: active ? "On" : "Off"
                    active: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sourceMuted : false
                    activeColor: TitanTheme.red
                    onClicked: {
                        if (typeof audioCtrl !== "undefined" && audioCtrl)
                            audioCtrl.toggleSourceMute()
                    }
                }
            }
        }
    }

    // ── 3. Thick Pill Sliders Bento (Brightness & Volume) ────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: sliderCol.implicitHeight + 20
        radius: TitanTheme.radiusBento
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true

        ColumnLayout {
            id: sliderCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Display Brightness Slider
            OneUISlider {
                iconGlyph: "\uf185" // sun
                from: 0
                to: 100
                value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.brightness : 80
                fillAccent: TitanTheme.accentBlue
                onChanged: (v) => {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setBrightness(v)
                }
            }

            // Sound Volume Slider
            OneUISlider {
                iconGlyph: {
                    if (muted) return "\uf026";
                    if (value <= 30) return "\uf027";
                    return "\uf028";
                }
                from: 0
                to: 100
                value: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sinkVolume : 60
                muted: typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sinkMuted
                fillAccent: TitanTheme.accentBlue
                onChanged: (v) => {
                    if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.setVolume(v)
                }
            }
        }
    }

    // ── 4. Circular Quick Action Toggles (4x2 Grid) ─────────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: gridCol.implicitHeight + 22
        radius: TitanTheme.radiusBento
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true

        ColumnLayout {
            id: gridCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // Row 1: Capture, Color pick, Game mode, VPN
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    height: 68
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
                    height: 68
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
                    height: 68
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
                    height: 68
                    OneUICircleButton {
                        anchors.centerIn: parent
                        iconGlyph: "\uf0ea" // clipboard
                        label: "Clipboard"
                        active: false
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.openClipboard()
                        }
                    }
                }
            }

            // Row 2: Awake, Virtual input, Screen record, Airplane mode
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    height: 68
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
                    height: 68
                    OneUICircleButton {
                        anchors.centerIn: parent
                        iconGlyph: "\uf11c" // keyboard
                        label: "Virtual input"
                        active: false
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.toggleVirtualKeyboard()
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: 68
                    OneUICircleButton {
                        anchors.centerIn: parent
                        iconGlyph: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.screenRecordingActive)
                                   ? "\uf04d" // stop square
                                   : "\uf111" // record circle
                        label: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.screenRecordingActive)
                               ? "Recording"
                               : "Record"
                        active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.screenRecordingActive : false
                        activeColor: TitanTheme.red
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.toggleScreenRecording()
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: 68
                    OneUICircleButton {
                        anchors.centerIn: parent
                        iconGlyph: "\uf072" // airplane
                        label: "Airplane"
                        active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.airplaneMode : false
                        activeColor: TitanTheme.accentBlue
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.toggleAirplaneMode()
                        }
                    }
                }
            }
        }
    }

    // ── 5. Bottom Device & Media Control Tiles ──────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        height: 50
        radius: 20
        color: medMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true

        // Tactile Liquid Touch: spring bounce on hover and press
        scale: medMa.pressed ? 0.97 : (medMa.containsMouse ? 1.015 : 1.0)
        Behavior on scale {
            NumberAnimation { duration: 130; easing.type: Easing.OutQuad }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: TitanTheme.bgOneUIPill

                Text {
                    anchors.centerIn: parent
                    text: "\uf001" // music
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 13
                    color: TitanTheme.accentBlue
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Media output"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: TitanTheme.textPrimary
                }

                Text {
                    text: "No device connected"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    color: TitanTheme.textSubtle
                }
            }

            Text {
                text: "\uf054"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 10
                color: TitanTheme.textSubtle
            }
        }

        MouseArea {
            id: medMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (typeof systemCtrl !== "undefined" && systemCtrl)
                    systemCtrl.openMediaWidget()
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 50
        radius: 20
        color: devMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true

        // Tactile Liquid Touch: spring bounce on hover and press
        scale: devMa.pressed ? 0.97 : (devMa.containsMouse ? 1.015 : 1.0)
        Behavior on scale {
            NumberAnimation { duration: 130; easing.type: Easing.OutQuad }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: TitanTheme.bgOneUIPill

                Text {
                    anchors.centerIn: parent
                    text: "\uf10b" // mobile / device
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 14
                    color: TitanTheme.textSecondary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Device control"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: TitanTheme.textPrimary
                }

                Text {
                    text: "Manage connected devices"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    color: TitanTheme.textSubtle
                }
            }

            Text {
                text: "\uf054"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 10
                color: TitanTheme.textSubtle
            }
        }

        MouseArea {
            id: devMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (typeof systemCtrl !== "undefined" && systemCtrl)
                    systemCtrl.openSettings()
            }
        }
    }
}