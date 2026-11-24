import QtQuick
import QtQuick.Layouts
import "../components"

Item {
    id: root

    property int selectedZone: 0

    readonly property var zones: [
        {
            title: "Spotlight Search",
            subtitle: "Launch apps & search files",
            shortcut: "⌘ Super + Space",
            keys: ["SUPER", "SPACE"],
            icon: "\uf002",
            accentColor: "#0A84FF",
            desc: "Press Super + Space from anywhere to summon Spotlight at the center of your display for instant app launching, file lookup, and quick calculations.",
            actionText: "Try Spotlight Live",
            trigger: function() { tourCtrl.toggleSpotlight(); }
        },
        {
            title: "Control Center",
            subtitle: "Wi-Fi, Bluetooth & Audio",
            shortcut: "⌘ Super + N",
            keys: ["SUPER", "N"],
            icon: "\uf1de",
            accentColor: "#5E5CE6",
            desc: "Click the top-right status capsule or press Super + N to adjust Wi-Fi, Bluetooth devices, sound output, screen brightness, and power profiles.",
            actionText: "Open Control Center",
            trigger: function() { tourCtrl.toggleControlCenter(); }
        },
        {
            title: "Top Bar & Workspaces",
            subtitle: "App menu & 10 workspaces",
            shortcut: "⌘ Super + 1–9",
            keys: ["SUPER", "1..9"],
            icon: "\uf009",
            accentColor: "#BF5AF2",
            desc: "Your top bar houses the Application Menu on the left, live workspace indicators, a dynamic Now Playing media island in the center, and system status on the right.",
            actionText: "Open App Menu",
            trigger: function() { tourCtrl.toggleMenu(); }
        },
        {
            title: "Focus & System Monitor",
            subtitle: "Focus timer & live telemetry",
            shortcut: "⌘ Super + M",
            keys: ["SUPER", "M"],
            icon: "\uf080",
            accentColor: "#30D158",
            desc: "Monitor live CPU, memory, and thermal headroom with Super + M, or start a distraction-free Pomodoro session from the top edge with Super + Alt + F.",
            actionText: "Open System Monitor",
            trigger: function() { tourCtrl.toggleSysmon(); }
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        anchors.leftMargin: 26
        anchors.rightMargin: 26
        spacing: 12

        // ── Header ──────────────────────────────────────────────────────────
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 3

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Get to Know Your Desktop"
                color: "#F5F5F7"
                font.family: "Inter"
                font.pixelSize: 22
                font.weight: Font.Bold
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Select a feature to preview where it lives on your screen, or click the action button to try it live."
                color: "#98989D"
                font.family: "Inter"
                font.pixelSize: 12
            }
        }

        // ── Main Content: Miniature Mac Display Left + Feature Cards Right ──
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 18

            // ── Left: Realistic Miniature Desktop Screen Preview ────────────
            Rectangle {
                Layout.preferredWidth: 465
                Layout.fillHeight: true
                radius: 14
                color: "#121215"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    // Miniature Display Frame
                    Rectangle {
                        id: miniScreen
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10
                        color: "#0D1526"
                        border.width: 2
                        border.color: Qt.rgba(1, 1, 1, 0.18)
                        clip: true

                        // Real Wallpaper Background inside Mini Screen
                        Image {
                            anchors.fill: parent
                            source: tourCtrl.wallpapers.length > 0 ? tourCtrl.wallpapers[0].url : ""
                            fillMode: Image.PreserveAspectCrop
                            opacity: 0.78
                        }

                        // Subtle vignette over wallpaper
                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(0.03, 0.05, 0.10, 0.45) }
                                GradientStop { position: 0.5; color: Qt.rgba(0.03, 0.05, 0.10, 0.20) }
                                GradientStop { position: 1.0; color: Qt.rgba(0.03, 0.05, 0.10, 0.55) }
                            }
                        }

                        // ── Miniature Top Bar (Waybar Replica) ──────────────
                        Rectangle {
                            id: miniTopBar
                            anchors.top: parent.top
                            anchors.topMargin: 6
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            height: 24
                            radius: 7
                            color: Qt.rgba(0.09, 0.10, 0.13, 0.90)
                            border.width: root.selectedZone === 2 ? 2 : 0.5
                            border.color: root.selectedZone === 2 ? "#BF5AF2" : Qt.rgba(1, 1, 1, 0.15)

                            // Left: App Menu + Workspace Dots
                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Rectangle {
                                    width: 14; height: 14; radius: 4
                                    color: "#0A84FF"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf009"
                                        color: "#FFFFFF"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 8
                                    }
                                }

                                Repeater {
                                    model: 4
                                    Rectangle {
                                        width: index === 0 ? 14 : 5
                                        height: 5
                                        radius: 2.5
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: index === 0 ? "#64D2FF" : Qt.rgba(1, 1, 1, 0.30)
                                    }
                                }
                            }

                            // Center: Dynamic Media Island
                            Rectangle {
                                anchors.centerIn: parent
                                width: 108
                                height: 16
                                radius: 8
                                color: Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.14)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 5
                                    Text {
                                        text: "\uf001"
                                        color: "#BF5AF2"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 8
                                    }
                                    Text {
                                        text: "Solaris • 12:45"
                                        color: "#F5F5F7"
                                        font.family: "Inter"
                                        font.pixelSize: 8
                                        font.weight: 600
                                    }
                                }
                            }

                            // Right: Status Tray Capsule
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                width: 64
                                height: 16
                                radius: 8
                                color: root.selectedZone === 1 ? Qt.rgba(94/255, 92/255, 230/255, 0.35) : Qt.rgba(1, 1, 1, 0.08)
                                border.width: root.selectedZone === 1 ? 1 : 0
                                border.color: "#5E5CE6"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "\uf1eb"; color: "#F5F5F7"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                                    Text { text: "\uf028"; color: "#F5F5F7"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                                    Text { text: "\uf240"; color: "#30D158"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                                }
                            }
                        }

                        // ── SCENE 0: Spotlight Search Mockup (Center) ───────
                        Rectangle {
                            visible: root.selectedZone === 0
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 8
                            width: 265
                            height: 142
                            radius: 11
                            color: Qt.rgba(0.11, 0.12, 0.15, 0.96)
                            border.width: 2
                            border.color: "#0A84FF"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 7

                                // Search Bar Row
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text {
                                        text: "\uf002"
                                        color: "#0A84FF"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                    }
                                    Text {
                                        text: "Spotlight Search…"
                                        color: "#F5F5F7"
                                        font.family: "Inter"
                                        font.pixelSize: 11
                                        font.weight: 600
                                        Layout.fillWidth: true
                                    }
                                    Rectangle {
                                        width: 44; height: 16; radius: 4
                                        color: Qt.rgba(1, 1, 1, 0.08)
                                        Text {
                                            anchors.centerIn: parent
                                            text: "⌘ Space"
                                            color: "#98989D"
                                            font.family: "Inter"
                                            font.pixelSize: 8
                                        }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.08) }

                                // 3 Mockup App Results
                                Repeater {
                                    model: [
                                        { icon: "\uf120", col: "#0A84FF", name: "Kitty Terminal", tag: "Application • Return" },
                                        { icon: "\uf268", col: "#5E5CE6", name: "TitanBrowser", tag: "Web Engine" },
                                        { icon: "\uf013", col: "#30D158", name: "System Settings", tag: "Preferences" }
                                    ]
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 24
                                        radius: 5
                                        color: index === 0 ? Qt.rgba(10/255, 132/255, 255/255, 0.25) : "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 6
                                            anchors.rightMargin: 6
                                            spacing: 7
                                            Rectangle {
                                                width: 16; height: 16; radius: 4
                                                color: modelData.col
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.icon
                                                    color: "#FFFFFF"
                                                    font.family: "JetBrainsMono Nerd Font"
                                                    font.pixelSize: 8
                                                }
                                            }
                                            Text {
                                                text: modelData.name
                                                color: "#F5F5F7"
                                                font.family: "Inter"
                                                font.pixelSize: 9
                                                font.weight: index === 0 ? 600 : 400
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: modelData.tag
                                                color: index === 0 ? "#64D2FF" : "#8E8E93"
                                                font.family: "Inter"
                                                font.pixelSize: 8
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── SCENE 1: macOS Control Center Mockup (Top-Right) ─
                        Rectangle {
                            visible: root.selectedZone === 1
                            anchors.top: miniTopBar.bottom
                            anchors.topMargin: 6
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            width: 196
                            height: 158
                            radius: 12
                            color: Qt.rgba(0.12, 0.12, 0.16, 0.96)
                            border.width: 2
                            border.color: "#5E5CE6"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 7

                                // Top Connectivity Grid
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 44
                                        radius: 8
                                        color: Qt.rgba(1, 1, 1, 0.06)
                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            spacing: 3
                                            Row {
                                                spacing: 5
                                                Rectangle { width: 14; height: 14; radius: 7; color: "#0A84FF"; Text { anchors.centerIn: parent; text: "\uf1eb"; color: "#FFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7 } }
                                                Text { text: "Wi-Fi"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
                                            }
                                            Row {
                                                spacing: 5
                                                Rectangle { width: 14; height: 14; radius: 7; color: "#0A84FF"; Text { anchors.centerIn: parent; text: "\uf293"; color: "#FFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7 } }
                                                Text { text: "Bluetooth"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 74
                                        height: 44
                                        radius: 8
                                        color: Qt.rgba(94/255, 92/255, 230/255, 0.25)
                                        border.width: 1
                                        border.color: "#5E5CE6"
                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 2
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\uf186"; color: "#A78BFA"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Focus"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
                                        }
                                    }
                                }

                                // Display Slider Card
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 32
                                    radius: 7
                                    color: Qt.rgba(1, 1, 1, 0.06)
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 3
                                        Text { text: "Display"; color: "#98989D"; font.family: "Inter"; font.pixelSize: 7; font.weight: 600 }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 8; radius: 4; color: Qt.rgba(1, 1, 1, 0.14)
                                            Rectangle { width: parent.width * 0.78; height: 8; radius: 4; color: "#F5F5F7" }
                                        }
                                    }
                                }

                                // Sound Slider Card
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 32
                                    radius: 7
                                    color: Qt.rgba(1, 1, 1, 0.06)
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 3
                                        Text { text: "Sound • PipeWire"; color: "#98989D"; font.family: "Inter"; font.pixelSize: 7; font.weight: 600 }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 8; radius: 4; color: Qt.rgba(1, 1, 1, 0.14)
                                            Rectangle { width: parent.width * 0.65; height: 8; radius: 4; color: "#0A84FF" }
                                        }
                                    }
                                }
                            }
                        }

                        // ── SCENE 2: Tiled Workspaces Mockup ────────────────
                        RowLayout {
                            visible: root.selectedZone === 2
                            anchors.top: miniTopBar.bottom
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10
                            spacing: 8

                            // Left Tiled Window
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: Qt.rgba(0.10, 0.11, 0.15, 0.92)
                                border.width: 2
                                border.color: "#BF5AF2"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6
                                    Row {
                                        spacing: 5
                                        Rectangle { width: 7; height: 7; radius: 3.5; color: "#FF5F57" }
                                        Rectangle { width: 7; height: 7; radius: 3.5; color: "#FEBC2E" }
                                        Rectangle { width: 7; height: 7; radius: 3.5; color: "#28C840" }
                                        Text { text: "  Code Editor • Workspace 1"; color: "#98989D"; font.family: "Inter"; font.pixelSize: 8 }
                                    }
                                    Rectangle { Layout.fillWidth: true; height: 7; radius: 3; color: Qt.rgba(191/255, 90/255, 242/255, 0.35) }
                                    Rectangle { Layout.preferredWidth: 130; height: 7; radius: 3; color: Qt.rgba(1, 1, 1, 0.12) }
                                    Rectangle { Layout.preferredWidth: 160; height: 7; radius: 3; color: Qt.rgba(10/255, 132/255, 255/255, 0.30) }
                                    Rectangle { Layout.preferredWidth: 110; height: 7; radius: 3; color: Qt.rgba(1, 1, 1, 0.10) }
                                    Item { Layout.fillHeight: true }
                                }
                            }

                            // Right Tiled Window
                            Rectangle {
                                Layout.preferredWidth: 165
                                Layout.fillHeight: true
                                radius: 8
                                color: Qt.rgba(0.08, 0.09, 0.13, 0.92)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.16)

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6
                                    Text { text: "Terminal • Kitty"; color: "#30D158"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
                                    Text { text: "$ titan-hwm status\n✓ PSI Guard: Active\n✓ Headroom: 25ms"; color: "#AEAEB2"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; lineHeight: 1.3 }
                                    Item { Layout.fillHeight: true }
                                }
                            }
                        }

                        // ── SCENE 3: Focus & System Monitor Mockup ──────────
                        Item {
                            visible: root.selectedZone === 3
                            anchors.top: miniTopBar.bottom
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10

                            // Top-Center TitanFocus Pill
                            Rectangle {
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 156
                                height: 26
                                radius: 13
                                color: Qt.rgba(0.10, 0.12, 0.16, 0.95)
                                border.width: 2
                                border.color: "#30D158"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Rectangle { width: 7; height: 7; radius: 3.5; color: "#30D158"; anchors.verticalCenter: parent.verticalCenter }
                                    Text {
                                        text: "Deep Focus • 24:59"
                                        color: "#F5F5F7"
                                        font.family: "Inter"
                                        font.pixelSize: 9
                                        font.weight: 600
                                    }
                                }
                            }

                            // Left-Edge System Monitor Card
                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: 10
                                width: 175
                                height: 122
                                radius: 10
                                color: Qt.rgba(0.10, 0.11, 0.15, 0.95)
                                border.width: 2
                                border.color: "#30D158"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "System Monitor"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 9; font.weight: 600 }
                                        Item { Layout.fillWidth: true }
                                        Text { text: "THM v3"; color: "#30D158"; font.family: "Inter"; font.pixelSize: 8; font.weight: Font.Bold }
                                    }

                                    // CPU Bar
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        RowLayout {
                                            Text { text: "CPU Load"; color: "#98989D"; font.family: "Inter"; font.pixelSize: 8 }
                                            Item { Layout.fillWidth: true }
                                            Text { text: "8%"; color: "#30D158"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 5; radius: 2.5; color: Qt.rgba(1, 1, 1, 0.12)
                                            Rectangle { width: parent.width * 0.22; height: 5; radius: 2.5; color: "#30D158" }
                                        }
                                    }

                                    // Memory Bar
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        RowLayout {
                                            Text { text: "Memory"; color: "#98989D"; font.family: "Inter"; font.pixelSize: 8 }
                                            Item { Layout.fillWidth: true }
                                            Text { text: "1.4 GB"; color: "#0A84FF"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 5; radius: 2.5; color: Qt.rgba(1, 1, 1, 0.12)
                                            Rectangle { width: parent.width * 0.32; height: 5; radius: 2.5; color: "#0A84FF" }
                                        }
                                    }

                                    // PSI Pressure Status
                                    Text {
                                        text: "✓ 25ms CFS Headroom Active"
                                        color: "#30D158"
                                        font.family: "Inter"
                                        font.pixelSize: 8
                                        font.weight: 500
                                    }
                                }
                            }
                        }
                    }

                    // Bottom Mini Caption Bar inside Display Card
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: root.zones[root.selectedZone].desc
                            color: "#98989D"
                            font.family: "Inter"
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // ── Right: 4 macOS Feature Selector Cards + Live Trigger ────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Repeater {
                    model: root.zones

                    Rectangle {
                        id: zoneCard
                        property bool isSel: index === root.selectedZone
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10

                        color: isSel ? Qt.rgba(10/255, 132/255, 255/255, 0.16)
                                     : (zoneMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07)
                                                                : Qt.rgba(1, 1, 1, 0.04))
                        border.width: isSel ? 2 : 1
                        border.color: isSel ? "#0A84FF" : Qt.rgba(1, 1, 1, 0.08)

                        Behavior on color { ColorAnimation { duration: 140 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Rectangle {
                                width: 34
                                height: 34
                                radius: 8
                                color: modelData.accentColor
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: "#FFFFFF"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: modelData.title
                                    color: "#F5F5F7"
                                    font.family: "Inter"
                                    font.pixelSize: 13
                                    font.weight: 600
                                }

                                Text {
                                    text: modelData.subtitle
                                    color: "#98989D"
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Rectangle {
                                implicitHeight: 20
                                implicitWidth: scText.implicitWidth + 10
                                radius: 5
                                color: Qt.rgba(1, 1, 1, 0.07)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.14)
                                Text {
                                    id: scText
                                    anchors.centerIn: parent
                                    text: modelData.shortcut
                                    color: zoneCard.isSel ? "#64D2FF" : "#AEAEB2"
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    font.weight: 600
                                }
                            }
                        }

                        MouseArea {
                            id: zoneMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                tourCtrl.playSound("tap");
                                root.selectedZone = index;
                            }
                        }
                    }
                }

                // Live Test Button at Bottom of Right Column
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: 8
                    color: tryMouse.pressed ? "#2C2C30"
                                            : (tryMouse.containsMouse ? "#38383D" : "#2D2D32")
                    border.width: 1
                    border.color: "#0A84FF"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: root.zones[root.selectedZone].icon
                            color: "#0A84FF"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.zones[root.selectedZone].actionText
                            color: "#F5F5F7"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: 600
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: tryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.zones[root.selectedZone].trigger()
                    }
                }
            }
        }
    }
}
