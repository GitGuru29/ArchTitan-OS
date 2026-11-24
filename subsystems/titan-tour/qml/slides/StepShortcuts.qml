import QtQuick
import QtQuick.Layouts
import "../components"

Item {
    id: root
    signal jumpToChapter(int chapterIdx)

    property int activeTab: 0
    property int hoveredIndex: 0

    readonly property var keyCategories: ["All", "Apps", "Tiling", "Overlays"]

    readonly property var allShortcuts: [
        { keys: ["SUPER", "Space"],       icon: "\uf002", col: "#0A84FF", title: "Spotlight Search", desc: "Launch apps, search files & math", category: 1, action: function() { tourCtrl.toggleSpotlight(); } },
        { keys: ["SUPER", "Return"],      icon: "\uf120", col: "#30D158", title: "Terminal",         desc: "Open GPU-accelerated Kitty terminal", category: 1, action: function() { tourCtrl.launchTerminal(); } },
        { keys: ["SUPER", "W"],           icon: "\uf268", col: "#5E5CE6", title: "Web Browser",      desc: "Launch TitanBrowser WebEngine", category: 1, action: function() { tourCtrl.launchBrowser(); } },
        { keys: ["SUPER", "E"],           icon: "\uf07b", col: "#64D2FF", title: "Files",            desc: "Open Dolphin file manager", category: 1, action: function() { tourCtrl.launchFileManager(); } },
        { keys: ["SUPER", "Q"],           icon: "\uf00d", col: "#FF453A", title: "Close Window",     desc: "Close the currently focused window", category: 2, action: null },
        { keys: ["SUPER", "F"],           icon: "\uf065", col: "#BF5AF2", title: "Fullscreen",       desc: "Expand active window edge-to-edge", category: 2, action: null },
        { keys: ["SUPER", "Alt", "Space"],icon: "\uf2d2", col: "#FF9F0A", title: "Float / Tile",     desc: "Toggle floating or tiled window", category: 2, action: null },
        { keys: ["SUPER", "1–9"],         icon: "\uf009", col: "#0A84FF", title: "Workspaces",       desc: "Jump directly to space 1 through 9", category: 2, action: null },
        { keys: ["SUPER", "N"],           icon: "\uf1de", col: "#5E5CE6", title: "Control Center",   desc: "Wi-Fi, Bluetooth, audio & display", category: 3, action: function() { tourCtrl.toggleControlCenter(); } },
        { keys: ["SUPER", "M"],           icon: "\uf080", col: "#30D158", title: "System Monitor",   desc: "Real-time CPU, RAM & PSI telemetry", category: 3, action: function() { tourCtrl.toggleSysmon(); } },
        { keys: ["SUPER", "Alt", "F"],    icon: "\uf06e", col: "#00C7BE", title: "TitanFocus",       desc: "Toggle top-edge Pomodoro timer", category: 3, action: function() { tourCtrl.toggleFocus(); } },
        { keys: ["SUPER", ","],           icon: "\uf013", col: "#8E8E93", title: "System Settings",  desc: "Open ArchTitan Preferences app", category: 3, action: function() { tourCtrl.launchSettings(); } }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 10

        // ── Top 60fps Animated 3-Pane Dwindle Tiling Stage ──────────────────
        MotionStage {
            Layout.fillWidth: true
            Layout.preferredHeight: 132
            chapterIndex: 5
        }

        // ── Editorial Header + Live Key Visualizer Pill + Segmented Filter ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 1
                Text {
                    text: "DESKTOP & WORKFLOW • CHAPTER 6"
                    color: "#FF9F0A"
                    font.family: "Inter"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.6
                }
                Text {
                    text: "Window Tiling & Keyboard Shortcuts"
                    color: "#FFFFFF"
                    font.family: "Inter"; font.pixelSize: 20; font.weight: Font.Bold
                }
            }

            Item { Layout.fillWidth: true }

            // Segmented Filter Control
            Rectangle {
                implicitHeight: 28
                implicitWidth: segRow.implicitWidth + 6
                radius: 7
                color: Qt.rgba(0, 0, 0, 0.28)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                Row {
                    id: segRow; anchors.centerIn: parent; spacing: 2
                    Repeater {
                        model: root.keyCategories
                        Rectangle {
                            property bool isSel: root.activeTab === index
                            implicitHeight: 22
                            implicitWidth: tabText.implicitWidth + 16
                            radius: 5
                            color: isSel ? "#3F3F46" : (tabMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
                            border.width: isSel ? 1 : 0
                            border.color: Qt.rgba(1, 1, 1, 0.16)

                            Text {
                                id: tabText; anchors.centerIn: parent
                                text: modelData
                                color: isSel ? "#F5F5F7" : "#98989D"
                                font.family: "Inter"; font.pixelSize: 11; font.weight: isSel ? 600 : 500
                            }
                            MouseArea {
                                id: tabMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { tourCtrl.playSound("tap"); root.activeTab = index; }
                            }
                        }
                    }
                }
            }
        }

        // ── 2-Column macOS Grouped Inset Cards ──────────────────────────────
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: gridLayout.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            GridLayout {
                id: gridLayout
                columns: 2
                width: parent.width
                columnSpacing: 10
                rowSpacing: 7

                Repeater {
                    model: root.allShortcuts

                    Rectangle {
                        visible: root.activeTab === 0 || root.activeTab === modelData.category
                        Layout.fillWidth: true
                        implicitHeight: 42
                        radius: 9
                        color: cardMouse.containsMouse ? Qt.rgba(10/255, 132/255, 255/255, 0.14)
                                                       : Qt.rgba(1, 1, 1, 0.045)
                        border.width: 1
                        border.color: cardMouse.containsMouse ? "#0A84FF" : Qt.rgba(1, 1, 1, 0.08)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 9

                            Rectangle {
                                width: 26; height: 26; radius: 6
                                color: modelData.col
                                border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.25)
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: "#FFFFFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 0
                                RowLayout {
                                    spacing: 5
                                    Text {
                                        text: modelData.title
                                        color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600
                                    }
                                    Rectangle {
                                        visible: modelData.action !== null
                                        implicitHeight: 14; implicitWidth: liveTag.implicitWidth + 8; radius: 4
                                        color: Qt.rgba(10/255, 132/255, 255/255, 0.18)
                                        Text {
                                            id: liveTag; anchors.centerIn: parent
                                            text: "Try ↗"; color: "#64D2FF"; font.family: "Inter"; font.pixelSize: 8; font.weight: 600
                                        }
                                    }
                                }
                                Text {
                                    text: modelData.desc
                                    color: "#98989D"; font.family: "Inter"; font.pixelSize: 10
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                            }

                            Row {
                                spacing: 3
                                Repeater {
                                    model: modelData.keys
                                    Keycap {
                                        text: modelData
                                        isAccent: cardMouse.containsMouse
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse; anchors.fill: parent; hoverEnabled: true
                            cursorShape: modelData.action !== null ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onEntered: root.hoveredIndex = index
                            onClicked: {
                                root.hoveredIndex = index;
                                if (modelData.action !== null) {
                                    tourCtrl.playSound("click");
                                    modelData.action();
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Bottom Editorial Navigation Bar ─────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Active Chord: " + root.allShortcuts[root.hoveredIndex].title
                color: "#8E8E93"
                font.family: "Inter"
                font.pixelSize: 11
                font.weight: 600
            }

            Row {
                spacing: 4
                Repeater {
                    model: root.allShortcuts[root.hoveredIndex].keys
                    Keycap { text: modelData; isAccent: true }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitHeight: 34
                implicitWidth: nxtRow.implicitWidth + 22
                radius: 8
                gradient: Gradient {
                    GradientStop { position: 0.0; color: nxtArea.containsMouse ? "#2894FF" : "#188BFF" }
                    GradientStop { position: 1.0; color: nxtArea.containsMouse ? "#0A84FF" : "#007AFF" }
                }
                border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.25)

                Row {
                    id: nxtRow; anchors.centerIn: parent; spacing: 6
                    Text { text: "Next: TitanFocus Deep Work"; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600 }
                    Text { text: "→"; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 13; font.weight: Font.Bold }
                }

                MouseArea {
                    id: nxtArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tourCtrl.playSound("tap");
                        root.jumpToChapter(6);
                    }
                }
            }
        }
    }
}
