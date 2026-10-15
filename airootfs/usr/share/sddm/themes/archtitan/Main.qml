import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Components"

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#08090C"

    // Configuration defaults from theme.conf
    property string ringMode: (typeof config !== "undefined" && config.ringMode) ? config.ringMode : "music"
    property color customAccent: (typeof config !== "undefined" && config.ringColor) ? config.ringColor : "#FFFFFF"
    property bool isMusicPlaying: false
    property bool simulateMusic: false
    property bool is24Hour: (typeof config !== "undefined" && config.clockFormat === "12h") ? false : true

    // ── Background Atmosphere & Haze ─────────────────────────────────
    // Dark carbon background
    Rectangle {
        anchors.fill: parent
        color: "#07080B"
    }

    // Horizontal atmospheric misty band (across the center horizon)
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 40
        height: 240
        opacity: 0.18
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.35; color: "#2B3245" }
            GradientStop { position: 0.50; color: "#46506B" }
            GradientStop { position: 0.65; color: "#2B3245" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Secondary subtle horizon beam
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        height: 1
        color: "#181B24"
    }

    // ── Centerpiece: The Spire, Compass Reticle & Glowing RGB Ring ───
    SpireReticle {
        id: spireReticle
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.12
        anchors.bottom: parent.bottom
        width: 720
        height: parent.height

        ringMode: root.ringMode
        customAccent: root.customAccent
        isMusicPlaying: root.isMusicPlaying || root.simulateMusic
    }

    // ── Top-Left: Mechanical Drum Roller Clock ────────────────────────
    RollerClock {
        id: rollerClock
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.09
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.09
        is24Hour: root.is24Hour
    }

    // ── Left-Center: Frosted Glass Auth Card ─────────────────────────
    Rectangle {
        id: authCard
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.09
        anchors.top: rollerClock.bottom
        anchors.topMargin: 48
        width: 350
        height: 320
        radius: 16
        color: Qt.rgba(0.04, 0.05, 0.08, 0.78)
        border.width: 1
        border.color: Qt.rgba(0.48, 0.64, 0.97, 0.28)

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // Card Header: Branding & Security Badge
            Row {
                width: parent.width
                height: 18

                Text {
                    text: "ARCHTITAN"
                    color: "#7E8597"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 3
                    font.family: "JetBrainsMono Nerd Font"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    id: headerSpacer
                    width: parent.width - 90 - badgeText.implicitWidth
                    height: 1
                }

                Text {
                    id: badgeText
                    text: "󰌾 SECURED"
                    color: "#4A5164"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    font.family: "JetBrainsMono Nerd Font"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Username Field Inside Glass Card
            Rectangle {
                width: parent.width
                height: 44
                radius: 10
                color: usernameField.activeFocus ? Qt.rgba(0.08, 0.10, 0.15, 0.95) : Qt.rgba(0.06, 0.08, 0.12, 0.75)
                border.width: 1
                border.color: usernameField.activeFocus ? "#7AA2F7" : Qt.rgba(1, 1, 1, 0.08)
                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextField {
                    id: usernameField
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    placeholderText: "User name"
                    placeholderTextColor: "#4A5164"
                    text: (typeof userModel !== "undefined" && userModel.lastUser) ? userModel.lastUser : ""
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    color: "#F0F3FA"
                    verticalAlignment: Text.AlignVCenter
                    background: null

                    Keys.onReturnPressed: passwordField.forceActiveFocus()
                }
            }

            // Password Field Inside Glass Card
            Rectangle {
                width: parent.width
                height: 44
                radius: 10
                color: passwordField.activeFocus ? Qt.rgba(0.08, 0.10, 0.15, 0.95) : Qt.rgba(0.06, 0.08, 0.12, 0.75)
                border.width: 1
                border.color: passwordField.activeFocus ? "#7AA2F7" : Qt.rgba(1, 1, 1, 0.08)
                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextField {
                    id: passwordField
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    placeholderText: "Password"
                    placeholderTextColor: "#4A5164"
                    echoMode: TextInput.Password
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    color: "#F0F3FA"
                    verticalAlignment: Text.AlignVCenter
                    background: null

                    Keys.onReturnPressed: root.triggerLogin()
                }
            }

            Item { height: 2 }

            // High-Contrast Solid White Button: ENTER SESSION
            Button {
                id: enterButton
                width: parent.width
                height: 42
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 2
                font.family: "JetBrainsMono Nerd Font"

                contentItem: Text {
                    text: "ENTER SESSION"
                    font: enterButton.font
                    color: "#08090C"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 8
                    color: enterButton.pressed ? "#CBD5E1" : (enterButton.hovered ? "#F8FAFC" : "#FFFFFF")
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                onClicked: root.triggerLogin()
            }

            // Auth Error Message: !! AUTH FAILED
            Text {
                id: errorMessage
                text: ""
                color: "#FF455B"
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 2
                font.family: "JetBrainsMono Nerd Font"
                visible: text.length > 0
                opacity: text.length > 0 ? 1.0 : 0.0
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
    }

    // ── Bottom-Right: System & Customization Actions ──────────────────
    Row {
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.09
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        spacing: 16

        // 1. Settings Gear Icon (Opens in-greeter customizer drawer)
        Text {
            text: ""
            color: gearMouse.containsMouse ? "#FFFFFF" : "#636B7E"
            font.pixelSize: 17
            font.family: "JetBrainsMono Nerd Font"
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 120 } }

            MouseArea {
                id: gearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: customDrawer.visible = !customDrawer.visible
            }
        }

        // 2. Reboot Icon
        Text {
            text: "⟳"
            color: rebootMouse.containsMouse ? "#FFFFFF" : "#636B7E"
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 120 } }

            MouseArea {
                id: rebootMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof sddm !== "undefined") sddm.reboot()
                }
            }
        }

        // 3. Power Off Icon
        Text {
            text: "⏻"
            color: powerMouse.containsMouse ? "#FFFFFF" : "#636B7E"
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 120 } }

            MouseArea {
                id: powerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof sddm !== "undefined") sddm.powerOff()
                }
            }
        }
    }

    // ── Interactive Customizer Popover Drawer ─────────────────────────
    CustomizerDrawer {
        id: customDrawer
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.09
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 70
        visible: false

        currentRingMode: root.ringMode
        currentAccent: root.customAccent
        is24HourClock: root.is24Hour
        simulateMusic: root.simulateMusic

        onRingModeChanged: function(m) { root.ringMode = m }
        onAccentColorChanged: function(c) { root.customAccent = c; root.ringMode = "accent" }
        onClockFormatChanged: function(is24) { root.is24Hour = is24 }
        onSimulateMusicToggled: function(sim) { root.simulateMusic = sim }
        onCloseRequested: { customDrawer.visible = false }
    }

    // ── Music / Audio Playback Detection Poller ───────────────────────
    Timer {
        id: audioCheckTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            // Poll local state file written by PipeWire / MPRIS listener
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///tmp/titan-music-state.json", true)
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200 && xhr.responseText) {
                        try {
                            var data = JSON.parse(xhr.responseText)
                            root.isMusicPlaying = (data.playing === true)
                        } catch (e) {
                            root.isMusicPlaying = false
                        }
                    } else {
                        root.isMusicPlaying = false
                    }
                }
            }
            xhr.send()
        }
    }

    // ── SDDM Authentication Handlers ──────────────────────────────────
    readonly property int hyprlandSessionIndex: {
        if (typeof sessionModel === "undefined" || !sessionModel) return 0
        try {
            var count = (typeof sessionModel.rowCount === "function") ? sessionModel.rowCount() : (sessionModel.count || 0)
            for (var i = 0; i < count; ++i) {
                var sName = ""
                if (typeof sessionModel.get === "function") {
                    var s = sessionModel.get(i)
                    sName = s ? (s.name || s.file || "") : ""
                }
                if (sName.toLowerCase().indexOf("hyprland") !== -1) {
                    return i
                }
            }
        } catch (e) {}
        return (typeof sessionModel.lastIndex !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    }

    function triggerLogin() {
        if (typeof sddm !== "undefined") {
            sddm.login(usernameField.text, passwordField.text, root.hyprlandSessionIndex)
        }
    }

    Connections {
        target: (typeof sddm !== "undefined") ? sddm : null
        ignoreUnknownSignals: true
        function onLoginFailed() {
            errorMessage.text = "!! AUTH FAILED"
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
        function onLoginSucceeded() {
            errorMessage.text = ""
        }
    }

    Component.onCompleted: {
        if (usernameField.text === "") {
            usernameField.forceActiveFocus()
        } else {
            passwordField.forceActiveFocus()
        }
    }
}
