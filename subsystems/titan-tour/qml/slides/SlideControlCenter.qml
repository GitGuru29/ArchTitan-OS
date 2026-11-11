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
                text: "CONTROL CENTER & HOT CORNERS"
                font.pixelSize: 18
                font.weight: Font.Black
                font.letterSpacing: 1.5
                color: "#F8FAFC"
                font.family: "Inter, sans-serif"
            }
            Text {
                text: "Your central cockpit for hardware toggles, media controls, and instant screen-edge hot zones."
                font.pixelSize: 11
                color: "#94A3B8"
            }
        }

        // Two Column Hero Layout
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // Left Column: Interactive Mini Control Center Bento Card
            GlowingCard {
                Layout.preferredWidth: 320
                Layout.fillHeight: true
                interactive: false

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Text { text: "⚡ TITAN CONTROL CENTER"; font.pixelSize: 10; font.weight: Font.Bold; color: "#38BDF8"; Layout.fillWidth: true }
                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            color: "#10B981"
                        }
                    }

                    // Mini Connectivity Box
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 10
                        color: Qt.rgba(0.12, 0.16, 0.22, 0.9)
                        border.color: Qt.rgba(1, 1, 1, 0.1)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Rectangle {
                                width: 34
                                height: 34
                                radius: 8
                                color: "#0284C7"
                                Text { anchors.centerIn: parent; text: "📶"; font.pixelSize: 14 }
                            }
                            ColumnLayout {
                                spacing: 1
                                Text { text: "ArchTitan-5G"; font.pixelSize: 11; font.weight: Font.Bold; color: "#F8FAFC" }
                                Text { text: "Connected • 520 Mbps"; font.pixelSize: 9; color: "#38BDF8" }
                            }
                        }
                    }

                    // Mini Interactive Sliders (Brightness & Volume)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // Display Slider
                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: 8
                            color: Qt.rgba(0.12, 0.16, 0.22, 0.9)
                            border.color: Qt.rgba(1, 1, 1, 0.1)

                            Rectangle {
                                width: parent.width * 0.85
                                height: parent.height
                                radius: 8
                                color: "#0EA5E9"
                            }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                Text { text: "☀️ Display Brightness"; font.pixelSize: 10; font.weight: Font.DemiBold; color: "#FFFFFF" }
                                Item { Layout.fillWidth: true }
                                Text { text: "85%"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                            }
                        }

                        // Sound Slider
                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: 8
                            color: Qt.rgba(0.12, 0.16, 0.22, 0.9)
                            border.color: Qt.rgba(1, 1, 1, 0.1)

                            Rectangle {
                                width: parent.width * 0.65
                                height: parent.height
                                radius: 8
                                color: "#0EA5E9"
                            }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                Text { text: "🔊 Master Volume"; font.pixelSize: 10; font.weight: Font.DemiBold; color: "#FFFFFF" }
                                Item { Layout.fillWidth: true }
                                Text { text: "65%"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                            }
                        }
                    }

                    // Stepped Bottleneck Preview Dock (5 utility icons)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 10
                        color: Qt.rgba(0.12, 0.16, 0.22, 0.9)
                        border.color: Qt.rgba(1, 1, 1, 0.1)

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 12
                            Text { text: "✂️"; font.pixelSize: 12 }
                            Text { text: "📸"; font.pixelSize: 12 }
                            Text { text: "🎥"; font.pixelSize: 12 }
                            Text { text: "✒️"; font.pixelSize: 12 }
                            Text { text: "☕"; font.pixelSize: 12 }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Live Trigger Button
                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 8
                        color: openCcHover.containsMouse ? "#0284C7" : Qt.rgba(0.05, 0.65, 1.0, 0.25)
                        border.color: "#38BDF8"
                        border.width: 1

                        Text { anchors.centerIn: parent; text: "Open Full Control Center ❯"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            id: openCcHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof tourCtrl !== "undefined") tourCtrl.toggleControlCenter()
                            }
                        }
                    }
                }
            }

            // Right Column: Hot Zones & Gestures Guide
            GlowingCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: "RADAR: ACTIVE SCREEN EDGES"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                        color: "#38BDF8"
                    }

                    // Screen outline graphic
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 120
                        radius: 8
                        color: Qt.rgba(0.04, 0.06, 0.10, 0.9)
                        border.color: Qt.rgba(1, 1, 1, 0.2)
                        border.width: 1

                        // Top-Right Hotzone Radar Blip
                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            width: 36
                            height: 36
                            radius: 4
                            color: Qt.rgba(0.05, 0.65, 1.0, 0.45)
                            border.color: "#38BDF8"

                            Text { anchors.centerIn: parent; text: "↗"; font.pixelSize: 16; font.weight: Font.Bold; color: "#FFFFFF" }
                        }

                        // Bottom-Right Hotzone Radar Blip
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            width: 36
                            height: 36
                            radius: 4
                            color: Qt.rgba(0.9, 0.4, 0.1, 0.45)
                            border.color: "#FB923C"

                            Text { anchors.centerIn: parent; text: "↘"; font.pixelSize: 16; font.weight: Font.Bold; color: "#FFFFFF" }
                        }

                        // Top-Left Hotzone Radar Blip
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            width: 36
                            height: 36
                            radius: 4
                            color: Qt.rgba(0.4, 0.2, 0.9, 0.45)
                            border.color: "#A78BFA"

                            Text { anchors.centerIn: parent; text: "↖"; font.pixelSize: 16; font.weight: Font.Bold; color: "#FFFFFF" }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Flick cursor to any corner trigger"
                            font.pixelSize: 10
                            color: "#64748B"
                        }
                    }

                    // Legend explanation
                    ColumnLayout {
                        spacing: 6
                        RowLayout {
                            spacing: 8
                            Rectangle { width: 8; height: 8; radius: 4; color: "#38BDF8" }
                            Text { text: "Top-Right ↗ : Snap open Titan Control Center"; font.pixelSize: 10; color: "#E2E8F0" }
                        }
                        RowLayout {
                            spacing: 8
                            Rectangle { width: 8; height: 8; radius: 4; color: "#FB923C" }
                            Text { text: "Bottom-Right ↘ : Slide in Notification Center"; font.pixelSize: 10; color: "#E2E8F0" }
                        }
                        RowLayout {
                            spacing: 8
                            Rectangle { width: 8; height: 8; radius: 4; color: "#A78BFA" }
                            Text { text: "Top-Left ↖ : Open Workspace Overview & Matrix"; font.pixelSize: 10; color: "#E2E8F0" }
                        }
                    }
                }
            }
        }
    }
}
