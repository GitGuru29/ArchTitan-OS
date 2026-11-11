import QtQuick
import QtQuick.Layouts
import "../components"

Item {
    id: slideRoot

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 20

        // ── Hero Holographic Section ────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 180

            // Ambient background glow
            Rectangle {
                anchors.centerIn: parent
                width: 220
                height: 140
                radius: 70
                color: Qt.rgba(0.05, 0.65, 1.0, 0.18)
            }

            // Orbital Ring 1 (Rotating)
            Rectangle {
                id: ring1
                anchors.centerIn: parent
                width: 140
                height: 140
                radius: 70
                color: "transparent"
                border.color: Qt.rgba(0.05, 0.65, 1.0, 0.35)
                border.width: 1

                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 16000
                    loops: Animation.Infinite
                }

                // Orbital Particle
                Rectangle {
                    x: 66
                    y: -4
                    width: 8
                    height: 8
                    radius: 4
                    color: "#38BDF8"
                }
            }

            // Orbital Ring 2 (Counter-rotating)
            Rectangle {
                id: ring2
                anchors.centerIn: parent
                width: 170
                height: 170
                radius: 85
                color: "transparent"
                border.color: Qt.rgba(0.4, 0.2, 0.9, 0.25)
                border.width: 1

                RotationAnimation on rotation {
                    from: 360
                    to: 0
                    duration: 22000
                    loops: Animation.Infinite
                }

                Rectangle {
                    x: 81
                    y: -4
                    width: 6
                    height: 6
                    radius: 3
                    color: "#818CF8"
                }
            }

            // Central Glowing Logo Badge
            Rectangle {
                anchors.centerIn: parent
                width: 90
                height: 90
                radius: 26
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "#0284C7" }
                    GradientStop { position: 0.6; color: "#0F172A" }
                    GradientStop { position: 1.0; color: "#020617" }
                }
                border.color: "#38BDF8"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "⚡"
                    font.pixelSize: 42
                }
            }
        }

        // ── Typography ──────────────────────────────────────────────────────
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "A NEW ERA OF LINUX COMPUTING"
                font.pixelSize: 20
                font.weight: Font.Black
                font.letterSpacing: 2.0
                color: "#F8FAFC"
                font.family: "Inter, sans-serif"
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Welcome to ArchTitan OS. Forged for raw speed, low latency, and breathtaking cinematic design."
                font.pixelSize: 12
                color: "#94A3B8"
                font.family: "Inter, sans-serif"
            }
        }

        // ── 3 Pillar Feature Cards ──────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            GlowingCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    Text { text: "⚡ High Velocity"; font.pixelSize: 12; font.weight: Font.Bold; color: "#38BDF8" }
                    Text {
                        text: "Hyprland Wayland compositor paired with native C++20 daemons and Zen kernel optimizations for razor-sharp response."
                        font.pixelSize: 10
                        color: "#94A3B8"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            GlowingCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    Text { text: "💎 Sapphire Glass"; font.pixelSize: 12; font.weight: Font.Bold; color: "#818CF8" }
                    Text {
                        text: "Obsidian dark glass styling, rounded squircles, smooth cubic bezier animations, and seamless dark mode."
                        font.pixelSize: 10
                        color: "#94A3B8"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            GlowingCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    Text { text: "🛡️ Hardened & Tuned"; font.pixelSize: 12; font.weight: Font.Bold; color: "#34D399" }
                    Text {
                        text: "Integrated Titan Hardware Manager v3, memory pressure safety, and one-click application container sandboxing."
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

