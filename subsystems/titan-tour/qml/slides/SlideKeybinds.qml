import QtQuick
import QtQuick.Layouts
import "../components"

Item {
    id: slideRoot

    property int activeKeybindIndex: 0

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 36
        anchors.rightMargin: 36
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 14

        // Header Title
        ColumnLayout {
            spacing: 2
            Text {
                text: "THE COMMAND DECK"
                font.pixelSize: 18
                font.weight: Font.Black
                font.letterSpacing: 1.5
                color: "#F8FAFC"
                font.family: "Inter, sans-serif"
            }
            Text {
                text: "ArchTitan is designed for lightning-speed keyboard mastery. Click any shortcut below to preview or test it live."
                font.pixelSize: 11
                color: "#94A3B8"
            }
        }

        // ── Interactive Keycap Visualizer Row ───────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            radius: 14
            color: Qt.rgba(0.06, 0.08, 0.13, 0.85)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 12

                KeycapItem {
                    keyText: "⊞ SUPER"
                    subText: "COMMAND"
                    isActive: true
                    activeGlow: "#38BDF8"
                }

                Text { text: "+"; font.pixelSize: 16; font.weight: Font.Bold; color: "#64748B" }

                KeycapItem {
                    id: targetKey
                    keyText: {
                        if (slideRoot.activeKeybindIndex === 0) return "SPACE"
                        if (slideRoot.activeKeybindIndex === 1) return "N"
                        if (slideRoot.activeKeybindIndex === 2) return "T"
                        if (slideRoot.activeKeybindIndex === 3) return "E"
                        return "Q"
                    }
                    subText: {
                        if (slideRoot.activeKeybindIndex === 0) return "SEARCH"
                        if (slideRoot.activeKeybindIndex === 1) return "CONTROL"
                        if (slideRoot.activeKeybindIndex === 2) return "TERMINAL"
                        if (slideRoot.activeKeybindIndex === 3) return "FILES"
                        return "CLOSE"
                    }
                    isActive: true
                    activeGlow: "#0EA5E9"
                }

                Rectangle { width: 1; height: 32; color: Qt.rgba(1, 1, 1, 0.15); Layout.leftMargin: 10; Layout.rightMargin: 10 }

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: {
                            if (slideRoot.activeKeybindIndex === 0) return "Titan Spotlight & App Launcher"
                            if (slideRoot.activeKeybindIndex === 1) return "Titan Control Center & Quick Settings"
                            if (slideRoot.activeKeybindIndex === 2) return "GPU-Accelerated Terminal (Kitty/Fish)"
                            if (slideRoot.activeKeybindIndex === 3) return "File Manager & Storage Browser"
                            return "Instantly Close Active Window"
                        }
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: "#E2E8F0"
                    }
                    Text {
                        text: {
                            if (slideRoot.activeKeybindIndex === 0) return "Instant search, math expressions, shell actions, and installed apps."
                            if (slideRoot.activeKeybindIndex === 1) return "Wi-Fi, Bluetooth, displays, audio volume, media player, and 12 quick actions."
                            if (slideRoot.activeKeybindIndex === 2) return "Pre-configured with Titan Fetch system telemetry and fish shell prompts."
                            if (slideRoot.activeKeybindIndex === 3) return "Browse local drives, NVMe mountpoints, and Titan Share transfers."
                            return "Closes the focused application window gracefully."
                        }
                        font.pixelSize: 10
                        color: "#94A3B8"
                    }
                }
            }
        }

        // ── 5 Clickable Shortcut Cards ──────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // Item 1: Super + Space (Spotlight)
            GlowingCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                border.color: slideRoot.activeKeybindIndex === 0 ? "#0EA5E9" : Qt.rgba(1, 1, 1, 0.10)
                color: slideRoot.activeKeybindIndex === 0 ? Qt.rgba(0.08, 0.22, 0.38, 0.85) : Qt.rgba(0.08, 0.11, 0.17, 0.78)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 14

                    Text { text: "🔍"; font.pixelSize: 14 }
                    Text { text: "Super + Space"; font.pixelSize: 11; font.weight: Font.Bold; font.family: "JetBrains Mono"; color: "#38BDF8" }
                    Text { text: "Universal Spotlight Search"; font.pixelSize: 11; color: "#E2E8F0"; Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: 80
                        implicitHeight: 26
                        radius: 6
                        color: testSpotlightHover.containsMouse ? "#0284C7" : Qt.rgba(0.05, 0.65, 1.0, 0.25)
                        border.color: "#38BDF8"
                        border.width: 1

                        Text { anchors.centerIn: parent; text: "Try Live ❯"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            id: testSpotlightHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                slideRoot.activeKeybindIndex = 0
                                if (typeof tourCtrl !== "undefined") tourCtrl.toggleSpotlight()
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: slideRoot.activeKeybindIndex = 0
                }
            }

            // Item 2: Super + N (Control Center)
            GlowingCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                border.color: slideRoot.activeKeybindIndex === 1 ? "#0EA5E9" : Qt.rgba(1, 1, 1, 0.10)
                color: slideRoot.activeKeybindIndex === 1 ? Qt.rgba(0.08, 0.22, 0.38, 0.85) : Qt.rgba(0.08, 0.11, 0.17, 0.78)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 14

                    Text { text: "🎛️"; font.pixelSize: 14 }
                    Text { text: "Super + N"; font.pixelSize: 11; font.weight: Font.Bold; font.family: "JetBrains Mono"; color: "#38BDF8" }
                    Text { text: "Titan Control Center (macOS Bento)"; font.pixelSize: 11; color: "#E2E8F0"; Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: 80
                        implicitHeight: 26
                        radius: 6
                        color: testCcHover.containsMouse ? "#0284C7" : Qt.rgba(0.05, 0.65, 1.0, 0.25)
                        border.color: "#38BDF8"
                        border.width: 1

                        Text { anchors.centerIn: parent; text: "Try Live ❯"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            id: testCcHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                slideRoot.activeKeybindIndex = 1
                                if (typeof tourCtrl !== "undefined") tourCtrl.toggleControlCenter()
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: slideRoot.activeKeybindIndex = 1
                }
            }

            // Item 3: Super + T (Terminal)
            GlowingCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                border.color: slideRoot.activeKeybindIndex === 2 ? "#0EA5E9" : Qt.rgba(1, 1, 1, 0.10)
                color: slideRoot.activeKeybindIndex === 2 ? Qt.rgba(0.08, 0.22, 0.38, 0.85) : Qt.rgba(0.08, 0.11, 0.17, 0.78)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 14

                    Text { text: "⚡"; font.pixelSize: 14 }
                    Text { text: "Super + T"; font.pixelSize: 11; font.weight: Font.Bold; font.family: "JetBrains Mono"; color: "#38BDF8" }
                    Text { text: "Launch Terminal (Kitty)"; font.pixelSize: 11; color: "#E2E8F0"; Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: 80
                        implicitHeight: 26
                        radius: 6
                        color: testTermHover.containsMouse ? "#0284C7" : Qt.rgba(0.05, 0.65, 1.0, 0.25)
                        border.color: "#38BDF8"
                        border.width: 1

                        Text { anchors.centerIn: parent; text: "Try Live ❯"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            id: testTermHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                slideRoot.activeKeybindIndex = 2
                                if (typeof tourCtrl !== "undefined") tourCtrl.launchTerminal()
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: slideRoot.activeKeybindIndex = 2
                }
            }

            // Item 4: Super + 1..9 (Workspaces)
            GlowingCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                border.color: slideRoot.activeKeybindIndex === 3 ? "#0EA5E9" : Qt.rgba(1, 1, 1, 0.10)
                color: slideRoot.activeKeybindIndex === 3 ? Qt.rgba(0.08, 0.22, 0.38, 0.85) : Qt.rgba(0.08, 0.11, 0.17, 0.78)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 14

                    Text { text: "🖥️"; font.pixelSize: 14 }
                    Text { text: "Super + 1..9"; font.pixelSize: 11; font.weight: Font.Bold; font.family: "JetBrains Mono"; color: "#38BDF8" }
                    Text { text: "Fluid Hyprland Workspace Switching"; font.pixelSize: 11; color: "#E2E8F0"; Layout.fillWidth: true }
                    Text { text: "Zero Lag"; font.pixelSize: 10; font.weight: Font.DemiBold; color: "#64748B" }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: slideRoot.activeKeybindIndex = 3
                }
            }
        }
    }
}
