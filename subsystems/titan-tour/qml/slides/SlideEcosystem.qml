import QtQuick
import QtQuick.Layouts
import "../components"

Item {
    id: slideRoot

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
                text: "THE NATIVE TITAN ECOSYSTEM"
                font.pixelSize: 18
                font.weight: Font.Black
                font.letterSpacing: 1.5
                color: "#F8FAFC"
                font.family: "Inter, sans-serif"
            }
            Text {
                text: "A suite of bespoke native tools designed specifically for ArchTitan OS."
                font.pixelSize: 11
                color: "#94A3B8"
            }
        }

        // 2x2 Feature Grid
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: 12
            columnSpacing: 14

            // Feature 1: Titan Share
            GlowingCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    RowLayout {
                        spacing: 8
                        Rectangle {
                            width: 28; height: 28; radius: 6
                            color: Qt.rgba(0.05, 0.65, 1.0, 0.25)
                            border.color: "#38BDF8"
                            Text { anchors.centerIn: parent; text: "📡"; font.pixelSize: 13 }
                        }
                        Text { text: "Titan Share"; font.pixelSize: 12; font.weight: Font.Bold; color: "#38BDF8" }
                    }

                    Text {
                        text: "Frictionless local network peer-to-peer file transfers. Send files and clipboard text to other Titan devices with zero configuration."
                        font.pixelSize: 10
                        color: "#94A3B8"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Feature 2: Titan Wallpaper Engine
            GlowingCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    RowLayout {
                        spacing: 8
                        Rectangle {
                            width: 28; height: 28; radius: 6
                            color: Qt.rgba(0.8, 0.3, 0.9, 0.25)
                            border.color: "#C084FC"
                            Text { anchors.centerIn: parent; text: "🎨"; font.pixelSize: 13 }
                        }
                        Text { text: "Titan Wallpaper Engine"; font.pixelSize: 12; font.weight: Font.Bold; color: "#C084FC"; Layout.fillWidth: true }

                        Rectangle {
                            implicitWidth: 70
                            implicitHeight: 22
                            radius: 4
                            color: Qt.rgba(0.8, 0.3, 0.9, 0.3)
                            border.color: "#C084FC"
                            Text { anchors.centerIn: parent; text: "Try Now ❯"; font.pixelSize: 9; font.weight: Font.Bold; color: "#FFFFFF" }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof tourCtrl !== "undefined") tourCtrl.launchWallpaperPicker()
                                }
                            }
                        }
                    }

                    Text {
                        text: "Curated 4K obsidian, cosmic, and sapphire wallpapers with automatic system palette extraction and adaptive glass blur."
                        font.pixelSize: 10
                        color: "#94A3B8"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Feature 3: Titan Sandbox
            GlowingCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    RowLayout {
                        spacing: 8
                        Rectangle {
                            width: 28; height: 28; radius: 6
                            color: Qt.rgba(0.1, 0.8, 0.4, 0.25)
                            border.color: "#34D399"
                            Text { anchors.centerIn: parent; text: "🛡️"; font.pixelSize: 13 }
                        }
                        Text { text: "Titan Sandbox Isolation"; font.pixelSize: 12; font.weight: Font.Bold; color: "#34D399" }
                    }

                    Text {
                        text: "Run unverified third-party binaries, browser plugins, or test scripts inside bubblewrap namespace sandboxes with restricted network and filesystem access."
                        font.pixelSize: 10
                        color: "#94A3B8"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Feature 4: Dynamic HUD & Waybar
            GlowingCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    RowLayout {
                        spacing: 8
                        Rectangle {
                            width: 28; height: 28; radius: 6
                            color: Qt.rgba(0.95, 0.6, 0.1, 0.25)
                            border.color: "#FBBF24"
                            Text { anchors.centerIn: parent; text: "⚡"; font.pixelSize: 13 }
                        }
                        Text { text: "Contextual Media & Telemetry HUD"; font.pixelSize: 12; font.weight: Font.Bold; color: "#FBBF24" }
                    }

                    Text {
                        text: "Dynamic Island-style popups for song transitions, volume/brightness steps, and live GPU/CPU utilization in Waybar."
                        font.pixelSize: 10
                        color: "#94A3B8"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}

