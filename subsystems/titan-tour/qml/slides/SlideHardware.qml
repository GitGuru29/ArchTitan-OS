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
                text: "TITAN HARDWARE MANAGER (THM v3)"
                font.pixelSize: 18
                font.weight: Font.Black
                font.letterSpacing: 1.5
                color: "#F8FAFC"
                font.family: "Inter, sans-serif"
            }
            Text {
                text: "Real-time process tree tracking, kernel PSI telemetry, and instant power profiles."
                font.pixelSize: 11
                color: "#94A3B8"
            }
        }

        // Hardware Identity Strip
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 10
            color: Qt.rgba(0.06, 0.08, 0.13, 0.85)
            border.color: Qt.rgba(1, 1, 1, 0.12)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 20

                RowLayout {
                    spacing: 6
                    Text { text: "💻"; font.pixelSize: 13 }
                    Text {
                        text: (typeof tourCtrl !== "undefined") ? tourCtrl.cpuName : "Intel / AMD Processor"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: "#E2E8F0"
                        elide: Text.ElideRight
                    }
                }

                RowLayout {
                    spacing: 6
                    Text { text: "🧠"; font.pixelSize: 13 }
                    Text {
                        text: (typeof tourCtrl !== "undefined") ? tourCtrl.ramTotal : "16 GB RAM"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: "#38BDF8"
                    }
                }

                RowLayout {
                    spacing: 6
                    Text { text: "🎮"; font.pixelSize: 13 }
                    Text {
                        text: (typeof tourCtrl !== "undefined") ? tourCtrl.gpuName : "Accelerated Graphics"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: "#A78BFA"
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Two Column Performance Cockpit
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // Left: Performance Mode Selector
            GlowingCard {
                Layout.preferredWidth: 340
                Layout.fillHeight: true
                interactive: false

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Text {
                        text: "SELECT PERFORMANCE PROFILE"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 0.8
                        color: "#38BDF8"
                    }

                    // Profile 1: Efficiency
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 8
                        color: (typeof tourCtrl !== "undefined" && tourCtrl.activeProfile === "efficiency")
                               ? Qt.rgba(0.06, 0.35, 0.20, 0.5)
                               : Qt.rgba(0.12, 0.15, 0.22, 0.7)
                        border.color: (typeof tourCtrl !== "undefined" && tourCtrl.activeProfile === "efficiency")
                                      ? "#10B981"
                                      : Qt.rgba(1, 1, 1, 0.1)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            Text { text: "🍃 Efficiency Mode"; font.pixelSize: 11; font.weight: Font.Bold; color: "#34D399"; Layout.fillWidth: true }
                            Text { text: "Silent Fans • Max Battery"; font.pixelSize: 9; color: "#94A3B8" }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof tourCtrl !== "undefined") tourCtrl.activeProfile = "efficiency"
                            }
                        }
                    }

                    // Profile 2: Balanced
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 8
                        color: (typeof tourCtrl !== "undefined" && tourCtrl.activeProfile === "balanced")
                               ? Qt.rgba(0.05, 0.30, 0.55, 0.5)
                               : Qt.rgba(0.12, 0.15, 0.22, 0.7)
                        border.color: (typeof tourCtrl !== "undefined" && tourCtrl.activeProfile === "balanced")
                                      ? "#0EA5E9"
                                      : Qt.rgba(1, 1, 1, 0.1)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            Text { text: "⚖️ Balanced Mode"; font.pixelSize: 11; font.weight: Font.Bold; color: "#38BDF8"; Layout.fillWidth: true }
                            Text { text: "Dynamic Scaling • Optimal"; font.pixelSize: 9; color: "#94A3B8" }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof tourCtrl !== "undefined") tourCtrl.activeProfile = "balanced"
                            }
                        }
                    }

                    // Profile 3: Performance
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 8
                        color: (typeof tourCtrl !== "undefined" && tourCtrl.activeProfile === "performance")
                               ? Qt.rgba(0.4, 0.15, 0.6, 0.5)
                               : Qt.rgba(0.12, 0.15, 0.22, 0.7)
                        border.color: (typeof tourCtrl !== "undefined" && tourCtrl.activeProfile === "performance")
                                      ? "#A855F7"
                                      : Qt.rgba(1, 1, 1, 0.1)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            Text { text: "🚀 Performance Mode"; font.pixelSize: 11; font.weight: Font.Bold; color: "#C084FC"; Layout.fillWidth: true }
                            Text { text: "Uncapped • Max IPC"; font.pixelSize: 9; color: "#94A3B8" }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof tourCtrl !== "undefined") tourCtrl.activeProfile = "performance"
                            }
                        }
                    }
                }
            }

            // Right: Memory Pressure & PSI Guard
            GlowingCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: "PRESSURE STALL INFORMATION (PSI)"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 0.8
                        color: "#34D399"
                    }

                    Text {
                        text: "Unlike traditional Linux systems that lock up under heavy memory starvation, THM v3 actively monitors kernel memory pressure stalls (PSI)."
                        font.pixelSize: 10
                        color: "#94A3B8"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    // Visual Pressure Meter
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 6
                        color: Qt.rgba(0.04, 0.06, 0.10, 0.9)
                        border.color: Qt.rgba(1, 1, 1, 0.12)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            Text { text: "Memory Pressure Stall:"; font.pixelSize: 10; color: "#64748B" }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 8
                                radius: 4
                                color: Qt.rgba(1, 1, 1, 0.1)

                                Rectangle {
                                    width: parent.width * 0.12
                                    height: parent.height
                                    radius: 4
                                    color: "#10B981"
                                }
                            }
                            Text { text: "0.0% (Optimal)"; font.pixelSize: 10; font.weight: Font.Bold; color: "#34D399" }
                        }
                    }

                    Text {
                        text: "• Classified Workloads: Background compilers, dev builds, and VMs are managed safely.\n• Observed Workloads: UI, audio, and active games remain 100% untouched."
                        font.pixelSize: 10
                        color: "#E2E8F0"
                        lineHeight: 1.3
                    }
                }
            }
        }
    }
}

