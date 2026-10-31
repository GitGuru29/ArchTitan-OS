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

    // Actions shared by the MouseArea and the keyboard handler of rows that
    // are also reachable with Tab / arrows.
    function openDeviceControl() {
        if (typeof systemCtrl !== "undefined" && systemCtrl)
            systemCtrl.openSettings();
    }

    function openPowerMenu() {
        if (typeof systemCtrl !== "undefined" && systemCtrl)
            systemCtrl.openPowerMenu();
    }

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
            onToggleClicked: {
                if (typeof networkCtrl !== "undefined" && networkCtrl)
                    networkCtrl.toggleWifi()
            }
            onDetailClicked: {
                rootWindow.showWifiPage = true;
            }
            onClicked: {
                rootWindow.showWifiPage = true;
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
        implicitHeight: sliderCol.implicitHeight + 24
        radius: TitanTheme.radiusBento
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true
        visible: (typeof systemCtrl !== "undefined" && systemCtrl)
                 ? (systemCtrl.tileVisibilityRevision >= 0 && systemCtrl.getTileVisible("sliders", true)) : true

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

            // Glass Transparency / Opacity Slider
            OneUISlider {
                iconGlyph: "\uf043" // water droplet / glass tint
                from: 10
                to: 95
                value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.glassOpacity : 35
                fillAccent: TitanTheme.cyan
                suffix: "%"
                onChanged: (v) => {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setGlassOpacity(v)
                }
            }
        }
    }

    // ── 4. Circular Quick Action Toggles (Reflowing Grid) ───────────────────
    Rectangle {
        id: actionTilesCard
        Layout.fillWidth: true
        implicitHeight: actionGrid.implicitHeight + 24
        radius: TitanTheme.radiusBento
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true
        visible: (showCapture || showColorPick || showGameMode || showClipboard ||
                  showCaffeine || showVirtualInput || showRecord || showAirplane)

        readonly property bool showCapture: (typeof systemCtrl !== "undefined" && systemCtrl)
                                            ? (systemCtrl.tileVisibilityRevision >= 0 && systemCtrl.getTileVisible("capture", true)) : true
        readonly property bool showColorPick: (typeof systemCtrl !== "undefined" && systemCtrl)
                                              ? (systemCtrl.tileVisibilityRevision >= 0 && systemCtrl.getTileVisible("colorPick", true)) : true
        readonly property bool showGameMode: (typeof systemCtrl !== "undefined" && systemCtrl)
                                             ? (systemCtrl.tileVisibilityRevision >= 0 && systemCtrl.getTileVisible("gameMode", true)) : true
        readonly property bool showClipboard: (typeof systemCtrl !== "undefined" && systemCtrl)
                                              ? (systemCtrl.tileVisibilityRevision >= 0 && systemCtrl.getTileVisible("clipboard", true)) : true
        readonly property bool showCaffeine: (typeof systemCtrl !== "undefined" && systemCtrl)
                                             ? (systemCtrl.tileVisibilityRevision >= 0 && systemCtrl.getTileVisible("caffeine", true)) : true
        readonly property bool showVirtualInput: (typeof systemCtrl !== "undefined" && systemCtrl)
                                                 ? (systemCtrl.tileVisibilityRevision >= 0 && systemCtrl.getTileVisible("virtualInput", true)) : true
        readonly property bool showRecord: (typeof systemCtrl !== "undefined" && systemCtrl)
                                           ? (systemCtrl.tileVisibilityRevision >= 0 && systemCtrl.getTileVisible("record", true)) : true
        readonly property bool showAirplane: (typeof systemCtrl !== "undefined" && systemCtrl)
                                             ? (systemCtrl.tileVisibilityRevision >= 0 && systemCtrl.getTileVisible("airplane", true)) : true

        GridLayout {
            id: actionGrid
            anchors.fill: parent
            anchors.margins: 12
            columns: 4
            rowSpacing: 12
            columnSpacing: 0

            // Capture
            Item {
                visible: actionTilesCard.showCapture
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

            // Color pick
            Item {
                visible: actionTilesCard.showColorPick
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

            // Game mode
            Item {
                visible: actionTilesCard.showGameMode
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

            // Clipboard
            Item {
                visible: actionTilesCard.showClipboard
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

            // Awake
            Item {
                visible: actionTilesCard.showCaffeine
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

            // Virtual input
            Item {
                visible: actionTilesCard.showVirtualInput
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

            // Screen record
            Item {
                visible: actionTilesCard.showRecord
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

            // Airplane
            Item {
                visible: actionTilesCard.showAirplane
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

    // ── 5. Bottom Device & Media Control Tiles ──────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        height: 50
        radius: 20
        color: medMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true
        visible: (typeof systemCtrl !== "undefined" && systemCtrl)
                 ? (systemCtrl.tileVisibilityRevision >= 0 && systemCtrl.getTileVisible("deviceMedia", true)) : true

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
                    font.family: TitanTheme.monoFamily
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
                font.family: TitanTheme.monoFamily
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
        // Keyboard reachability for this list row.
        activeFocusOnTab: true
        Keys.onReturnPressed: (event) => { bentoRoot.openDeviceControl(); event.accepted = true }
        Keys.onEnterPressed:  (event) => { bentoRoot.openDeviceControl(); event.accepted = true }
        Keys.onSpacePressed:  (event) => { bentoRoot.openDeviceControl(); event.accepted = true }
        color: devMa.containsMouse || activeFocus ? TitanTheme.bgHover : TitanTheme.bgOneUICard
        border.color: activeFocus ? TitanTheme.accent : TitanTheme.borderGlass
        border.width: activeFocus ? 2 : 1
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
                    font.family: TitanTheme.monoFamily
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
                font.family: TitanTheme.monoFamily
                font.pixelSize: 10
                color: TitanTheme.textSubtle
            }
        }

        MouseArea {
            id: devMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: bentoRoot.openDeviceControl()
        }
    }

    // ── 6. Power & Session Bento Tile ───────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        height: 50
        radius: 20
        color: pwrTileMa.containsMouse ? Qt.rgba(TitanTheme.red.r, TitanTheme.red.g, TitanTheme.red.b, 0.16) : TitanTheme.bgOneUICard
        border.color: activeFocus ? TitanTheme.accent
                      : pwrTileMa.containsMouse ? Qt.rgba(TitanTheme.red.r, TitanTheme.red.g, TitanTheme.red.b, 0.45)
                      : TitanTheme.borderGlass
        border.width: activeFocus ? 2 : 1
        clip: true

        // Keyboard reachability for this bento tile.
        activeFocusOnTab: true
        Keys.onReturnPressed: (event) => { bentoRoot.openPowerMenu(); event.accepted = true }
        Keys.onEnterPressed:  (event) => { bentoRoot.openPowerMenu(); event.accepted = true }
        Keys.onSpacePressed:  (event) => { bentoRoot.openPowerMenu(); event.accepted = true }

        // Tactile Liquid Touch: spring bounce on hover and press
        scale: pwrTileMa.pressed ? 0.97 : (pwrTileMa.containsMouse ? 1.015 : 1.0)
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
                color: Qt.rgba(TitanTheme.red.r, TitanTheme.red.g, TitanTheme.red.b, 0.2)

                Text {
                    anchors.centerIn: parent
                    text: "\uf011" // power
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 13
                    color: TitanTheme.red
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Power menu"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: TitanTheme.textPrimary
                }

                Text {
                    text: "Lock, sleep, restart or power off"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    color: TitanTheme.textSubtle
                }
            }

            Text {
                text: "\uf054"
                font.family: TitanTheme.monoFamily
                font.pixelSize: 10
                color: TitanTheme.textSubtle
            }
        }

        MouseArea {
            id: pwrTileMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (typeof rootWindow !== "undefined" && rootWindow) {
                    rootWindow.showPowerMenu = true;
                } else if (typeof systemCtrl !== "undefined" && systemCtrl) {
                    systemCtrl.openPowerMenu();
                }
            }
        }
    }
}