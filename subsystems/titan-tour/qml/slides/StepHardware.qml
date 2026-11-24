import QtQuick
import QtQuick.Layouts
import "../components"

Item {
    id: root
    signal finishRequested()
    signal startCoachAt(int coachStepIdx)

    readonly property var profiles: [
        {
            id: "power-saver",
            title: "Low Power",
            badge: "Quiet & Cool",
            spec: "Target: Max Battery • Silent Acoustics",
            icon: "\uf06c",
            accentColor: "#30D158",
            desc: "Reduces energy consumption and fan acoustics to maximize battery life during everyday tasks."
        },
        {
            id: "balanced",
            title: "Automatic",
            badge: "Recommended",
            spec: "Target: 25ms CFS Headroom • 60–144 Hz",
            icon: "\uf24e",
            accentColor: "#0A84FF",
            desc: "Intelligently adapts CPU and memory priority so your active window stays smooth under any load."
        },
        {
            id: "performance",
            title: "High Performance",
            badge: "Max Boost",
            spec: "Target: Peak Turbo Clocks • Full GPU",
            icon: "\uf0e7",
            accentColor: "#FF9F0A",
            desc: "Sustains peak processor and graphics clock speeds for heavy compilation and intensive workloads."
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12

        // ── Top 60fps Animated THM v3 Slice Protection Stage ────────────────
        MotionStage {
            Layout.fillWidth: true
            Layout.preferredHeight: 118
            chapterIndex: 7
        }

        // ── Editorial Title & "Summon Sysmon" Action ────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    text: "INTELLIGENCE & CARE • CHAPTER 8"
                    color: "#30D158"
                    font.family: "Inter"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.6
                }
                Text {
                    text: "Hardware Guard (THM v3) & Energy Mode"
                    color: "#FFFFFF"
                    font.family: "Inter"; font.pixelSize: 20; font.weight: Font.Bold
                }
            }

            Rectangle {
                implicitHeight: 30
                implicitWidth: sysRow.implicitWidth + 16
                radius: 7
                color: sysArea.containsMouse ? "#383840" : "#2A2A30"
                border.width: 1; border.color: "#30D158"
                Row {
                    id: sysRow; anchors.centerIn: parent; spacing: 6
                    Text { text: "\uf080"; color: "#30D158"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Open System Monitor (⌘ M)"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 11; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea {
                    id: sysArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: tourCtrl.toggleSysmon()
                }
            }
        }

        // ── Middle Card: macOS "About This Mac" Style System Overview Card ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 88
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.10)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 16

                Rectangle {
                    width: 50; height: 50; radius: 12
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#1E3A8A" }
                        GradientStop { position: 1.0; color: "#0B1120" }
                    }
                    border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.25)
                    Image {
                        anchors.centerIn: parent; width: 28; height: 28
                        source: tourCtrl.logoUrl; fillMode: Image.PreserveAspectFit; mipmap: true
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: 148
                    spacing: 2
                    Text { text: "ArchTitan OS"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 15; font.weight: Font.Bold }
                    Text { text: tourCtrl.isLiveMode ? "Live USB Media" : "Release 2026.11 • 64-bit"; color: "#98989D"; font.family: "Inter"; font.pixelSize: 11 }
                    Text { text: "✓ 25ms CFS Guard Active"; color: "#30D158"; font.family: "Inter"; font.pixelSize: 10; font.weight: Font.Bold }
                }

                Rectangle {
                    width: 1; Layout.fillHeight: true; Layout.topMargin: 12; Layout.bottomMargin: 12
                    color: Qt.rgba(1, 1, 1, 0.09)
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 6

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { text: "Processor"; color: "#8E8E93"; font.family: "Inter"; font.pixelSize: 10 }
                        Text { text: tourCtrl.cpuName; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 11; font.weight: 600; elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    ColumnLayout {
                        Layout.preferredWidth: 145; spacing: 0
                        Text { text: "Memory"; color: "#8E8E93"; font.family: "Inter"; font.pixelSize: 10 }
                        Text { text: tourCtrl.ramTotal; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 11; font.weight: 600 }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { text: "Graphics"; color: "#8E8E93"; font.family: "Inter"; font.pixelSize: 10 }
                        Text { text: tourCtrl.gpuName; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 11; font.weight: 600; elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    ColumnLayout {
                        Layout.preferredWidth: 145; spacing: 0
                        Text { text: "Kernel"; color: "#8E8E93"; font.family: "Inter"; font.pixelSize: 10 }
                        Text { text: tourCtrl.kernelVersion; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 11; font.weight: 600; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                }
            }
        }

        // ── Lower: 3-Way macOS Energy Mode Selector ─────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Repeater {
                model: root.profiles

                Rectangle {
                    id: profCard
                    property bool isSelected: tourCtrl.activeProfile === modelData.id
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12

                    color: isSelected ? Qt.rgba(10/255, 132/255, 255/255, 0.16)
                                      : (profMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08)
                                                                 : Qt.rgba(1, 1, 1, 0.045))
                    border.width: isSelected ? 2 : 1
                    border.color: isSelected ? "#0A84FF" : Qt.rgba(1, 1, 1, 0.09)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                width: 28; height: 28; radius: 7
                                color: modelData.accentColor
                                border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.25)
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: "#FFFFFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                                }
                            }

                            ColumnLayout {
                                spacing: 0
                                Text { text: modelData.title; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600 }
                                Text { text: modelData.badge; color: profCard.isSelected ? "#64D2FF" : "#8E8E93"; font.family: "Inter"; font.pixelSize: 10; font.weight: 600 }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                width: 16; height: 16; radius: 8
                                color: profCard.isSelected ? "#0A84FF" : "transparent"
                                border.width: 2
                                border.color: profCard.isSelected ? "#0A84FF" : "#636366"
                                Rectangle {
                                    visible: profCard.isSelected
                                    anchors.centerIn: parent; width: 6; height: 6; radius: 3; color: "#FFFFFF"
                                }
                            }
                        }

                        Text {
                            text: modelData.desc
                            color: "#98989D"; font.family: "Inter"; font.pixelSize: 11; lineHeight: 1.25
                            Layout.fillWidth: true; Layout.fillHeight: true; wrapMode: Text.WordWrap
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 20; radius: 5
                            color: Qt.rgba(0, 0, 0, 0.22)
                            Text {
                                anchors.centerIn: parent
                                text: modelData.spec
                                color: profCard.isSelected ? "#D1D1D6" : "#8E8E93"
                                font.family: "Inter"; font.pixelSize: 9; font.weight: 500
                            }
                        }
                    }

                    MouseArea {
                        id: profMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: tourCtrl.activeProfile = modelData.id
                    }
                }
            }
        }

        // ── Bottom Quick Launch & Finish Bar ────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: [
                    { label: "Terminal",   icon: "\uf120", col: "#30D158", fn: function() { tourCtrl.launchTerminal(); } },
                    { label: "Browser",    icon: "\uf268", col: "#0A84FF", fn: function() { tourCtrl.launchBrowser(); } },
                    { label: "Settings",   icon: "\uf013", col: "#AEAEB2", fn: function() { tourCtrl.launchSettings(); } }
                ]

                Rectangle {
                    implicitHeight: 32
                    implicitWidth: actRow.implicitWidth + 18
                    radius: 8
                    color: actMouse.containsMouse ? "#38383D" : "#2A2A2E"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.14)

                    Row {
                        id: actRow; anchors.centerIn: parent; spacing: 6
                        Text { text: modelData.icon; color: modelData.col; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: modelData.label; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 11; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                    }

                    MouseArea {
                        id: actMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.fn()
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Finish & Start Using ArchTitan Button
            Rectangle {
                implicitHeight: 34
                implicitWidth: 156
                radius: 8
                gradient: Gradient {
                    GradientStop { position: 0.0; color: finArea.containsMouse ? "#2894FF" : "#188BFF" }
                    GradientStop { position: 1.0; color: finArea.containsMouse ? "#0A84FF" : "#007AFF" }
                }
                border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.25)

                Row {
                    anchors.centerIn: parent; spacing: 6
                    Text { text: "Get Started"; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 13; font.weight: Font.Bold }
                    Text { text: "\uf00c"; color: "#FFFFFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                }

                MouseArea {
                    id: finArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.finishRequested()
                }
            }
        }
    }
}
