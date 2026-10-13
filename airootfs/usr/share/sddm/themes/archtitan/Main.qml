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

    // ── Left-Center: Minimalist Futuristic Auth Form ─────────────────
    Item {
        id: authCard
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.09
        anchors.top: rollerClock.bottom
        anchors.topMargin: 56
        width: 320
        height: 300

        // Active Focus Indicator Pill (slides vertically between focused fields)
        Rectangle {
            id: focusPill
            x: -16
            width: 3
            height: 38
            radius: 1.5
            color: "#FFFFFF"
            visible: usernameField.activeFocus || passwordField.activeFocus

            y: usernameField.activeFocus ? usernameField.y : passwordField.y
            Behavior on y {
                NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
            }
        }

        Column {
            anchors.fill: parent
            spacing: 24

            // Branding Label: ARCHTITAN
            Text {
                text: "ARCHTITAN"
                color: "#7E8597"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.letterSpacing: 4
                font.family: "JetBrainsMono Nerd Font"
            }

            // Username Field with Minimal Underline
            Item {
                width: parent.width
                height: 44

                TextField {
                    id: usernameField
                    anchors.fill: parent
                    placeholderText: "User name"
                    placeholderTextColor: "#4A5164"
                    text: (typeof userModel !== "undefined" && userModel.lastUser) ? userModel.lastUser : ""
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"
                    color: "#F0F3FA"
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 0
                    rightPadding: 0

                    background: Rectangle {
                        color: "transparent"
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: usernameField.activeFocus ? 1.5 : 1
                            color: usernameField.activeFocus ? "#DCE2EE" : "#2A2F3D"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    Keys.onReturnPressed: passwordField.forceActiveFocus()
                }
            }

            // Password Field with Minimal Underline
            Item {
                width: parent.width
                height: 44

                TextField {
                    id: passwordField
                    anchors.fill: parent
                    placeholderText: "Password"
                    placeholderTextColor: "#4A5164"
                    echoMode: TextInput.Password
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"
                    color: "#F0F3FA"
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 0
                    rightPadding: 0

                    background: Rectangle {
                        color: "transparent"
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: passwordField.activeFocus ? 1.5 : 1
                            color: passwordField.activeFocus ? "#DCE2EE" : "#2A2F3D"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    Keys.onReturnPressed: root.triggerLogin()
                }
            }

            Item { height: 4 }

            // High-Contrast Solid White Button: ENTER SESSION
            Button {
                id: enterButton
                width: 250
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
                    radius: 2
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
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
    }

    // ── Bottom-Left: Session Selector ─────────────────────────────────
    Row {
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.09
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        spacing: 8

        Text {
            text: "SESSION"
            color: "#4B5264"
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 1.5
            font.family: "JetBrainsMono Nerd Font"
            anchors.verticalCenter: parent.verticalCenter
        }

        ComboBox {
            id: sessionCombo
            width: 140
            height: 28
            model: (typeof sessionModel !== "undefined") ? sessionModel : ["Hyprland"]
            currentIndex: (typeof sessionModel !== "undefined") ? sessionModel.lastIndex : 0
            textRole: "name"
            font.pixelSize: 10
            font.family: "JetBrainsMono Nerd Font"

            contentItem: Text {
                text: sessionCombo.displayText
                color: "#8E98AC"
                font: sessionCombo.font
                verticalAlignment: Text.AlignVCenter
                leftPadding: 6
            }

            background: Rectangle {
                radius: 4
                color: "#12141A"
                border.width: 1
                border.color: "#242834"
            }

            popup: Popup {
                y: -implicitHeight - 4
                width: sessionCombo.width
                implicitHeight: contentItem.implicitHeight + 10
                padding: 4
                background: Rectangle {
                    radius: 6
                    color: "#12141A"
                    border.width: 1
                    border.color: "#2E3444"
                }
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: sessionCombo.popup.visible ? sessionCombo.delegateModel : null
                }
            }

            delegate: ItemDelegate {
                width: sessionCombo.width
                height: 28
                contentItem: Text {
                    text: model.name ? model.name : modelData
                    color: highlighted ? "#FFFFFF" : "#8E98AC"
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: highlighted ? "#1E222D" : "transparent"
                    radius: 3
                }
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
    function triggerLogin() {
        if (typeof sddm !== "undefined" && typeof sessionModel !== "undefined") {
            sddm.login(usernameField.text, passwordField.text, sessionCombo.currentIndex)
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
