import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI
import "../components"

Item {
    id: root

    property int activeTab: 0

    readonly property var keyCategories: ["All", "General", "Windows", "Titan Tools"]

    readonly property var allShortcuts: [
        { keys: ["SUPER", "RETURN"], title: "Terminal", desc: "Launches GPU-accelerated Kitty terminal", category: 1, action: function() { tourCtrl.launchTerminal(); } },
        { keys: ["SUPER", "SPACE"],  title: "Spotlight", desc: "Instant fuzzy application & file search", category: 3, action: function() { tourCtrl.toggleSpotlight(); } },
        { keys: ["SUPER", "W"],      title: "Web Browser", desc: "Launches TitanBrowser WebEngine", category: 1, action: function() { tourCtrl.launchBrowser(); } },
        { keys: ["SUPER", "E"],      title: "File Manager", desc: "Opens Dolphin file browser", category: 1, action: function() { tourCtrl.launchFileManager(); } },
        { keys: ["SUPER", "Q"],      title: "Close Window", desc: "Kills active focused window", category: 2, action: null },
        { keys: ["SUPER", "F"],      title: "Fullscreen", desc: "Toggles edge-to-edge monocle mode", category: 2, action: null },
        { keys: ["SUPER", "ALT", "SPACE"], title: "Float / Tile", desc: "Toggles floating state of window", category: 2, action: null },
        { keys: ["SUPER", "P"],      title: "Split Direction", desc: "Toggles dwindle horizontal/vertical split", category: 2, action: null },
        { keys: ["SUPER", "1..9"],   title: "Switch Workspace", desc: "Jumps directly to workspace 1 through 9", category: 2, action: null },
        { keys: ["SUPER", "N"],      title: "Control Center", desc: "Opens quick settings & audio router", category: 3, action: function() { tourCtrl.toggleControlCenter(); } },
        { keys: ["SUPER", "M"],      title: "System Monitor", desc: "Toggles live CPU, RAM & THM v3 cockpit", category: 3, action: function() { tourCtrl.toggleSysmon(); } },
        { keys: ["SUPER", "ALT", "F"], title: "TitanFocus", desc: "Toggles top Zen focus timer pill", category: 3, action: function() { tourCtrl.toggleFocus(); } },
        { keys: ["SUPER", ","],      title: "OS Settings", desc: "Opens ArchTitan system preferences", category: 3, action: function() { tourCtrl.launchSettings(); } },
        { keys: ["SUPER", "SHIFT", "P"], title: "Cycle Power", desc: "Cycles Eco -> Balanced -> Performance", category: 3, action: null }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        // ── Header & Category Tabs ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                spacing: 2
                Text {
                    text: "HYPRLAND SHORTCUTS & CHEAT SHEET"
                    color: TitanTheme.accent
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.0
                }
                Text {
                    text: "Fast keyboard workflows engineered for high-velocity navigation."
                    color: TitanTheme.textLow
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            // Category Filter Pills
            Row {
                spacing: 6
                Repeater {
                    model: root.keyCategories
                    Rectangle {
                        property bool isSel: root.activeTab === index
                        implicitHeight: 28
                        implicitWidth: tabLabel.implicitWidth + 18
                        radius: 14
                        color: isSel ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.22)
                                     : (tabMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.5))
                        border.width: 1
                        border.color: isSel ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.1)

                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: isSel ? TitanTheme.accent : TitanTheme.textMid
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            font.weight: isSel ? Font.Bold : Font.Medium
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

        // ── 2-Column Shortcut Grid ──────────────────────────────────────────────
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
                rowSpacing: 10

                Repeater {
                    model: root.allShortcuts

                    Rectangle {
                        visible: root.activeTab === 0 || root.activeTab === modelData.category
                        Layout.fillWidth: true
                        implicitHeight: 52
                        radius: 8
                        color: cardMouse.containsMouse ? Qt.rgba(TitanTheme.surface1.r, TitanTheme.surface1.g, TitanTheme.surface1.b, 0.7)
                                                       : Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.5)
                        border.width: 1
                        border.color: cardMouse.containsMouse ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.35)
                                                              : Qt.rgba(1, 1, 1, 0.07)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // Keycaps
                            Row {
                                spacing: 4
                                Repeater {
                                    model: modelData.keys
                                    Keycap {
                                        text: modelData
                                        implicitHeight: 22
                                    }
                                }
                            }

                            // Title & Description
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: modelData.title
                                    color: TitanTheme.textHigh
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: 600
                                }
                                Text {
                                    text: modelData.desc
                                    color: TitanTheme.textLow
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Optional Run Action icon
                            Text {
                                visible: modelData.action !== null
                                text: "\uf04b" // Play / test icon
                                color: cardMouse.containsMouse ? TitanTheme.accent : TitanTheme.textLow
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 10
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: modelData.action !== null ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
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
