import QtQuick
import QtQuick.Layouts
import "../components"

Item {
    id: root

    property int selectedZone: 0

    function activeWallpaperUrl() {
        var list = tourCtrl.wallpapers;
        for (var i = 0; i < list.length; i++) {
            if (list[i].path === tourCtrl.selectedWallpaper) return list[i].url;
        }
        return list.length > 0 ? list[0].url : "";
    }

    readonly property var zones: [
        {
            title: "Spotlight Search",
            subtitle: "Launch apps, files & live math",
            shortcut: "⌘ Super + Space",
            keys: ["SUPER", "SPACE"],
            icon: "\uf002",
            accentColor: "#0A84FF",
            desc: "Press Super + Space from anywhere to summon Spotlight at the center of your display for instant app launching, file lookup, and inline calculations.",
            actionText: "Try Spotlight Live",
            trigger: function() { tourCtrl.toggleSpotlight(); }
        },
        {
            title: "Control Center",
            subtitle: "Wi-Fi, Bluetooth, Audio & Display",
            shortcut: "⌘ Super + N",
            keys: ["SUPER", "N"],
            icon: "\uf1de",
            accentColor: "#5E5CE6",
            desc: "Click the top-right status capsule or press Super + N to adjust Wi-Fi, Bluetooth devices, sound output, screen brightness, and power profiles.",
            actionText: "Open Control Center",
            trigger: function() { tourCtrl.toggleControlCenter(); }
        },
        {
            title: "Top Bar & Tiled Workspaces",
            subtitle: "App menu & 10 workspaces",
            shortcut: "⌘ Super + 1–9",
            keys: ["SUPER", "1..9"],
            icon: "\uf009",
            accentColor: "#BF5AF2",
            desc: "Your top bar houses the Application Menu on the left, 10 dynamic workspaces, a live Now Playing media island in the center, and system tray on the right.",
            actionText: "Open App Menu",
            trigger: function() { tourCtrl.toggleMenu(); }
        },
        {
            title: "Focus & System Monitor",
            subtitle: "Zen focus timer & PSI telemetry",
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
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        spacing: 12

        // ── Header ──────────────────────────────────────────────────────────
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2

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
                text: "Click any feature card—or click directly inside the interactive screen preview—to explore your workspace."
                color: "#98989D"
                font.family: "Inter"
                font.pixelSize: 12
            }
        }

        // ── Main Content: Miniature Mac Studio Display Left + Feature Cards Right ──
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // ── Left: Realistic Miniature Apple Studio Display ──────────────
            Rectangle {
                Layout.preferredWidth: 486
                Layout.fillHeight: true
                radius: 14
                color: "#111216"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    // Miniature Display Bezel
                    Rectangle {
                        id: miniScreen
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10
                        color: "#0D1526"
                        border.width: 2
                        border.color: root.zones[root.selectedZone].accentColor
                        clip: true

                        Behavior on border.color { ColorAnimation { duration: 180 } }

                        // Active Wallpaper Background inside Mini Screen
                        Image {
                            anchors.fill: parent
                            source: root.activeWallpaperUrl()
                            fillMode: Image.PreserveAspectCrop
                            opacity: 0.82
                        }

                        // Subtle vignette over wallpaper
                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(0.03, 0.04, 0.09, 0.42) }
                                GradientStop { position: 0.5; color: Qt.rgba(0.03, 0.04, 0.09, 0.18) }
                                GradientStop { position: 1.0; color: Qt.rgba(0.03, 0.04, 0.09, 0.62) }
                            }
                        }

                        // ── Miniature Top Bar (Clickable Waybar Replica) ────
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
                            color: Qt.rgba(0.08, 0.09, 0.13, 0.92)
                            border.width: root.selectedZone === 2 ? 2 : 1
                            border.color: root.selectedZone === 2 ? "#BF5AF2" : Qt.rgba(1, 1, 1, 0.18)

                            // Left: App Menu + Workspace Dots (Click selects Zone 2)
                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Rectangle {
                                    width: 15; height: 15; radius: 4
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
                                        color: index === 0 ? "#64D2FF" : Qt.rgba(1, 1, 1, 0.32)
                                    }
                                }
                            }

                            // Center: Dynamic Media Island
                            Rectangle {
                                anchors.centerIn: parent
                                width: 118
                                height: 16
                                radius: 8
                                color: Qt.rgba(1, 1, 1, 0.09)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.15)

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
                                        text: "Solaris • 12:45 PM"
                                        color: "#F5F5F7"
                                        font.family: "Inter"
                                        font.pixelSize: 8
                                        font.weight: 600
                                    }
                                }
                            }

                            // Right: Status Tray Capsule (Click selects Zone 1)
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                width: 68
                                height: 16
                                radius: 8
                                color: root.selectedZone === 1 ? Qt.rgba(94/255, 92/255, 230/255, 0.40) : Qt.rgba(1, 1, 1, 0.09)
                                border.width: 1
                                border.color: root.selectedZone === 1 ? "#5E5CE6" : Qt.rgba(1, 1, 1, 0.14)

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
                            anchors.verticalCenterOffset: 2
                            width: 284
                            height: 150
                            radius: 12
                            color: Qt.rgba(0.10, 0.11, 0.15, 0.96)
                            border.width: 2
                            border.color: "#0A84FF"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

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
                                        text: "Terminal"
                                        color: "#FFFFFF"
                                        font.family: "Inter"
                                        font.pixelSize: 11
                                        font.weight: 600
                                    }
                                    Rectangle {
                                        width: 1.5; height: 13; color: "#0A84FF"
                                    }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        width: 48; height: 16; radius: 4
                                        color: Qt.rgba(10/255, 132/255, 255/255, 0.18)
                                        border.width: 1
                                        border.color: "#0A84FF"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "⌘ Space"
                                            color: "#64D2FF"
                                            font.family: "Inter"
                                            font.pixelSize: 8
                                            font.weight: 600
                                        }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.10) }

                                // 3 Mockup App Results
                                Repeater {
                                    model: [
                                        { icon: "\uf120", col: "#0A84FF", name: "Kitty Terminal", sub: "GPU Terminal Emulator", tag: "↵ Open" },
                                        { icon: "\uf268", col: "#5E5CE6", name: "TitanBrowser", sub: "Hardware-Accelerated Web", tag: "⌘ 2" },
                                        { icon: "\uf1ec", col: "#30D158", name: "2048 × 64 = 131,072", sub: "Instant Math Evaluation", tag: "Copy" }
                                    ]
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 26
                                        radius: 6
                                        color: index === 0 ? Qt.rgba(10/255, 132/255, 255/255, 0.26) : "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 6
                                            anchors.rightMargin: 6
                                            spacing: 8
                                            Rectangle {
                                                width: 18; height: 18; radius: 5
                                                color: modelData.col
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.icon
                                                    color: "#FFFFFF"
                                                    font.family: "JetBrainsMono Nerd Font"
                                                    font.pixelSize: 8
                                                }
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 0
                                                Text {
                                                    text: modelData.name
                                                    color: "#F5F5F7"
                                                    font.family: "Inter"
                                                    font.pixelSize: 9
                                                    font.weight: 600
                                                }
                                                Text {
                                                    text: modelData.sub
                                                    color: "#8E8E93"
                                                    font.family: "Inter"
                                                    font.pixelSize: 7
                                                }
                                            }
                                            Text {
                                                text: modelData.tag
                                                color: index === 0 ? "#64D2FF" : "#8E8E93"
                                                font.family: "Inter"
                                                font.pixelSize: 8
                                                font.weight: 600
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
                            anchors.topMargin: 5
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            width: 214
                            height: 158
                            radius: 12
                            color: Qt.rgba(0.11, 0.12, 0.16, 0.96)
                            border.width: 2
                            border.color: "#5E5CE6"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 9
                                spacing: 6

                                // Top Connectivity + Now Playing Bento Row
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 48
                                        radius: 8
                                        color: Qt.rgba(1, 1, 1, 0.06)
                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            spacing: 4
                                            Row {
                                                spacing: 5
                                                Rectangle { width: 15; height: 15; radius: 7.5; color: "#0A84FF"; Text { anchors.centerIn: parent; text: "\uf1eb"; color: "#FFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7 } }
                                                Column {
                                                    Text { text: "Wi-Fi"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
                                                    Text { text: "ArchTitan-5G"; color: "#8E8E93"; font.family: "Inter"; font.pixelSize: 6 }
                                                }
                                            }
                                            Row {
                                                spacing: 5
                                                Rectangle { width: 15; height: 15; radius: 7.5; color: "#0A84FF"; Text { anchors.centerIn: parent; text: "\uf293"; color: "#FFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7 } }
                                                Text { text: "AirPods Pro"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
                                            }
                                        }
                                    }

                                    // Mini Now Playing Bento Tile
                                    Rectangle {
                                        Layout.preferredWidth: 88
                                        height: 48
                                        radius: 8
                                        color: Qt.rgba(94/255, 92/255, 230/255, 0.24)
                                        border.width: 1
                                        border.color: "#5E5CE6"
                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            spacing: 2
                                            Row {
                                                spacing: 4
                                                Rectangle { width: 14; height: 14; radius: 4; color: "#BF5AF2"; Text { anchors.centerIn: parent; text: "\uf001"; color: "#FFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7 } }
                                                Text { text: "Solaris"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
                                            }
                                            Text { text: "⏮   ⏸   ⏭"; color: "#D1D1D6"; font.family: "Inter"; font.pixelSize: 8; Layout.alignment: Qt.AlignHCenter }
                                        }
                                    }
                                }

                                // Display Slider Card
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 36
                                    radius: 8
                                    color: Qt.rgba(1, 1, 1, 0.06)
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 3
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Display Brightness"; color: "#D1D1D6"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
                                            Item { Layout.fillWidth: true }
                                            Text { text: "82%"; color: "#8E8E93"; font.family: "Inter"; font.pixelSize: 7 }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 8; radius: 4; color: Qt.rgba(1, 1, 1, 0.14)
                                            Rectangle { width: parent.width * 0.82; height: 8; radius: 4; color: "#F5F5F7" }
                                        }
                                    }
                                }

                                // Sound Slider Card
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 36
                                    radius: 8
                                    color: Qt.rgba(1, 1, 1, 0.06)
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 3
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "PipeWire Studio Audio"; color: "#D1D1D6"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
                                            Item { Layout.fillWidth: true }
                                            Text { text: "68%"; color: "#64D2FF"; font.family: "Inter"; font.pixelSize: 7 }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 8; radius: 4; color: Qt.rgba(1, 1, 1, 0.14)
                                            Rectangle { width: parent.width * 0.68; height: 8; radius: 4; color: "#0A84FF" }
                                        }
                                    }
                                }
                            }
                        }

                        // ── SCENE 2: Tiled Workspaces Mockup ────────────────
                        RowLayout {
                            visible: root.selectedZone === 2
                            anchors.top: miniTopBar.bottom
                            anchors.bottom: miniDockBar.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 8
                            spacing: 8

                            // Left Master Tiled Window
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: Qt.rgba(0.10, 0.11, 0.15, 0.93)
                                border.width: 2
                                border.color: "#BF5AF2"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 9
                                    spacing: 5
                                    Row {
                                        spacing: 4
                                        Rectangle { width: 6; height: 6; radius: 3; color: "#FF5F57" }
                                        Rectangle { width: 6; height: 6; radius: 3; color: "#FEBC2E" }
                                        Rectangle { width: 6; height: 6; radius: 3; color: "#28C840" }
                                        Text { text: "  Code Editor • Master Pane"; color: "#D1D1D6"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
                                    }
                                    Rectangle { Layout.fillWidth: true; height: 6; radius: 3; color: Qt.rgba(191/255, 90/255, 242/255, 0.45) }
                                    Rectangle { Layout.preferredWidth: 140; height: 6; radius: 3; color: Qt.rgba(10/255, 132/255, 255/255, 0.35) }
                                    Rectangle { Layout.preferredWidth: 170; height: 6; radius: 3; color: Qt.rgba(48/255, 209/255, 88/255, 0.30) }
                                    Rectangle { Layout.preferredWidth: 120; height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.14) }
                                    Rectangle { Layout.preferredWidth: 155; height: 6; radius: 3; color: Qt.rgba(100/255, 210/255, 255/255, 0.25) }
                                    Item { Layout.fillHeight: true }
                                }
                            }

                            // Right Dwindle Split Stack (2 Panes)
                            ColumnLayout {
                                Layout.preferredWidth: 168
                                Layout.fillHeight: true
                                spacing: 6

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 8
                                    color: Qt.rgba(0.08, 0.09, 0.13, 0.93)
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.18)

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 3
                                        Text { text: "Kitty Terminal"; color: "#30D158"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
                                        Text { text: "$ titan-hwm status\n✓ 25ms Headroom OK"; color: "#AEAEB2"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7 }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 54
                                    radius: 8
                                    color: Qt.rgba(0.08, 0.09, 0.13, 0.93)
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.18)

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 7
                                        spacing: 2
                                        Text { text: "Dwindle Split • Super + P"; color: "#64D2FF"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
                                        Text { text: "Auto-tiles new windows"; color: "#8E8E93"; font.family: "Inter"; font.pixelSize: 7 }
                                    }
                                }
                            }
                        }

                        // ── SCENE 3: Focus & System Monitor Mockup ──────────
                        Item {
                            visible: root.selectedZone === 3
                            anchors.top: miniTopBar.bottom
                            anchors.bottom: miniDockBar.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 8

                            // Top-Center TitanFocus Pill
                            Rectangle {
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 176
                                height: 24
                                radius: 12
                                color: Qt.rgba(0.09, 0.11, 0.15, 0.96)
                                border.width: 2
                                border.color: "#30D158"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Rectangle { width: 7; height: 7; radius: 3.5; color: "#30D158"; anchors.verticalCenter: parent.verticalCenter }
                                    Text {
                                        text: "TitanFocus • 24:59 • Zen"
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
                                anchors.top: parent.top
                                anchors.topMargin: 28
                                width: 205
                                height: 112
                                radius: 10
                                color: Qt.rgba(0.09, 0.11, 0.15, 0.96)
                                border.width: 2
                                border.color: "#30D158"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 9
                                    spacing: 5

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "System Monitor HUD"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 9; font.weight: 600 }
                                        Item { Layout.fillWidth: true }
                                        Text { text: "THM v3.2"; color: "#30D158"; font.family: "Inter"; font.pixelSize: 8; font.weight: Font.Bold }
                                    }

                                    // CPU Bar
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        RowLayout {
                                            Text { text: "CPU Pressure"; color: "#98989D"; font.family: "Inter"; font.pixelSize: 8 }
                                            Item { Layout.fillWidth: true }
                                            Text { text: "8% • LOW"; color: "#30D158"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
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
                                            Text { text: "Memory PSI"; color: "#98989D"; font.family: "Inter"; font.pixelSize: 8 }
                                            Item { Layout.fillWidth: true }
                                            Text { text: "1.4 GB • 0.00%"; color: "#0A84FF"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600 }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 5; radius: 2.5; color: Qt.rgba(1, 1, 1, 0.12)
                                            Rectangle { width: parent.width * 0.30; height: 5; radius: 2.5; color: "#0A84FF" }
                                        }
                                    }
                                }
                            }
                        }

                        // ── Bottom Interactive Mini-Dock Scene Switcher ─────
                        Rectangle {
                            id: miniDockBar
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 22
                            width: dockPillsRow.implicitWidth + 10
                            radius: 11
                            color: Qt.rgba(0.08, 0.09, 0.13, 0.90)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.16)

                            Row {
                                id: dockPillsRow
                                anchors.centerIn: parent
                                spacing: 4

                                Repeater {
                                    model: ["Spotlight", "Control Center", "Tiling", "Telemetry"]

                                    Rectangle {
                                        property bool isCur: root.selectedZone === index
                                        height: 16
                                        width: dLbl.implicitWidth + 12
                                        radius: 8
                                        color: isCur ? root.zones[index].accentColor : "transparent"

                                        Text {
                                            id: dLbl
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: isCur ? "#FFFFFF" : "#AEAEB2"
                                            font.family: "Inter"
                                            font.pixelSize: 8
                                            font.weight: isCur ? Font.Bold : 500
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                tourCtrl.playSound("tap");
                                                root.selectedZone = index;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Bottom Mini Caption Bar inside Display Card
                    Text {
                        text: root.zones[root.selectedZone].desc
                        color: "#AEAEB2"
                        font.family: "Inter"
                        font.pixelSize: 11
                        lineHeight: 1.25
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
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
                        radius: 11

                        color: isSel ? Qt.rgba(10/255, 132/255, 255/255, 0.16)
                                     : (zoneMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.075)
                                                                : Qt.rgba(1, 1, 1, 0.04))
                        border.width: isSel ? 2 : 1
                        border.color: isSel ? modelData.accentColor : Qt.rgba(1, 1, 1, 0.08)

                        Behavior on color { ColorAnimation { duration: 140 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Rectangle {
                                width: 36
                                height: 36
                                radius: 9
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
                    implicitHeight: 38
                    radius: 9
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: tryMouse.containsMouse ? "#1E90FF" : "#0A84FF"
                        }
                        GradientStop {
                            position: 1.0
                            color: tryMouse.containsMouse ? "#0070E0" : "#0066CC"
                        }
                    }
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.25)

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: root.zones[root.selectedZone].icon
                            color: "#FFFFFF"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.zones[root.selectedZone].actionText
                            color: "#FFFFFF"
                            font.family: "Inter"
                            font.pixelSize: 13
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
