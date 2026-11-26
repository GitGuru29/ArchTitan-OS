import QtQuick

/**
 * FeaturePreview — Main Stage content for each guided feature step (03..09).
 * Uses real live telemetry, real theme/wallpaper catalogs, and direct triggers
 * to open the actual running ArchTitan overlays.
 */
Item {
    id: root

    property string featureId: "spotlight"
    property bool liveActive: typeof tourCtrl !== "undefined" ? tourCtrl.liveFeatureOpen : false
    property int selectedSecurityPillar: 0

    signal launchLiveRequested()

    // ── 03: TITAN SPOTLIGHT ─────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 22
        color: "#D8181825"
        border.width: 1
        border.color: "#3800D2FF"
        visible: root.featureId === "spotlight"

        Column {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 18

            // Header badge row
            Row {
                spacing: 10
                Rectangle {
                    width: 32; height: 32; radius: 10
                    color: "#2200D2FF"; border.width: 1; border.color: "#6600D2FF"
                    Text { anchors.centerIn: parent; text: "⌕"; font.pixelSize: 17; color: "#00D2FF" }
                }
                Column {
                    spacing: 2
                    Text { text: "TITAN SPOTLIGHT · ZERO COLD-START LAUNCHER"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.2; color: "#00D2FF" }
                    Text { text: "Single-tap Super key invocation · LayerShellQt hardware blur"; font.family: "Inter"; font.pixelSize: 12; color: "#A6ADC8" }
                }
            }

            // Glass search bar preview
            Rectangle {
                width: parent.width
                height: 54
                radius: 14
                color: "#EE11111B"
                border.width: 1.5
                border.color: "#00D2FF"

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Text { text: "⌕"; font.pixelSize: 20; color: "#00D2FF"; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: "42 * 10   →   = 420  (Enter to copy)"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: "#CDD6F4"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 68; height: 26; radius: 7
                    color: "#2200D2FF"; border.width: 1; border.color: "#5500D2FF"
                    Text { anchors.centerIn: parent; text: "Super"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold; color: "#00D2FF" }
                }
            }

            // Capabilities 3-card row
            Row {
                width: parent.width
                spacing: 12

                Repeater {
                    model: [
                        { tag: "APPS", title: "XDG Desktop Indexer", desc: "Fuzzy prefix & substring search across all installed native and sandboxed apps.", key: "Super" },
                        { tag: "MATH", title: "Instant Calculator", desc: "Evaluate 42 * 10, sqrt(144), 2^8, or trig expressions live as you type.", key: "Enter → Copy" },
                        { tag: "CLIPBOARD", title: "Clipboard History", desc: "Recall recent copied text snippets and code blocks instantly via cliphist.", key: "Super + V" }
                    ]

                    Rectangle {
                        width: (parent.width - 24) / 3
                        height: 118
                        radius: 14
                        color: "#B81E1E2E"
                        border.width: 1
                        border.color: "#26FFFFFF"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 6

                            Row {
                                spacing: 8
                                Text { text: modelData.tag; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.weight: Font.Bold; color: "#00D2FF" }
                                Rectangle {
                                    width: kLbl.implicitWidth + 10; height: 18; radius: 5; color: "#313244"
                                    Text { id: kLbl; anchors.centerIn: parent; text: modelData.key; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: "#CDD6F4" }
                                }
                            }
                            Text { text: modelData.title; font.family: "Inter"; font.pixelSize: 13; font.weight: Font.Bold; color: "#CDD6F4" }
                            Text { width: parent.width; text: modelData.desc; font.family: "Inter"; font.pixelSize: 11; color: "#A6ADC8"; wrapMode: Text.WordWrap }
                        }
                    }
                }
            }

            // Live trigger bar
            Rectangle {
                width: parent.width
                height: 52
                radius: 14
                color: "#2000D2FF"
                border.width: 1
                border.color: "#5500D2FF"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.liveActive ? "Spotlight is open on your desktop — try typing a query or math expression."
                                          : "Open the real Titan Spotlight overlay directly on your desktop:"
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: "#CDD6F4"
                }

                GlassButton {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.liveActive ? "Close Spotlight" : "Launch Spotlight Live"
                    shortcutHint: "Super"
                    variant: "primary"
                    buttonHeight: 34
                    onClicked: root.launchLiveRequested()
                }
            }
        }
    }

    // ── 04: WORKSPACE HUD / MISSION CONTROL ─────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 22
        color: "#D8181825"
        border.width: 1
        border.color: "#3800D2FF"
        visible: root.featureId === "workspace"

        property int activeWsPreview: 0

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            Row {
                spacing: 10
                Rectangle {
                    width: 32; height: 32; radius: 10
                    color: "#2200D2FF"; border.width: 1; border.color: "#6600D2FF"
                    Text { anchors.centerIn: parent; text: "⊞"; font.pixelSize: 17; color: "#00D2FF" }
                }
                Column {
                    spacing: 2
                    Text { text: "TITAN WORKSPACE HUD · 2×5 MISSION CONTROL MATRIX"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.2; color: "#00D2FF" }
                    Text { text: "Click any workspace card below or launch the live top-edge Mission Control overlay (Super + Tab)"; font.family: "Inter"; font.pixelSize: 12; color: "#A6ADC8" }
                }
            }

            // 2x5 Interactive Workspace Grid
            Grid {
                width: parent.width
                columns: 5
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: [
                        { ws: 1, key: "󰘳 1", apps: ["Kitty · fish", "Code · THM"] },
                        { ws: 2, key: "󰘳 2", apps: ["TitanBrowser"] },
                        { ws: 3, key: "󰘳 3", apps: ["Sysmon · C++20"] },
                        { ws: 4, key: "󰘳 4", apps: ["Settings"] },
                        { ws: 5, key: "󰘳 5", apps: [] },
                        { ws: 6, key: "󰘳 6", apps: ["Media · MPV"] },
                        { ws: 7, key: "󰘳 7", apps: [] },
                        { ws: 8, key: "󰘳 8", apps: [] },
                        { ws: 9, key: "󰘳 9", apps: [] },
                        { ws: 10, key: "󰘳 0", apps: [] }
                    ]

                    Rectangle {
                        readonly property bool sel: index === parent.parent.parent.activeWsPreview
                        width: (parent.width - 40) / 5
                        height: 82
                        radius: 12
                        color: sel ? "#2600D2FF" : "#B81E1E2E"
                        border.width: sel ? 1.5 : 1
                        border.color: sel ? "#00D2FF" : "#28FFFFFF"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 9
                            spacing: 5

                            Item {
                                width: parent.width; height: 16
                                Text {
                                    text: "WS " + modelData.ws
                                    font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Bold
                                    color: sel ? "#00D2FF" : "#CDD6F4"
                                }
                                Rectangle {
                                    anchors.right: parent.right
                                    width: 32; height: 15; radius: 4
                                    color: "#22FFFFFF"
                                    Text { anchors.centerIn: parent; text: modelData.key; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; color: "#A6ADC8" }
                                }
                            }

                            Repeater {
                                model: modelData.apps
                                Rectangle {
                                    width: parent.width; height: 18; radius: 5
                                    color: "#CC313244"; border.width: 1; border.color: "#3300D2FF"
                                    Text {
                                        anchors.left: parent.left; anchors.leftMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData
                                        font.family: "Inter"; font.pixelSize: 9; color: "#CDD6F4"
                                    }
                                }
                            }

                            Text {
                                visible: modelData.apps.length === 0
                                text: "Empty desktop"
                                font.family: "Inter"; font.pixelSize: 9; color: "#7F849C"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.parent.parent.parent.activeWsPreview = index
                        }
                    }
                }
            }

            // Gestures & live action bar
            Rectangle {
                width: parent.width
                height: 54
                radius: 14
                color: "#2000D2FF"
                border.width: 1
                border.color: "#5500D2FF"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 260
                    text: "Touchpad 3-finger horizontal swipe steps 1:1 between workspaces · Right-edge dwell advances"
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: "#CDD6F4"
                    elide: Text.ElideRight
                }

                GlassButton {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.liveActive ? "Hide Workspace HUD" : "Open Workspace HUD Live"
                    shortcutHint: "Super+Tab"
                    variant: "primary"
                    buttonHeight: 34
                    onClicked: root.launchLiveRequested()
                }
            }
        }
    }

    // ── 05: TITAN QUICKSETTINGS ─────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 22
        color: "#D8181825"
        border.width: 1
        border.color: "#3800D2FF"
        visible: root.featureId === "quicksettings"

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            Row {
                spacing: 10
                Rectangle {
                    width: 32; height: 32; radius: 10
                    color: "#2200D2FF"; border.width: 1; border.color: "#6600D2FF"
                    Text { anchors.centerIn: parent; text: "☰"; font.pixelSize: 16; color: "#00D2FF" }
                }
                Column {
                    spacing: 2
                    Text { text: "TITAN QUICKSETTINGS · LIQUID GLASS CONTROL CENTER"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.2; color: "#00D2FF" }
                    Text { text: "Summon via Super + N or top-right corner pointer dwell (180 ms)"; font.family: "Inter"; font.pixelSize: 12; color: "#A6ADC8" }
                }
            }

            // Tile grid + power profile selector
            Grid {
                width: parent.width
                columns: 3
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: [
                        { title: "Wi-Fi & Network", sub: "NetworkManager live scanner", active: true, badge: "Connected" },
                        { title: "Bluetooth", sub: "BlueZ device switcher", active: true, badge: "Ready" },
                        { title: "PipeWire Audio", sub: "Low-latency sink & volume", active: true, badge: "Active" },
                        { title: "Display & Brightness", sub: "Backlight & Night Light", active: true, badge: "100%" },
                        { title: "Do Not Disturb", sub: "Silences notification popups", active: false, badge: "Off" },
                        { title: "Notification Center", sub: "Bottom-right hotzone drawer", active: true, badge: "Live" }
                    ]

                    Rectangle {
                        width: (parent.width - 20) / 3
                        height: 68
                        radius: 14
                        color: modelData.active ? "#2400D2FF" : "#B81E1E2E"
                        border.width: 1
                        border.color: modelData.active ? "#6600D2FF" : "#26FFFFFF"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            Row {
                                spacing: 6
                                Text { text: modelData.title; font.family: "Inter"; font.pixelSize: 12; font.weight: Font.Bold; color: "#CDD6F4" }
                                Rectangle {
                                    width: bTxt.implicitWidth + 10; height: 16; radius: 5
                                    color: modelData.active ? "#00D2FF" : "#313244"
                                    Text { id: bTxt; anchors.centerIn: parent; text: modelData.badge; font.family: "Inter"; font.pixelSize: 9; font.weight: Font.Bold; color: modelData.active ? "#11111B" : "#A6ADC8" }
                                }
                            }
                            Text { text: modelData.sub; font.family: "Inter"; font.pixelSize: 11; color: "#A6ADC8" }
                        }
                    }
                }
            }

            // Live stateful Power Profile Selector connected to tourCtrl.activeProfile
            Rectangle {
                width: parent.width
                height: 54
                radius: 14
                color: "#B81E1E2E"
                border.width: 1
                border.color: "#2EFFFFFF"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Active Power Profile (Super + Shift + P):"
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: "#CDD6F4"
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "power-saver", label: "Power Saver" },
                            { id: "balanced", label: "Balanced" },
                            { id: "performance", label: "Performance" }
                        ]

                        GlassButton {
                            readonly property bool isCurrent: typeof tourCtrl !== "undefined" && tourCtrl.activeProfile === modelData.id
                            text: modelData.label
                            variant: isCurrent ? "primary" : "secondary"
                            buttonHeight: 32
                            horizontalPadding: 14
                            onClicked: if (typeof tourCtrl !== "undefined") tourCtrl.activeProfile = modelData.id
                        }
                    }
                }
            }

            // Launch real QuickSettings drawer
            Rectangle {
                width: parent.width
                height: 48
                radius: 14
                color: "#2000D2FF"
                border.width: 1
                border.color: "#5500D2FF"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.liveActive ? "QuickSettings drawer is open on the right edge — try interacting with its controls."
                                          : "Slide out the real Titan QuickSettings drawer on the right edge:"
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: "#CDD6F4"
                }

                GlassButton {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.liveActive ? "Hide QuickSettings" : "Open QuickSettings Live"
                    shortcutHint: "Super+N"
                    variant: "primary"
                    buttonHeight: 32
                    onClicked: root.launchLiveRequested()
                }
            }
        }
    }

    // ── 06: TITAN MEDIA HUD (DYNAMIC ISLAND) ────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 22
        color: "#D8181825"
        border.width: 1
        border.color: "#3800D2FF"
        visible: root.featureId === "media"

        readonly property bool playerActive: typeof tourCtrl !== "undefined" ? tourCtrl.hasMediaPlayer : false

        Column {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 16

            Row {
                spacing: 10
                Rectangle {
                    width: 32; height: 32; radius: 10
                    color: "#2200D2FF"; border.width: 1; border.color: "#6600D2FF"
                    Text { anchors.centerIn: parent; text: "♪"; font.pixelSize: 16; color: "#00D2FF" }
                }
                Column {
                    spacing: 2
                    Text { text: "TITAN MEDIA HUD · DYNAMIC ISLAND OVERLAY"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.2; color: "#00D2FF" }
                    Text {
                        text: parent.parent.parent.playerActive
                            ? "Active MPRIS media player detected on D-Bus — controls are live."
                            : "No active media player right now — the island automatically expands when Spotify, TitanBrowser, or MPV plays audio."
                        font.family: "Inter"; font.pixelSize: 12; color: "#A6ADC8"
                    }
                }
            }

            // Dynamic Island capsule stage
            Rectangle {
                width: Math.min(parent.width, 540)
                height: 118
                radius: 28
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#F211111B"
                border.width: 1.5
                border.color: "#8800D2FF"

                Row {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 16

                    // Album / Insignia disc
                    Rectangle {
                        width: 82; height: 82; radius: 18
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#00D2FF" }
                            GradientStop { position: 1.0; color: "#0284C7" }
                        }
                        Text { anchors.centerIn: parent; text: "♫"; font.pixelSize: 32; color: "#11111B" }
                    }

                    Column {
                        width: parent.width - 210
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            text: "ArchTitan Audio · PipeWire Low-Latency"
                            font.family: "Inter"; font.pixelSize: 15; font.weight: Font.Bold; color: "#CDD6F4"
                            elide: Text.ElideRight; width: parent.width
                        }
                        Text {
                            text: "MPRIS D-Bus Transport · GPU & Context Capsule"
                            font.family: "Inter"; font.pixelSize: 12; color: "#A6ADC8"
                        }

                        // Progress rail
                        Rectangle {
                            width: parent.width; height: 5; radius: 2.5; color: "#313244"
                            Rectangle { width: parent.width * 0.44; height: parent.height; radius: 2.5; color: "#00D2FF" }
                        }
                    }

                    // Transport buttons
                    Row {
                        spacing: 10
                        anchors.verticalCenter: parent.verticalCenter

                        Repeater {
                            model: ["⏮", "⏯", "⏭"]
                            Rectangle {
                                width: 32; height: 32; radius: 16
                                color: index === 1 ? "#00D2FF" : "#313244"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: 13
                                    color: index === 1 ? "#11111B" : "#CDD6F4"
                                }
                            }
                        }
                    }
                }
            }

            // Live trigger bar
            Rectangle {
                width: parent.width
                height: 50
                radius: 14
                color: "#2000D2FF"
                border.width: 1
                border.color: "#5500D2FF"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Click the center capsule in Waybar or press Super + M to expand the Media HUD."
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: "#CDD6F4"
                }

                GlassButton {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.liveActive ? "Hide Media HUD" : "Toggle Media HUD Live"
                    shortcutHint: "Super+M"
                    variant: "primary"
                    buttonHeight: 34
                    onClicked: root.launchLiveRequested()
                }
            }
        }
    }

    // ── 07: INTELLIGENCE UNDER THE HOOD (THM v3.4 & SYSMON) ─────────────────
    Rectangle {
        anchors.fill: parent
        radius: 22
        color: "#D8181825"
        border.width: 1
        border.color: "#3800D2FF"
        visible: root.featureId === "sysmon"

        readonly property int cpuPct: typeof tourCtrl !== "undefined" ? Math.round(tourCtrl.cpuUsage * 100) : 14
        readonly property int ramPct: typeof tourCtrl !== "undefined" ? Math.round(tourCtrl.ramUsage * 100) : 28
        readonly property int tempC: typeof tourCtrl !== "undefined" ? tourCtrl.cpuTemp : 42
        readonly property real psiMem: typeof tourCtrl !== "undefined" ? tourCtrl.psiMemory : 0.0

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            Row {
                spacing: 10
                Rectangle {
                    width: 32; height: 32; radius: 10
                    color: "#2200D2FF"; border.width: 1; border.color: "#6600D2FF"
                    Text { anchors.centerIn: parent; text: "◈"; font.pixelSize: 16; color: "#00D2FF" }
                }
                Column {
                    spacing: 2
                    Text { text: "TITAN HARDWARE MANAGER (THM v3.4) & LIVE SYSMON"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.2; color: "#00D2FF" }
                    Text {
                        text: (typeof tourCtrl !== "undefined" ? tourCtrl.cpuName : "Multi-Core CPU") + "  ·  "
                            + (typeof tourCtrl !== "undefined" ? tourCtrl.ramTotal : "16 GB") + "  ·  Kernel "
                            + (typeof tourCtrl !== "undefined" ? tourCtrl.kernelVersion : "Linux")
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: "#A6ADC8"
                    }
                }
            }

            // 4 Live Hardware Telemetry Gauges (fed from real /proc & /sys)
            Row {
                width: parent.width
                spacing: 10

                Repeater {
                    model: [
                        { label: "CPU LOAD", value: parent.parent.parent.cpuPct + "%", ratio: parent.parent.parent.cpuPct / 100.0, sub: "5 Hz cgroup v2 scheduler", accent: "#00D2FF" },
                        { label: "MEMORY", value: parent.parent.parent.ramPct + "%", ratio: parent.parent.parent.ramPct / 100.0, sub: "memory.high / low guard", accent: "#0284C7" },
                        { label: "THERMALS", value: parent.parent.parent.tempC + "°C", ratio: Math.min(1.0, parent.parent.parent.tempC / 95.0), sub: "ACPI thermal zone", accent: "#A6E3A1" },
                        { label: "PSI PRESSURE", value: parent.parent.parent.psiMem.toFixed(2), ratio: Math.min(1.0, parent.parent.parent.psiMem / 10.0), sub: "oom_kill = 0 invariant", accent: "#94E2D5" }
                    ]

                    Rectangle {
                        width: (parent.width - 30) / 4
                        height: 102
                        radius: 14
                        color: "#B81E1E2E"
                        border.width: 1
                        border.color: "#28FFFFFF"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 5

                            Text { text: modelData.label; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.weight: Font.Bold; color: "#A6ADC8" }
                            Text { text: modelData.value; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 22; font.weight: Font.Bold; color: "#CDD6F4" }

                            Rectangle {
                                width: parent.width; height: 5; radius: 2.5; color: "#313244"
                                Rectangle {
                                    width: Math.max(6, parent.width * modelData.ratio)
                                    height: parent.height; radius: 2.5; color: modelData.accent
                                }
                            }
                            Text { text: modelData.sub; font.family: "Inter"; font.pixelSize: 10; color: "#7F849C" }
                        }
                    }
                }
            }

            // THM cgroup v2 workload routing visualization
            Rectangle {
                width: parent.width
                height: 64
                radius: 14
                color: "#B81E1E2E"
                border.width: 1
                border.color: "#28FFFFFF"

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Repeater {
                        model: [
                            { slice: "archtitan-latency.slice", desc: "Uncapped foreground & audio/input boost", tag: "PRIORITY 1" },
                            { slice: "archtitan-active.slice", desc: "Focused workspace + 30s recent-focus grace", tag: "FOREGROUND" },
                            { slice: "archtitan-background.slice", desc: "Throttled via cpu.max (~90.7% throughput)", tag: "BACKGROUND" }
                        ]

                        Rectangle {
                            width: (parent.width - 20) / 3
                            height: parent.height
                            radius: 10
                            color: "#9911111B"
                            border.width: 1
                            border.color: index === 0 ? "#6600D2FF" : "#22FFFFFF"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 2
                                Text { text: modelData.slice; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.weight: Font.Bold; color: index === 0 ? "#00D2FF" : "#CDD6F4" }
                                Text { text: modelData.desc; font.family: "Inter"; font.pixelSize: 10; color: "#A6ADC8"; elide: Text.ElideRight; width: parent.width }
                            }
                        }
                    }
                }
            }

            // Live Sysmon trigger
            Rectangle {
                width: parent.width
                height: 48
                radius: 14
                color: "#2000D2FF"
                border.width: 1
                border.color: "#5500D2FF"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 255
                    text: "Dwell pointer on the left-centre screen edge (180 ms) or launch Sysmon:"
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: "#CDD6F4"
                    elide: Text.ElideRight
                }

                GlassButton {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.liveActive ? "Hide Sysmon" : "Open Titan Sysmon Live"
                    shortcutHint: "Left Edge"
                    variant: "primary"
                    buttonHeight: 32
                    onClicked: root.launchLiveRequested()
                }
            }
        }
    }

    // ── 08: PROTECTION BY DESIGN (SANDBOX, GUARD, BTRFS) ────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 22
        color: "#D8181825"
        border.width: 1
        border.color: "#3800D2FF"
        visible: root.featureId === "security"

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            Row {
                spacing: 10
                Rectangle {
                    width: 32; height: 32; radius: 10
                    color: "#2200D2FF"; border.width: 1; border.color: "#6600D2FF"
                    Text { anchors.centerIn: parent; text: "🛡"; font.pixelSize: 16; color: "#00D2FF" }
                }
                Column {
                    spacing: 2
                    Text { text: "PROTECTION BY DESIGN · ZERO-CONFIG DEFENCE IN DEPTH"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.2; color: "#00D2FF" }
                    Text { text: "Click any protection layer to inspect its runtime enforcement policy"; font.family: "Inter"; font.pixelSize: 12; color: "#A6ADC8" }
                }
            }

            // Three interactive security pillars
            Row {
                width: parent.width
                spacing: 12

                Repeater {
                    model: [
                        {
                            tag: "ISOLATION",
                            title: "Titan Sandbox",
                            bin: "titan-sandboxd · titan-exec-hook",
                            summary: "Every user app launches inside isolated Linux user, mount, PID, and network namespaces with seccomp-bpf syscall filtering.",
                            detail: "Policies: /etc/titan-sandbox/policies/{browser,general-gui,media}.toml · Drops root capabilities automatically."
                        },
                        {
                            tag: "INTEGRITY",
                            title: "ArchTitan Guard",
                            bin: "archtitan-guard · pacman hooks",
                            summary: "Locks display manager and greeter integrity against accidental removal or conflicting package transactions.",
                            detail: "Guarantees SDDM Rise Theme and Hyprland session boot reliability across rolling Arch updates."
                        },
                        {
                            tag: "RECOVERY",
                            title: "BTRFS Snapshots",
                            bin: "archtitan-btrfs-snapshot · grub-btrfs",
                            summary: "Captures read-only root subvolume snapshots automatically before every pacman update with 10-snapshot rotation.",
                            detail: "Snapshots appear directly in the GRUB boot menu (/.snapshots/@pre-pacman-*) for instant rollback."
                        }
                    ]

                    Rectangle {
                        readonly property bool sel: root.selectedSecurityPillar === index
                        width: (parent.width - 24) / 3
                        height: 170
                        radius: 16
                        color: sel ? "#2400D2FF" : "#B81E1E2E"
                        border.width: sel ? 1.5 : 1
                        border.color: sel ? "#00D2FF" : "#28FFFFFF"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 5

                            Row {
                                spacing: 6
                                Rectangle {
                                    width: tLbl.implicitWidth + 10; height: 18; radius: 5
                                    color: sel ? "#00D2FF" : "#313244"
                                    Text { id: tLbl; anchors.centerIn: parent; text: modelData.tag; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.weight: Font.Bold; color: sel ? "#11111B" : "#00D2FF" }
                                }
                                Text { text: "ACTIVE"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.weight: Font.Bold; color: "#A6E3A1"; anchors.verticalCenter: parent.verticalCenter }
                            }

                            Text { text: modelData.title; font.family: "Inter"; font.pixelSize: 15; font.weight: Font.Bold; color: "#CDD6F4" }
                            Text { text: modelData.bin; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: "#00D2FF"; elide: Text.ElideRight; width: parent.width }
                            Text { width: parent.width; text: modelData.summary; font.family: "Inter"; font.pixelSize: 11; color: "#A6ADC8"; wrapMode: Text.WordWrap; lineHeight: 1.25 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedSecurityPillar = index
                        }
                    }
                }
            }

            // Selected pillar technical detail bar
            Rectangle {
                width: parent.width
                height: 46
                radius: 12
                color: "#9911111B"
                border.width: 1
                border.color: "#4400D2FF"

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        var details = [
                            "Titan Sandbox: /etc/titan-sandbox/policies/{browser,general-gui,media}.toml · seccomp-bpf active.",
                            "ArchTitan Guard: Pre-transaction hook blocks conflicting display managers & protects sddm-rise-theme.",
                            "BTRFS Snapshot Hook: Pre-pacman read-only snapshots in /.snapshots/@pre-pacman-* + GRUB rollback."
                        ];
                        return details[root.selectedSecurityPillar] || details[0];
                    }
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: "#CDD6F4"
                    elide: Text.ElideRight
                }
            }
        }
    }

    // ── 09: MAKE IT YOURS (NON-DESTRUCTIVE THEME & WALLPAPER PREVIEW) ───────
    Rectangle {
        anchors.fill: parent
        radius: 22
        color: "#D8181825"
        border.width: 1
        border.color: "#3800D2FF"
        visible: root.featureId === "personalize"

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12

            // Header + non-destructive guarantee badge
            Item {
                width: parent.width
                height: 36

                Row {
                    spacing: 10
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: 32; height: 32; radius: 10
                        color: "#2200D2FF"; border.width: 1; border.color: "#6600D2FF"
                        Text { anchors.centerIn: parent; text: "✦"; font.pixelSize: 16; color: "#00D2FF" }
                    }
                    Column {
                        spacing: 1
                        Text { text: "LIVE THEME & WALLPAPER STUDIO · SAFE PREVIEW"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.2; color: "#00D2FF" }
                        Text {
                            text: (typeof tourCtrl !== "undefined" && tourCtrl.themeAppliedFeedback)
                                ? "✓ Applied to your desktop!"
                                : "Previewing: " + (typeof tourCtrl !== "undefined" ? tourCtrl.previewThemeName : "ArchTitan Signature") + " (Installed theme untouched until you click Apply)"
                            font.family: "Inter"; font.pixelSize: 12
                            color: (typeof tourCtrl !== "undefined" && tourCtrl.themeAppliedFeedback) ? "#A6E3A1" : "#A6ADC8"
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    GlassButton {
                        text: "Settings"
                        shortcutHint: "Super+,"
                        variant: "secondary"
                        buttonHeight: 32
                        horizontalPadding: 12
                        onClicked: if (typeof tourCtrl !== "undefined") tourCtrl.launchSettings()
                    }

                    GlassButton {
                        text: "Wallpapers"
                        shortcutHint: "Super+\\"
                        variant: "secondary"
                        buttonHeight: 32
                        horizontalPadding: 12
                        onClicked: if (typeof tourCtrl !== "undefined") tourCtrl.launchWallpaperPicker()
                    }
                }
            }

            // Theme swatches grid (5 columns x 2 rows = 10 curated themes)
            Grid {
                width: parent.width
                columns: 5
                rowSpacing: 8
                columnSpacing: 8

                Repeater {
                    model: typeof tourCtrl !== "undefined" ? tourCtrl.themes : []

                    Rectangle {
                        readonly property bool isPreviewed: typeof tourCtrl !== "undefined" && tourCtrl.previewThemeId === modelData.id
                        readonly property bool isInstalled: typeof tourCtrl !== "undefined" && tourCtrl.installedThemeId === modelData.id
                        width: (parent.width - 32) / 5
                        height: 52
                        radius: 11
                        color: isPreviewed ? "#2800D2FF" : "#B81E1E2E"
                        border.width: isPreviewed ? 1.5 : 1
                        border.color: isPreviewed ? "#00D2FF" : "#26FFFFFF"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            Row {
                                spacing: 6
                                Rectangle {
                                    width: 12; height: 12; radius: 6
                                    color: modelData.accent || "#00D2FF"
                                    border.width: 1; border.color: "#44FFFFFF"
                                }
                                Text {
                                    text: modelData.name
                                    font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Bold
                                    color: "#CDD6F4"
                                    elide: Text.ElideRight
                                    width: parent.parent.width - 22
                                }
                            }

                            Text {
                                text: isInstalled ? "● Installed" : (isPreviewed ? "◉ Previewing" : "Click to preview")
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                color: isInstalled ? "#A6E3A1" : (isPreviewed ? "#00D2FF" : "#7F849C")
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (typeof tourCtrl !== "undefined") tourCtrl.selectPreviewTheme(modelData.id)
                        }
                    }
                }
            }

            // Wallpaper thumbnails strip
            Row {
                width: parent.width
                spacing: 8

                Repeater {
                    model: typeof tourCtrl !== "undefined" ? tourCtrl.wallpapers.slice(0, 6) : []

                    Rectangle {
                        readonly property bool wpSel: typeof tourCtrl !== "undefined" && tourCtrl.previewWallpaper === modelData.path
                        width: (parent.width - 40) / 6
                        height: 54
                        radius: 10
                        color: "#11111B"
                        border.width: wpSel ? 2 : 1
                        border.color: wpSel ? "#00D2FF" : "#28FFFFFF"
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: modelData.url
                            sourceSize: Qt.size(160, 90)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 18
                            color: "#CC11111B"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.name
                                font.family: "Inter"
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                color: wpSel ? "#00D2FF" : "#CDD6F4"
                                elide: Text.ElideRight
                                width: parent.width - 6
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (typeof tourCtrl !== "undefined") tourCtrl.selectPreviewWallpaper(modelData.path)
                        }
                    }
                }
            }

            // Explicit Apply / Reset action bar
            Rectangle {
                width: parent.width
                height: 46
                radius: 12
                color: "#2000D2FF"
                border.width: 1
                border.color: "#5500D2FF"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: (typeof tourCtrl !== "undefined" && tourCtrl.themeModifiedInPreview)
                        ? "Preview active inside tour. Click Apply to set it on your desktop:"
                        : "Select any theme or wallpaper above to preview its look live."
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: "#CDD6F4"
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    GlassButton {
                        visible: typeof tourCtrl !== "undefined" && tourCtrl.themeModifiedInPreview
                        text: "Reset Preview"
                        variant: "ghost"
                        buttonHeight: 32
                        horizontalPadding: 12
                        onClicked: if (typeof tourCtrl !== "undefined") tourCtrl.resetPreviewToInstalled()
                    }

                    GlassButton {
                        text: (typeof tourCtrl !== "undefined" && tourCtrl.themeAppliedFeedback) ? "Applied ✓" : "Apply to Desktop"
                        variant: "primary"
                        buttonHeight: 32
                        horizontalPadding: 16
                        onClicked: if (typeof tourCtrl !== "undefined") tourCtrl.applyPreviewChoice()
                    }
                }
            }
        }
    }
}
