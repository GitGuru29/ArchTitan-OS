import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property var profiles: [
        {
            id: "power-saver",
            title: "Low Power",
            badge: "Quiet & Cool",
            icon: "\uf06c",
            accentColor: "#30D158",
            desc: "Reduces energy consumption and fan acoustics to maximize battery life during everyday tasks."
        },
        {
            id: "balanced",
            title: "Automatic",
            badge: "Recommended",
            icon: "\uf24e",
            accentColor: "#0A84FF",
            desc: "Intelligently adapts CPU and memory priority so your active window stays smooth under any load."
        },
        {
            id: "performance",
            title: "High Performance",
            badge: "Max Boost",
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
                text: "Review your machine specifications and select an energy mode for your workflow."
                color: "#98989D"
                font.family: "Inter"
                font.pixelSize: 12
            }
        }

        // ── Upper Card: macOS "About This Mac" Style System Overview Card ───
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 96
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.045)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 18

                // Workstation Squircle Icon
                Rectangle {
                    width: 54
                    height: 54
                    radius: 13
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#2C3E50" }
                        GradientStop { position: 1.0; color: "#1A252F" }
                    }
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.20)

                    Image {
                        anchors.centerIn: parent
                        width: 30
                        height: 30
                        source: tourCtrl.logoUrl
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                    }
                }

                // OS Brand Title
                ColumnLayout {
                    Layout.preferredWidth: 165
                    spacing: 2

                    Text {
                        text: "ArchTitan OS"
                        color: "#F5F5F7"
                        font.family: "Inter"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }

                    Text {
                        text: tourCtrl.isLiveMode ? "Live USB Environment" : "Release 2026.11 • 64-bit"
                        color: "#98989D"
                        font.family: "Inter"
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    width: 1
                    Layout.fillHeight: true
                    Layout.topMargin: 14
                    Layout.bottomMargin: 14
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                // 2x2 Apple Hardware Spec Grid
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 20
                    rowSpacing: 8

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

                    color: isSelected ? Qt.rgba(10/255, 132/255, 255/255, 0.14)
                                      : (profMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.075)
                                                                 : Qt.rgba(1, 1, 1, 0.04))
                    border.width: isSelected ? 2 : 1
                    border.color: isSelected ? "#0A84FF" : Qt.rgba(1, 1, 1, 0.08)

                    Behavior on color { ColorAnimation { duration: 140 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                width: 30
                                height: 30
                                radius: 7
                                color: modelData.accentColor
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: "#FFFFFF"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
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
                                    font.weight: 500
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
            color: Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.07)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: "Quick Actions:"
                    color: "#98989D"
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: 500
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
                                font.weight: 500
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
