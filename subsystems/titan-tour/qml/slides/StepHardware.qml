import QtQuick
import QtQuick.Layouts

Item {
    id: root

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
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        spacing: 12

        // ── Centered macOS Title ────────────────────────────────────────────
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Your System, Tuned & Ready"
                color: "#F5F5F7"
                font.family: "Inter"
                font.pixelSize: 22
                font.weight: Font.Bold
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Review your machine specifications and select an adaptive energy mode for your workflow."
                color: "#98989D"
                font.family: "Inter"
                font.pixelSize: 12
            }
        }

        // ── Upper Card: macOS "About This Mac" Style System Overview Card ───
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 108
            radius: 14
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.10)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 18

                // Workstation Squircle Icon
                Rectangle {
                    width: 60
                    height: 60
                    radius: 15
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#1E3A8A" }
                        GradientStop { position: 0.5; color: "#172554" }
                        GradientStop { position: 1.0; color: "#0B1120" }
                    }
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.25)

                    Image {
                        anchors.centerIn: parent
                        width: 34
                        height: 34
                        source: tourCtrl.logoUrl
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                    }
                }

                // OS Brand Title & Status Pill
                ColumnLayout {
                    Layout.preferredWidth: 162
                    spacing: 4

                    Text {
                        text: "ArchTitan OS"
                        color: "#F5F5F7"
                        font.family: "Inter"
                        font.pixelSize: 17
                        font.weight: Font.Bold
                    }

                    Text {
                        text: tourCtrl.isLiveMode ? "Live USB Environment" : "Release 2026.11 • 64-bit"
                        color: "#98989D"
                        font.family: "Inter"
                        font.pixelSize: 11
                    }

                    Rectangle {
                        implicitHeight: 18
                        implicitWidth: thmTag.implicitWidth + 10
                        radius: 9
                        color: Qt.rgba(48/255, 209/255, 88/255, 0.16)
                        border.width: 1
                        border.color: "#30D158"
                        Text {
                            id: thmTag
                            anchors.centerIn: parent
                            text: "✓ THM v3 Guard Active"
                            color: "#30D158"
                            font.family: "Inter"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }
                }

                Rectangle {
                    width: 1
                    Layout.fillHeight: true
                    Layout.topMargin: 16
                    Layout.bottomMargin: 16
                    color: Qt.rgba(1, 1, 1, 0.09)
                }

                // 2x2 Apple Hardware Spec Grid
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 18
                    rowSpacing: 10

                    // Processor
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text { text: "Processor"; color: "#8E8E93"; font.family: "Inter"; font.pixelSize: 10 }
                        Text { text: tourCtrl.cpuName; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600; elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    // Memory
                    ColumnLayout {
                        Layout.preferredWidth: 155
                        spacing: 1
                        Text { text: "Memory"; color: "#8E8E93"; font.family: "Inter"; font.pixelSize: 10 }
                        Text { text: tourCtrl.ramTotal; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600 }
                    }

                    // Graphics
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text { text: "Graphics"; color: "#8E8E93"; font.family: "Inter"; font.pixelSize: 10 }
                        Text { text: tourCtrl.gpuName; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600; elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    // Kernel
                    ColumnLayout {
                        Layout.preferredWidth: 155
                        spacing: 1
                        Text { text: "Kernel"; color: "#8E8E93"; font.family: "Inter"; font.pixelSize: 10 }
                        Text { text: tourCtrl.kernelVersion; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                }
            }
        }

        // ── Middle: macOS Energy Mode Selector (3 Cards) ────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

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

                    Behavior on color { ColorAnimation { duration: 140 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 8
                                color: modelData.accentColor
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.25)
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: "#FFFFFF"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                }
                            }

                            ColumnLayout {
                                spacing: 1
                                Text {
                                    text: modelData.title
                                    color: "#F5F5F7"
                                    font.family: "Inter"
                                    font.pixelSize: 13
                                    font.weight: 600
                                }
                                Text {
                                    text: modelData.badge
                                    color: profCard.isSelected ? "#64D2FF" : "#8E8E93"
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    font.weight: 600
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // macOS Radio Indicator
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: profCard.isSelected ? "#0A84FF" : "transparent"
                                border.width: 2
                                border.color: profCard.isSelected ? "#0A84FF" : "#636366"

                                Rectangle {
                                    visible: profCard.isSelected
                                    anchors.centerIn: parent
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: "#FFFFFF"
                                }
                            }
                        }

                        Text {
                            text: modelData.desc
                            color: "#98989D"
                            font.family: "Inter"
                            font.pixelSize: 11
                            lineHeight: 1.3
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            wrapMode: Text.WordWrap
                        }

                        // Bottom Technical Spec Pill
                        Rectangle {
                            Layout.fillWidth: true
                            height: 22
                            radius: 6
                            color: Qt.rgba(0, 0, 0, 0.22)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.06)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.spec
                                color: profCard.isSelected ? "#D1D1D6" : "#8E8E93"
                                font.family: "Inter"
                                font.pixelSize: 10
                                font.weight: 500
                            }
                        }
                    }

                    MouseArea {
                        id: profMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tourCtrl.activeProfile = modelData.id
                    }
                }
            }
        }

        // ── Bottom Quick Launch Bar ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 44
            radius: 10
            color: Qt.rgba(1, 1, 1, 0.045)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: "Quick Launch:"
                    color: "#98989D"
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: 600
                }

                Item { Layout.fillWidth: true }

                Repeater {
                    model: [
                        { label: "Open Terminal",   icon: "\uf120", col: "#30D158", fn: function() { tourCtrl.launchTerminal(); } },
                        { label: "Web Browser",     icon: "\uf268", col: "#0A84FF", fn: function() { tourCtrl.launchBrowser(); } },
                        { label: "System Settings", icon: "\uf013", col: "#AEAEB2", fn: function() { tourCtrl.launchSettings(); } }
                    ]

                    Rectangle {
                        implicitHeight: 28
                        implicitWidth: actRow.implicitWidth + 18
                        radius: 7
                        color: actMouse.containsMouse ? "#38383D" : "#2A2A2E"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.14)

                        Row {
                            id: actRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: modelData.icon
                                color: modelData.col
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.label
                                color: "#F5F5F7"
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.weight: 600
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: actMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.fn()
                        }
                    }
                }
            }
        }
    }
}
