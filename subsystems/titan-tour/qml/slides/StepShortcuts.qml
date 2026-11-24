import QtQuick
import QtQuick.Layouts
import "../components"

Item {
    id: root

    property int activeTab: 0
    property int hoveredIndex: 0

    readonly property var keyCategories: ["All Shortcuts", "Apps & Search", "Window Tiling", "System Tools"]

    readonly property var allShortcuts: [
        { keys: ["SUPER", "Space"],       icon: "\uf002", col: "#0A84FF", title: "Spotlight Search", desc: "Launch apps, search files & commands", category: 1, action: function() { tourCtrl.toggleSpotlight(); } },
        { keys: ["SUPER", "Return"],      icon: "\uf120", col: "#30D158", title: "Terminal",         desc: "Open GPU-accelerated Kitty terminal", category: 1, action: function() { tourCtrl.launchTerminal(); } },
        { keys: ["SUPER", "W"],           icon: "\uf268", col: "#5E5CE6", title: "Web Browser",      desc: "Launch TitanBrowser WebEngine", category: 1, action: function() { tourCtrl.launchBrowser(); } },
        { keys: ["SUPER", "E"],           icon: "\uf07b", col: "#64D2FF", title: "Files",            desc: "Open Dolphin file manager", category: 1, action: function() { tourCtrl.launchFileManager(); } },
        { keys: ["SUPER", "Q"],           icon: "\uf00d", col: "#FF453A", title: "Close Window",     desc: "Close the currently focused window", category: 2, action: null },
        { keys: ["SUPER", "F"],           icon: "\uf065", col: "#BF5AF2", title: "Fullscreen",       desc: "Expand active window edge-to-edge", category: 2, action: null },
        { keys: ["SUPER", "Alt", "Space"],icon: "\uf2d2", col: "#FF9F0A", title: "Float / Tile",     desc: "Toggle floating or tiled window mode", category: 2, action: null },
        { keys: ["SUPER", "1–9"],         icon: "\uf009", col: "#0A84FF", title: "Switch Workspace", desc: "Jump directly to workspace 1 through 9", category: 2, action: null },
        { keys: ["SUPER", "N"],           icon: "\uf1de", col: "#5E5CE6", title: "Control Center",   desc: "Wi-Fi, Bluetooth, audio & brightness", category: 3, action: function() { tourCtrl.toggleControlCenter(); } },
        { keys: ["SUPER", "M"],           icon: "\uf080", col: "#30D158", title: "System Monitor",   desc: "Real-time CPU, RAM & PSI telemetry", category: 3, action: function() { tourCtrl.toggleSysmon(); } },
        { keys: ["SUPER", "Alt", "F"],    icon: "\uf06e", col: "#FF9F0A", title: "TitanFocus",       desc: "Toggle top-edge Zen focus session timer", category: 3, action: function() { tourCtrl.toggleFocus(); } },
        { keys: ["SUPER", ","],           icon: "\uf013", col: "#8E8E93", title: "System Settings",  desc: "Open ArchTitan Preferences app", category: 3, action: function() { tourCtrl.launchSettings(); } }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 14
        anchors.bottomMargin: 12
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        spacing: 10

        // ── Top Bar: Title Left + Live macOS Key Visualizer Pill Right ──────
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                spacing: 2

                Text {
                    text: "Keyboard Shortcuts"
                    color: "#F5F5F7"
                    font.family: "Inter"
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }

                Text {
                    text: "Hover any shortcut to inspect, or click an app shortcut to trigger it live."
                    color: "#98989D"
                    font.family: "Inter"
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            // Live Interactive Key Visualizer HUD Pill
            Rectangle {
                implicitHeight: 38
                implicitWidth: hudRow.implicitWidth + 20
                radius: 10
                color: Qt.rgba(10/255, 132/255, 255/255, 0.14)
                border.width: 1
                border.color: "#0A84FF"

                Row {
                    id: hudRow
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        width: 22; height: 22; radius: 6
                        color: root.allShortcuts[root.hoveredIndex].col
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent
                            text: root.allShortcuts[root.hoveredIndex].icon
                            color: "#FFFFFF"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        text: root.allShortcuts[root.hoveredIndex].title + ":"
                        color: "#F5F5F7"
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: 600
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            model: root.allShortcuts[root.hoveredIndex].keys
                            Keycap {
                                text: modelData
                                isAccent: true
                            }
                        }
                    }
                }
            }
        }

        // ── macOS Segmented Filter Control ──────────────────────────────────
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitHeight: 30
            implicitWidth: segRow.implicitWidth + 6
            radius: 8
            color: Qt.rgba(0, 0, 0, 0.26)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            Row {
                id: segRow
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: root.keyCategories

                    Rectangle {
                        property bool isSel: root.activeTab === index
                        implicitHeight: 24
                        implicitWidth: tabText.implicitWidth + 22
                        radius: 6
                        color: isSel ? "#3F3F46" : (tabMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
                        border.width: isSel ? 1 : 0
                        border.color: Qt.rgba(1, 1, 1, 0.16)

                        Text {
                            id: tabText
                            anchors.centerIn: parent
                            text: modelData
                            color: isSel ? "#F5F5F7" : "#98989D"
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.weight: isSel ? 600 : 500
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                tourCtrl.playSound("tap");
                                root.activeTab = index;
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
                columnSpacing: 12
                rowSpacing: 8

                Repeater {
                    model: root.allShortcuts

                    Rectangle {
                        visible: root.activeTab === 0 || root.activeTab === modelData.category
                        Layout.fillWidth: true
                        implicitHeight: 46
                        radius: 10
                        color: cardMouse.containsMouse ? Qt.rgba(10/255, 132/255, 255/255, 0.14)
                                                       : Qt.rgba(1, 1, 1, 0.045)
                        border.width: 1
                        border.color: cardMouse.containsMouse
                                      ? "#0A84FF"
                                      : Qt.rgba(1, 1, 1, 0.08)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            // macOS Colorful Squircle Icon
                            Rectangle {
                                width: 30
                                height: 30
                                radius: 7
                                color: modelData.col
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.25)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: "#FFFFFF"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                }
                            }

                            // Action Title & Description
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: modelData.title
                                        color: "#F5F5F7"
                                        font.family: "Inter"
                                        font.pixelSize: 12
                                        font.weight: 600
                                    }

                                    Rectangle {
                                        visible: modelData.action !== null
                                        implicitHeight: 15
                                        implicitWidth: liveTag.implicitWidth + 8
                                        radius: 4
                                        color: Qt.rgba(10/255, 132/255, 255/255, 0.18)
                                        Text {
                                            id: liveTag
                                            anchors.centerIn: parent
                                            text: "Try ↗"
                                            color: "#64D2FF"
                                            font.family: "Inter"
                                            font.pixelSize: 9
                                            font.weight: 600
                                        }
                                    }
                                }

                                Text {
                                    text: modelData.desc
                                    color: "#98989D"
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // 3D Apple Keycaps on the Right
                            Row {
                                spacing: 4
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
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
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
    }
}
