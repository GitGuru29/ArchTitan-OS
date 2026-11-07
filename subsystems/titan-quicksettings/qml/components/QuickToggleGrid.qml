import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * QuickToggleGrid — Apple macOS Control Center Bento Grid.
 *
 * Authentic macOS Control Center layout:
 * - 3-Row Connectivity Bento (Wi-Fi, Bluetooth, TitanDrop)
 * - Focus / Do Not Disturb card + Stage & Screen Mirroring
 * - Full-width Display Brightness & Sound Volume pill sliders
 * - Liquid Glass Opacity slider (ArchTitan exclusive)
 * - Now Playing media player card
 * - Modular quick action pills (Dark mode, Night shift, Mic mute, Caffeine)
 */
ColumnLayout {
    id: bentoRoot
    Layout.fillWidth: true
    spacing: 10

    // ── 1. Top Section: Connectivity (Left) + Focus & Utilities (Right) ─────
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 148
        spacing: 10

        // ── 1A. Left Bento: 3-Row Connectivity (Wi-Fi, Bluetooth, TitanDrop) ──
        Rectangle {
            id: connectivityCard
            Layout.preferredWidth: (parent.width - 10) / 2
            Layout.fillHeight: true
            radius: 18
            color: TitanTheme.bgOneUICard
            border.color: TitanTheme.borderGlass
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                // ── Wi-Fi Row ───────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38

                    RowLayout {
                        anchors.fill: parent
                        spacing: 8

                        Rectangle {
                            id: wifiIconCircle
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 16
                            color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                                   ? (TitanTheme.isDark ? "#007AFF" : TitanTheme.accent)
                                   : Qt.rgba(1, 1, 1, 0.12)

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "\uf1eb"
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 14
                                color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                                       ? "#FFFFFF" : TitanTheme.textMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof networkCtrl !== "undefined" && networkCtrl)
                                        networkCtrl.toggleWifi()
                                }
                            }
                        }

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
                                text: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                                      ? (networkCtrl.ssid ? networkCtrl.ssid : "Connected")
                                      : "Off"
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 10
                                color: TitanTheme.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            text: "›"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 16
                            color: TitanTheme.textMuted
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            rootWindow.showWifiPage = true;
                        }
                    }
                }

                // Hairline Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                // ── Bluetooth Row ───────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    spacing: 8

                    Rectangle {
                        id: btIconCircle
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 16
                        color: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered)
                               ? (TitanTheme.isDark ? "#007AFF" : TitanTheme.accent)
                               : Qt.rgba(1, 1, 1, 0.12)

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf294"
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 14
                            color: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered)
                                   ? "#FFFFFF" : TitanTheme.textMuted
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl)
                                    bluetoothCtrl.toggleBluetooth()
                            }
                        }
                    }

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
                            text: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl && bluetoothCtrl.powered)
                                  ? bluetoothCtrl.statusText : "Off"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 10
                            color: TitanTheme.textMuted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: "›"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 16
                        color: TitanTheme.textMuted
                    }
                }

                // Hairline Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                // ── TitanDrop / AirDrop Row ─────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 16
                        color: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.vpnActive)
                               ? "#007AFF" : Qt.rgba(1, 1, 1, 0.12)

                        Text {
                            anchors.centerIn: parent
                            text: "\uf1e0"
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 14
                            color: "#FFFFFF"
                        }
                    }

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
                            text: "Contacts Only"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 10
                            color: TitanTheme.textMuted
                        }
                    }
                }
            }
        }

        // ── 1B. Right Column: Focus (DND) Card + 2 Utilities Cards ──────────
        ColumnLayout {
            Layout.preferredWidth: (parent.width - 10) / 2
            Layout.fillHeight: true
            spacing: 10

            // ── Focus / Do Not Disturb Card (Height: 69px) ──────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 69
                radius: 18
                color: TitanTheme.bgOneUICard
                border.color: (typeof notifServer !== "undefined" && notifServer && notifServer.dndActive)
                              ? TitanTheme.accent : TitanTheme.borderGlass
                border.width: 1
                clip: true

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 17
                        color: (typeof notifServer !== "undefined" && notifServer && notifServer.dndActive)
                               ? "#5856D6" : Qt.rgba(1, 1, 1, 0.12)

                        Text {
                            anchors.centerIn: parent
                            text: "\uf186" // moon
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 15
                            color: (typeof notifServer !== "undefined" && notifServer && notifServer.dndActive)
                                   ? "#FFFFFF" : TitanTheme.textMuted
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "Focus"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: TitanTheme.textPrimary
                        }

                        Text {
                            text: (typeof notifServer !== "undefined" && notifServer && notifServer.dndActive)
                                  ? "Do Not Disturb" : "Off"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 10
                            color: TitanTheme.textMuted
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof notifServer !== "undefined" && notifServer)
                            notifServer.toggleDnd()
                    }
                }
            }

            // ── 2 Square Utilities Cards Side-by-Side (Height: 69px) ────────
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 69
                spacing: 10

                // Stage Manager / Overview
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    color: TitanTheme.bgOneUICard
                    border.color: TitanTheme.borderGlass
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uf009" // tiles / stage
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 16
                            color: TitanTheme.textPrimary
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Stage"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: TitanTheme.textPrimary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.openSettings();
                        }
                    }
                }

                // Screen Capture / Snip
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    color: TitanTheme.bgOneUICard
                    border.color: TitanTheme.borderGlass
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uf030" // camera / snip
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 16
                            color: TitanTheme.textPrimary
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Screen"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: TitanTheme.textPrimary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.takeScreenshot();
                        }
                    }
                }
            }
        }
    }

    // ── 2. Display Brightness Bento Card (Apple Pill Slider) ────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: displayCol.implicitHeight + 20
        radius: 18
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true

        ColumnLayout {
            id: displayCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            OneUISlider {
                title: "Display"
                iconGlyph: "\uf185" // sun
                from: 0
                to: 100
                value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.brightness : 80
                fillAccent: "#FFFFFF"
                onChanged: (v) => {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setBrightness(v)
                }
            }
        }
    }

    // ── 3. Sound Volume Bento Card (Apple Pill Slider) ──────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: soundCol.implicitHeight + 20
        radius: 18
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true

        ColumnLayout {
            id: soundCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            OneUISlider {
                title: "Sound"
                iconGlyph: {
                    if (muted) return "\uf026";
                    if (value <= 30) return "\uf027";
                    return "\uf028";
                }
                from: 0
                to: 100
                value: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sinkVolume : 60
                muted: typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sinkMuted
                fillAccent: "#FFFFFF"
                onChanged: (v) => {
                    if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.setVolume(v)
                }
            }
        }
    }

    // ── 4. Liquid Glass Opacity Bento Card (ArchTitan Exclusive) ───────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: glassCol.implicitHeight + 20
        radius: 18
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true

        ColumnLayout {
            id: glassCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            OneUISlider {
                title: "Liquid Glass"
                iconGlyph: "\uf043" // water droplet
                from: 10
                to: 95
                value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.glassOpacity : 35
                suffix: "%"
                fillAccent: TitanTheme.cyan
                onChanged: (v) => {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) {
                        if (typeof systemCtrl.setGlassOpacity === "function") {
                            systemCtrl.setGlassOpacity(v)
                        } else {
                            systemCtrl.glassOpacity = v
                        }
                    }
                }
            }
        }
    }

    // ── 5. Now Playing / Media Player Bento Card ───────────────────────────
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 74
        radius: 18
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // Album Art Thumbnail (Squircle 48x48)
            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.12)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.15)
                clip: true

                Text {
                    anchors.centerIn: parent
                    text: "\uf001" // music note
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 20
                    color: TitanTheme.accent
                }
            }

            // Track Details
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "ArchTitan Audio Engine"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: TitanTheme.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: "PipeWire • WirePlumber Native"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    color: TitanTheme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Media Playback Controls
            RowLayout {
                spacing: 14

                Text {
                    text: "\uf04a" // previous
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 14
                    color: TitanTheme.textMuted
                }

                Rectangle {
                    width: 30
                    height: 30
                    radius: 15
                    color: Qt.rgba(1, 1, 1, 0.16)

                    Text {
                        anchors.centerIn: parent
                        text: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sinkMuted) ? "\uf04b" : "\uf04c"
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 12
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof audioCtrl !== "undefined" && audioCtrl)
                                audioCtrl.toggleSinkMute()
                        }
                    }
                }

                Text {
                    text: "\uf04e" // next
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 14
                    color: TitanTheme.textMuted
                }
            }
        }
    }

    // ── 6. Modular Quick Action Pills (Dark Mode, Night Shift, Mic Mute, Caffeine)
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        spacing: 6

        // Dark Mode Pill
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.themeDark)
                   ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.themeDark)
                          ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(1, 1, 1, 0.08)

            RowLayout {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.themeDark) ? "\uf186" : "\uf185"
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 11
                    color: "#FFFFFF"
                }
                Text {
                    text: "Dark"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: "#FFFFFF"
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                        systemCtrl.themeDark = !systemCtrl.themeDark
                }
            }
        }

        // Night Shift Pill
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: (typeof nightLightCtrl !== "undefined" && nightLightCtrl && nightLightCtrl.active)
                   ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: (typeof nightLightCtrl !== "undefined" && nightLightCtrl && nightLightCtrl.active)
                          ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(1, 1, 1, 0.08)

            RowLayout {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: "\uf06e" // eye
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 11
                    color: (typeof nightLightCtrl !== "undefined" && nightLightCtrl && nightLightCtrl.active)
                           ? TitanTheme.cyan : "#FFFFFF"
                }
                Text {
                    text: "Night"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: "#FFFFFF"
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof nightLightCtrl !== "undefined" && nightLightCtrl)
                        nightLightCtrl.toggleNightLight()
                }
            }
        }

        // Mic Mute Pill
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted)
                   ? Qt.rgba(243/255, 139/255, 168/255, 0.25) : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted)
                          ? TitanTheme.red : Qt.rgba(1, 1, 1, 0.08)

            RowLayout {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted) ? "\uf131" : "\uf130"
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 11
                    color: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted)
                           ? TitanTheme.red : "#FFFFFF"
                }
                Text {
                    text: "Mic"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: "#FFFFFF"
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof audioCtrl !== "undefined" && audioCtrl)
                        audioCtrl.toggleSourceMute()
                }
            }
        }

        // Caffeine / Awake Pill
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.caffeineActive)
                   ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            border.color: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.caffeineActive)
                          ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(1, 1, 1, 0.08)

            RowLayout {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: "\uf0f4" // coffee
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 11
                    color: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.caffeineActive)
                           ? TitanTheme.peach : "#FFFFFF"
                }
                Text {
                    text: "Awake"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: "#FFFFFF"
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                        systemCtrl.setCaffeineActive(!systemCtrl.caffeineActive)
                }
            }
        }
    }
}
