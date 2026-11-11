import QtQuick
import QtQuick.Layouts
import "../components"

Item {
    id: slideRoot

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 36
        anchors.rightMargin: 36
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 16

        // Header Title
        ColumnLayout {
            spacing: 2
            Text {
                text: (typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode) ? "READY FOR INSTALLATION" : "READY FOR LAUNCH"
                font.pixelSize: 18
                font.weight: Font.Black
                font.letterSpacing: 1.5
                color: "#F8FAFC"
                font.family: "Inter, sans-serif"
            }
            Text {
                text: (typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode)
                      ? "You are currently running in the Live USB environment. You can test features freely or install ArchTitan to your disk."
                      : "Your system is fully tuned and ready. Explore custom settings, change wallpapers, or dive right into your terminal."
                font.pixelSize: 11
                color: "#94A3B8"
            }
        }

        // ── Main Hero CTA Card ──────────────────────────────────────────────
        GlowingCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            color: (typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode)
                   ? Qt.rgba(0.95, 0.55, 0.05, 0.20)
                   : Qt.rgba(0.05, 0.65, 1.0, 0.20)
            border.color: (typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode)
                          ? "#F59E0B"
                          : "#0EA5E9"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                // Big Icon Squircle
                Rectangle {
                    width: 64
                    height: 64
                    radius: 18
                    color: (typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode)
                           ? "#D97706"
                           : "#0284C7"
                    border.color: "#FFFFFF"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: (typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode) ? "🚀" : "⚡"
                        font.pixelSize: 28
                    }
                }

                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true

                    Text {
                        text: (typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode) ? "Install ArchTitan to NVMe / SSD" : "Enter ArchTitan Workstation"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                        font.family: "Inter, sans-serif"
                    }

                    Text {
                        text: (typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode)
                              ? "Launch Calamares graphical installer with automatic Btrfs snapshots, Zram swap, and bootloader setup."
                              : "You are running on bare-metal hardware. All systems are online, optimized, and ready."
                        font.pixelSize: 11
                        color: "#CBD5E1"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    implicitWidth: 140
                    implicitHeight: 42
                    radius: 10
                    color: primaryHover.containsMouse ? "#FFFFFF" : "#F8FAFC"

                    Text {
                        anchors.centerIn: parent
                        text: (typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode) ? "Launch Installer ❯" : "Get Started ❯"
                        font.pixelSize: 12
                        font.weight: Font.Black
                        color: (typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode) ? "#B45309" : "#0369A1"
                    }

                    MouseArea {
                        id: primaryHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof tourCtrl !== "undefined") {
                                if (tourCtrl.isLiveMode) {
                                    tourCtrl.launchInstaller()
                                } else {
                                    tourCtrl.finishTour(!tourCtrl.showOnStartup)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── 3 Quick Action Cards ────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // Action 1: Speaker Audio Test
            GlowingCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    RowLayout {
                        Text { text: "🔊 Audio Check"; font.pixelSize: 11; font.weight: Font.Bold; color: "#38BDF8"; Layout.fillWidth: true }
                        Text { text: "PipeWire"; font.pixelSize: 9; color: "#64748B" }
                    }

                    Text {
                        text: "Play spatial audio test chime to verify speaker balance and volume levels."
                        font.pixelSize: 10
                        color: "#94A3B8"
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 6
                        color: testSndHover.containsMouse ? "#0284C7" : Qt.rgba(0.05, 0.65, 1.0, 0.25)
                        border.color: "#38BDF8"

                        Text { anchors.centerIn: parent; text: "Play Audio Chime ❯"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            id: testSndHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof tourCtrl !== "undefined") tourCtrl.testAudio()
                            }
                        }
                    }
                }
            }

            // Action 2: Settings
            GlowingCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    RowLayout {
                        Text { text: "⚙️ System Settings"; font.pixelSize: 11; font.weight: Font.Bold; color: "#818CF8"; Layout.fillWidth: true }
                        Text { text: "Preferences"; font.pixelSize: 9; color: "#64748B" }
                    }

                    Text {
                        text: "Configure displays, scaling, keyboard layouts, and Waybar themes."
                        font.pixelSize: 10
                        color: "#94A3B8"
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 6
                        color: cfgHover.containsMouse ? "#4338CA" : Qt.rgba(0.4, 0.2, 0.9, 0.25)
                        border.color: "#818CF8"

                        Text { anchors.centerIn: parent; text: "Open Settings ❯"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            id: cfgHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof tourCtrl !== "undefined") tourCtrl.launchSettings()
                            }
                        }
                    }
                }
            }

            // Action 3: Terminal
            GlowingCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    RowLayout {
                        Text { text: "⚡ Open Terminal"; font.pixelSize: 11; font.weight: Font.Bold; color: "#34D399"; Layout.fillWidth: true }
                        Text { text: "Kitty"; font.pixelSize: 9; color: "#64748B" }
                    }

                    Text {
                        text: "Launch GPU-accelerated terminal with fish shell and pacman package manager."
                        font.pixelSize: 10
                        color: "#94A3B8"
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 6
                        color: termHover.containsMouse ? "#059669" : Qt.rgba(0.1, 0.8, 0.4, 0.25)
                        border.color: "#34D399"

                        Text { anchors.centerIn: parent; text: "Launch Terminal ❯"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            id: termHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof tourCtrl !== "undefined") tourCtrl.launchTerminal()
                            }
                        }
                    }
                }
            }
        }
    }
}

