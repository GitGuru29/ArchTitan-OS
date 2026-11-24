import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    radius: 14
    color: "#0E1320"
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.14)
    clip: true

    property int chapterIndex: 0
    property real phase: 0.45
    property int tickStep: 0

    NumberAnimation on phase {
        from: 0.0
        to: 1.0
        duration: 2800
        loops: Animation.Infinite
        running: root.visible
        easing.type: Easing.InOutSine
    }

    Timer {
        interval: 2200
        repeat: true
        running: root.visible
        onTriggered: root.tickStep = (root.tickStep + 1) % 3
    }

    function activeWallpaperUrl() {
        var list = tourCtrl.wallpapers;
        for (var i = 0; i < list.length; i++) {
            if (list[i].path === tourCtrl.selectedWallpaper) return list[i].url;
        }
        return list.length > 0 ? list[0].url : "";
    }

    // Live 4K Wallpaper Backdrop inside the Motion Stage
    Image {
        anchors.fill: parent
        source: root.activeWallpaperUrl()
        fillMode: Image.PreserveAspectCrop
        opacity: root.chapterIndex === 0 ? 0.50 : 0.65
        asynchronous: true
    }

    // Apple Editorial Stage Vignette
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.04, 0.05, 0.09, 0.68) }
            GradientStop { position: 0.5; color: Qt.rgba(0.04, 0.06, 0.11, 0.45) }
            GradientStop { position: 1.0; color: Qt.rgba(0.03, 0.04, 0.08, 0.82) }
        }
    }

    // Top Specular Highlight
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 36
        height: 1
        color: Qt.rgba(1, 1, 1, 0.22)
    }

    // ════════════════════════════════════════════════════════════════════════
    // SCENE 0: Welcome to ArchTitan (Panoramic Sequoia Hero + Floating Cards)
    // ════════════════════════════════════════════════════════════════════════
    RowLayout {
        visible: root.chapterIndex === 0
        anchors.fill: parent
        anchors.leftMargin: 22
        anchors.rightMargin: 20
        spacing: 18

        // 3D macOS Squircle Emblem
        Item {
            width: 78; height: 78
            Rectangle {
                anchors.centerIn: parent
                width: 78; height: 78; radius: 20
                color: Qt.rgba(10/255, 132/255, 255/255, 0.16)
                border.width: 1; border.color: Qt.rgba(100/255, 210/255, 255/255, 0.35)
            }
            Rectangle {
                anchors.centerIn: parent
                width: 68; height: 68; radius: 17
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#1E40AF" }
                    GradientStop { position: 0.5; color: "#172554" }
                    GradientStop { position: 1.0; color: "#0B1120" }
                }
                border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.32)
                Image {
                    anchors.centerIn: parent
                    width: 42; height: 42
                    source: tourCtrl.logoUrl
                    fillMode: Image.PreserveAspectFit; mipmap: true
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            Row {
                spacing: 6
                Rectangle {
                    implicitHeight: 19; implicitWidth: rLbl.implicitWidth + 12; radius: 9
                    color: Qt.rgba(10/255, 132/255, 255/255, 0.24)
                    border.width: 1; border.color: "#0A84FF"
                    Text {
                        id: rLbl; anchors.centerIn: parent
                        text: tourCtrl.isLiveMode ? "LIVE USB MEDIA" : "ARCHTITAN OS • 2026.11"
                        color: "#64D2FF"; font.family: "Inter"; font.pixelSize: 9; font.weight: Font.Bold
                    }
                }
                Rectangle {
                    implicitHeight: 19; implicitWidth: wLbl.implicitWidth + 12; radius: 9
                    color: Qt.rgba(1, 1, 1, 0.10); border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.16)
                    Text {
                        id: wLbl; anchors.centerIn: parent
                        text: "Wayland • Hyprland 0.57"
                        color: "#E5E5EA"; font.family: "Inter"; font.pixelSize: 9; font.weight: 600
                    }
                }
            }

            Text {
                text: "Designed for Velocity & Calm"
                color: "#FFFFFF"
                font.family: "Inter"; font.pixelSize: 23; font.weight: Font.Bold
            }

            Text {
                text: "Cupertino glass aesthetics paired with C++20 system daemons and 25ms kernel CPU headroom protection."
                color: "#D1D1D6"
                font.family: "Inter"; font.pixelSize: 12; lineHeight: 1.25
                Layout.fillWidth: true; wrapMode: Text.WordWrap
            }
        }

        // Right: Animated Floating 3D Glass Widget Stack
        Column {
            spacing: 7
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: [
                    { icon: "\uf001", col: "#BF5AF2", title: "Dynamic Media Island", sub: "Live MPRIS2 Waveform" },
                    { icon: "\uf0e7", col: "#30D158", title: "25ms CFS Headroom",    sub: "Locked 144Hz Desktop" },
                    { icon: "\uf002", col: "#0A84FF", title: "Spotlight & Tiling",   sub: "Sub-ms Fuzzy Launcher" }
                ]
                Rectangle {
                    width: 186; height: 34; radius: 17
                    color: Qt.rgba(0.08, 0.09, 0.14, 0.90)
                    border.width: 1
                    border.color: index === root.tickStep ? modelData.col : Qt.rgba(1, 1, 1, 0.18)
                    Behavior on border.color { ColorAnimation { duration: 240 } }

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 9; anchors.rightMargin: 10; spacing: 8
                        Rectangle {
                            width: 18; height: 18; radius: 9; color: modelData.col
                            Text { anchors.centerIn: parent; text: modelData.icon; color: "#FFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0
                            Text { text: modelData.title; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 10; font.weight: 600 }
                            Text { text: modelData.sub; color: "#98989D"; font.family: "Inter"; font.pixelSize: 8 }
                        }
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // SCENE 2: Top Bar & Dynamic Media Island (Animated Waveform & Workspaces)
    // ════════════════════════════════════════════════════════════════════════
    Item {
        visible: root.chapterIndex === 2
        anchors.fill: parent
        anchors.margins: 16

        // Zoomed-In High-Detail Top Bar
        Rectangle {
            id: zoomedBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 40
            radius: 11
            color: Qt.rgba(0.08, 0.09, 0.13, 0.94)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.20)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                // App Menu Button + Animated Workspace Pills
                Row {
                    spacing: 6
                    Rectangle {
                        width: 24; height: 24; radius: 6; color: "#0A84FF"
                        Text { anchors.centerIn: parent; text: "\uf009"; color: "#FFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                    }

                    Repeater {
                        model: 5
                        Rectangle {
                            property bool isAct: index === root.tickStep
                            width: isAct ? 24 : 8
                            height: 8
                            radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: isAct ? "#64D2FF" : Qt.rgba(1, 1, 1, 0.28)
                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Center: Expanded Dynamic Media Island with Animated Equalizer Bars
                Rectangle {
                    width: 236
                    height: 28
                    radius: 14
                    color: Qt.rgba(191/255, 90/255, 242/255, 0.20)
                    border.width: 1
                    border.color: "#BF5AF2"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Rectangle {
                            width: 18; height: 18; radius: 5; color: "#BF5AF2"
                            Text { anchors.centerIn: parent; text: "\uf001"; color: "#FFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9 }
                        }

                        Text {
                            text: "Solaris • M83"
                            color: "#FFFFFF"
                            font.family: "Inter"; font.pixelSize: 11; font.weight: 600
                            Layout.fillWidth: true
                        }

                        // 6-Bar Animated Audio Equalizer
                        Row {
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter
                            Repeater {
                                model: 6
                                Rectangle {
                                    width: 2
                                    height: 5 + Math.round(9 * Math.abs(Math.sin((root.phase * 6.28) + index * 0.9)))
                                    radius: 1
                                    color: "#D8B4FE"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: System Status Capsule
                Rectangle {
                    width: 106; height: 26; radius: 13
                    color: Qt.rgba(1, 1, 1, 0.08)
                    Row {
                        anchors.centerIn: parent; spacing: 8
                        Text { text: "\uf1eb"; color: "#F5F5F7"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                        Text { text: "\uf028"; color: "#F5F5F7"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                        Text { text: "100%"; color: "#30D158"; font.family: "Inter"; font.pixelSize: 10; font.weight: Font.Bold }
                    }
                }
            }
        }

        // Expanded Media Popover Preview Below Bar
        Rectangle {
            anchors.top: zoomedBar.bottom
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            width: 340
            height: 82
            radius: 12
            color: Qt.rgba(0.09, 0.10, 0.15, 0.94)
            border.width: 1
            border.color: Qt.rgba(191/255, 90/255, 242/255, 0.55)

            RowLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 12
                Rectangle {
                    width: 54; height: 54; radius: 10
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#9333EA" }
                        GradientStop { position: 1.0; color: "#3B82F6" }
                    }
                    Text { anchors.centerIn: parent; text: "\uf001"; color: "#FFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20 }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4
                    Text { text: "Now Playing • Dynamic Island"; color: "#D8B4FE"; font.family: "Inter"; font.pixelSize: 10; font.weight: Font.Bold }
                    Text { text: "Solaris — Midnight Horizon"; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 13; font.weight: 600 }
                    Rectangle {
                        Layout.fillWidth: true; height: 5; radius: 2.5; color: Qt.rgba(1, 1, 1, 0.14)
                        Rectangle { width: parent.width * (0.35 + 0.45 * root.phase); height: 5; radius: 2.5; color: "#BF5AF2" }
                    }
                }
                Text { text: "⏮  ⏸  ⏭"; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 13 }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // SCENE 3: Control Center (Animated Dropdown & Live Sliders)
    // ════════════════════════════════════════════════════════════════════════
    Item {
        visible: root.chapterIndex === 3
        anchors.fill: parent
        anchors.margins: 14

        Rectangle {
            anchors.centerIn: parent
            width: 390
            height: 144
            radius: 14
            color: Qt.rgba(0.10, 0.11, 0.16, 0.95)
            border.width: 2
            border.color: "#5E5CE6"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // Left Column: Connectivity Pills
                ColumnLayout {
                    Layout.preferredWidth: 165
                    Layout.fillHeight: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 9
                        color: Qt.rgba(10/255, 132/255, 255/255, 0.22)
                        border.width: 1; border.color: "#0A84FF"
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 8; spacing: 8
                            Rectangle { width: 26; height: 26; radius: 13; color: "#0A84FF"; Text { anchors.centerIn: parent; text: "\uf1eb"; color: "#FFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } }
                            ColumnLayout {
                                spacing: 0
                                Text { text: "Wi-Fi"; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 11; font.weight: 600 }
                                Text { text: "ArchTitan-5G"; color: "#64D2FF"; font.family: "Inter"; font.pixelSize: 9 }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 9
                        color: Qt.rgba(94/255, 92/255, 230/255, 0.22)
                        border.width: 1; border.color: "#5E5CE6"
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 8; spacing: 8
                            Rectangle { width: 26; height: 26; radius: 13; color: "#5E5CE6"; Text { anchors.centerIn: parent; text: "\uf293"; color: "#FFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } }
                            ColumnLayout {
                                spacing: 0
                                Text { text: "Bluetooth"; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 11; font.weight: 600 }
                                Text { text: "AirPods Pro"; color: "#A78BFA"; font.family: "Inter"; font.pixelSize: 9 }
                            }
                        }
                    }
                }

                // Right Column: Animated Display & PipeWire Audio Sliders
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 9
                        color: Qt.rgba(1, 1, 1, 0.06)
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 8; spacing: 4
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Display Brightness"; color: "#E5E5EA"; font.family: "Inter"; font.pixelSize: 10; font.weight: 600 }
                                Item { Layout.fillWidth: true }
                                Text { text: Math.round(65 + 25 * root.phase) + "%"; color: "#98989D"; font.family: "Inter"; font.pixelSize: 10 }
                            }
                            Rectangle {
                                Layout.fillWidth: true; height: 10; radius: 5; color: Qt.rgba(1, 1, 1, 0.14)
                                Rectangle { width: parent.width * (0.65 + 0.25 * root.phase); height: 10; radius: 5; color: "#FFFFFF" }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 9
                        color: Qt.rgba(1, 1, 1, 0.06)
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 8; spacing: 4
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "PipeWire Studio Audio"; color: "#E5E5EA"; font.family: "Inter"; font.pixelSize: 10; font.weight: 600 }
                                Item { Layout.fillWidth: true }
                                Text { text: Math.round(50 + 35 * (1.0 - root.phase)) + "%"; color: "#64D2FF"; font.family: "Inter"; font.pixelSize: 10 }
                            }
                            Rectangle {
                                Layout.fillWidth: true; height: 10; radius: 5; color: Qt.rgba(1, 1, 1, 0.14)
                                Rectangle { width: parent.width * (0.50 + 0.35 * (1.0 - root.phase)); height: 10; radius: 5; color: "#0A84FF" }
                            }
                        }
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // SCENE 4: Spotlight Command Bar (Animated Self-Typing & Math)
    // ════════════════════════════════════════════════════════════════════════
    Item {
        id: scene4Item
        visible: root.chapterIndex === 4
        anchors.fill: parent

        readonly property var queries: [
            { q: "2048 * 64", res: "131,072", sub: "Inline Math Result • Press Return to Copy", icon: "\uf1ec", col: "#30D158" },
            { q: "kitty",     res: "Kitty Terminal", sub: "GPU-Accelerated Terminal Emulator", icon: "\uf120", col: "#0A84FF" },
            { q: "settings",  res: "ArchTitan Settings", sub: "System Preferences & Wallpaper Studio", icon: "\uf013", col: "#5E5CE6" }
        ]

        Rectangle {
            anchors.centerIn: parent
            width: 390
            height: 138
            radius: 13
            color: Qt.rgba(0.09, 0.10, 0.14, 0.96)
            border.width: 2
            border.color: "#32ADE6"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Text { text: "\uf002"; color: "#32ADE6"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
                    Text {
                        text: scene4Item.queries[root.tickStep].q
                        color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 14; font.weight: 600
                    }
                    Rectangle { width: 2; height: 16; color: "#32ADE6"; opacity: root.phase > 0.5 ? 1.0 : 0.2 }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 58; height: 20; radius: 5; color: Qt.rgba(50/255, 173/255, 230/255, 0.20)
                        Text { anchors.centerIn: parent; text: "⌘ Space"; color: "#64D2FF"; font.family: "Inter"; font.pixelSize: 10; font.weight: 600 }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.10) }

                // Highlighted Top Match Row
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: Qt.rgba(10/255, 132/255, 255/255, 0.24)
                    border.width: 1
                    border.color: "#0A84FF"

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 12; spacing: 10
                        Rectangle {
                            width: 32; height: 32; radius: 8
                            color: scene4Item.queries[root.tickStep].col
                            Text { anchors.centerIn: parent; text: scene4Item.queries[root.tickStep].icon; color: "#FFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 1
                            Text { text: scene4Item.queries[root.tickStep].res; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 13; font.weight: Font.Bold }
                            Text { text: scene4Item.queries[root.tickStep].sub; color: "#98989D"; font.family: "Inter"; font.pixelSize: 10 }
                        }
                        Text { text: "↵ Open"; color: "#64D2FF"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Bold }
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // SCENE 5: Window Tiling & Spaces (Animated 3-Pane Dwindle Tree)
    // ════════════════════════════════════════════════════════════════════════
    RowLayout {
        visible: root.chapterIndex === 5
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Master Pane (Left)
        Rectangle {
            Layout.preferredWidth: 360
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: Qt.rgba(0.09, 0.10, 0.14, 0.94)
            border.width: root.tickStep === 0 ? 2 : 1
            border.color: root.tickStep === 0 ? "#FF9F0A" : Qt.rgba(1, 1, 1, 0.16)

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 6
                Row {
                    spacing: 5
                    Rectangle { width: 7; height: 7; radius: 3.5; color: "#FF5F57" }
                    Rectangle { width: 7; height: 7; radius: 3.5; color: "#FEBC2E" }
                    Rectangle { width: 7; height: 7; radius: 3.5; color: "#28C840" }
                    Text { text: "  Master Window • Dwindle Tree"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 10; font.weight: 600 }
                }
                Rectangle { Layout.fillWidth: true; height: 8; radius: 4; color: Qt.rgba(255/255, 159/255, 10/255, 0.35) }
                Rectangle { Layout.preferredWidth: 180; height: 8; radius: 4; color: Qt.rgba(10/255, 132/255, 255/255, 0.32) }
                Rectangle { Layout.preferredWidth: 210; height: 8; radius: 4; color: Qt.rgba(48/255, 209/255, 88/255, 0.28) }
                Rectangle { Layout.preferredWidth: 150; height: 8; radius: 4; color: Qt.rgba(1, 1, 1, 0.14) }
                Item { Layout.fillHeight: true }
            }
        }

        // Right Split Stack (2 Panes)
        ColumnLayout {
            Layout.preferredWidth: 250
            Layout.fillHeight: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; radius: 10
                color: Qt.rgba(0.09, 0.10, 0.14, 0.94)
                border.width: root.tickStep === 1 ? 2 : 1
                border.color: root.tickStep === 1 ? "#0A84FF" : Qt.rgba(1, 1, 1, 0.16)
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 9; spacing: 3
                    Text { text: "Pane 2 • Kitty Terminal (⌘ Return)"; color: "#64D2FF"; font.family: "Inter"; font.pixelSize: 10; font.weight: 600 }
                    Text { text: "Auto-splits 50/50 when spawned"; color: "#98989D"; font.family: "Inter"; font.pixelSize: 9 }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; radius: 10
                color: Qt.rgba(0.09, 0.10, 0.14, 0.94)
                border.width: root.tickStep === 2 ? 2 : 1
                border.color: root.tickStep === 2 ? "#30D158" : Qt.rgba(1, 1, 1, 0.16)
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 9; spacing: 3
                    Text { text: "Pane 3 • Vertical Sub-Split (⌘ P)"; color: "#30D158"; font.family: "Inter"; font.pixelSize: 10; font.weight: 600 }
                    Text { text: "Move across 10 spaces with ⌘ 1–9"; color: "#98989D"; font.family: "Inter"; font.pixelSize: 9 }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // SCENE 6: TitanFocus Deep Work (Pomodoro Island & Notification Silencer)
    // ════════════════════════════════════════════════════════════════════════
    ColumnLayout {
        visible: root.chapterIndex === 6
        anchors.centerIn: parent
        width: 420
        spacing: 12

        // Expanded TitanFocus Top-Edge Pill
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 310
            height: 44
            radius: 22
            color: Qt.rgba(0.08, 0.10, 0.14, 0.96)
            border.width: 2
            border.color: "#00C7BE"

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 10
                Rectangle {
                    width: 24; height: 24; radius: 12; color: "#00C7BE"
                    Text { anchors.centerIn: parent; text: "\uf06e"; color: "#FFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                }
                Text {
                    text: "Deep Work Session • 24:59"
                    color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 13; font.weight: Font.Bold
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 58; height: 20; radius: 10; color: Qt.rgba(0, 199/255, 190/255, 0.22)
                    Text { anchors.centerIn: parent; text: "ACTIVE"; color: "#5EEAD4"; font.family: "Inter"; font.pixelSize: 9; font.weight: Font.Bold }
                }
            }
        }

        // Muted Notification Banner Preview
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 350
            height: 54
            radius: 12
            color: Qt.rgba(0.10, 0.11, 0.15, 0.90)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)

            RowLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 10
                Rectangle {
                    width: 30; height: 30; radius: 8; color: "#3A3A40"
                    Text { anchors.centerIn: parent; text: "\uf1f6"; color: "#5EEAD4"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 1
                    Text { text: "Notifications Silenced by TitanFocus"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 11; font.weight: 600 }
                    Text { text: "Non-urgent alerts are held quietly until your focus block completes."; color: "#98989D"; font.family: "Inter"; font.pixelSize: 10 }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // SCENE 7: Hardware Guard • THM v3 (Asymmetric Cgroups v2 Simulation)
    // ════════════════════════════════════════════════════════════════════════
    RowLayout {
        visible: root.chapterIndex === 7
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Left Card: Background Bulk Workload (Corralled & Burst-Smoothed)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: Qt.rgba(0.09, 0.10, 0.14, 0.94)
            border.width: 1
            border.color: "#FF9F0A"

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 6
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Background Slice (Builds / Indexers)"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 11; font.weight: 600 }
                    Item { Layout.fillWidth: true }
                    Text { text: "THROTTLED"; color: "#FF9F0A"; font.family: "Inter"; font.pixelSize: 9; font.weight: Font.Bold }
                }
                Text { text: "archtitan-background.slice • cpu.weight = 20"; color: "#98989D"; font.family: "Inter"; font.pixelSize: 10 }
                Rectangle {
                    Layout.fillWidth: true; height: 8; radius: 4; color: Qt.rgba(1, 1, 1, 0.12)
                    Rectangle { width: parent.width * (0.72 + 0.18 * root.phase); height: 8; radius: 4; color: "#FF9F0A" }
                }
                Text { text: "✓ 25ms CFS quota cap + cpu.max.burst smoothing"; color: "#FBBF24"; font.family: "Inter"; font.pixelSize: 10 }
            }
        }

        // Right Card: Protected Interactive Desktop Slice (Locked 144Hz)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: Qt.rgba(0.09, 0.10, 0.14, 0.94)
            border.width: 2
            border.color: "#30D158"

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 6
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Protected Desktop & Audio Slice"; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Bold }
                    Item { Layout.fillWidth: true }
                    Text { text: "144 FPS • 0 XRUNS"; color: "#30D158"; font.family: "Inter"; font.pixelSize: 9; font.weight: Font.Bold }
                }
                Text { text: "archtitan-protected.slice • Hyprland & PipeWire"; color: "#98989D"; font.family: "Inter"; font.pixelSize: 10 }
                Rectangle {
                    Layout.fillWidth: true; height: 8; radius: 4; color: Qt.rgba(1, 1, 1, 0.12)
                    Rectangle { width: parent.width * 0.18; height: 8; radius: 4; color: "#30D158" }
                }
                Text { text: "✓ Guaranteed 1-core headroom under 100% system load"; color: "#34D399"; font.family: "Inter"; font.pixelSize: 10; font.weight: 600 }
            }
        }
    }
}
