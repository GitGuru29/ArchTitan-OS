import QtQuick
import "../components"
import "../animations"

/**
 * QuickSettingsScene — Slide 05: "Control Everything"
 * Matches panel 5/10 in Image 2 (media_1795534773489_da4d70fb.jpg):
 *   - Left: "Control Everything", "Manage connectivity, sound, brightness and more from one place.",
 *           and "[ ⌘  Super + N ]" badge
 *   - Right: Rounded square frosted-glass Control Center panel with 4 top circular
 *            toggles (Wi-Fi, Bluetooth, Airplane, Lock), horizontal Brightness &
 *            Volume sliders + vertical pill slider, "Nothing Playing" media card,
 *            and 4 bottom quick action icons.
 */
Item {
    id: root

    property bool wifiOn: true
    property bool btOn: true
    property bool airplaneOn: false
    property bool lockOn: false
    property real brightnessVal: 0.72
    property real volumeVal: 0.38

    onVisibleChanged: if (visible) stagger.trigger()

    StaggerReveal {
        id: stagger
        durationMs: 550
    }

    SlideContainer {
        anchors.fill: parent
        title: "Control Everything"
        subtitle: "Manage connectivity,\nsound, brightness and\nmore from one place."
        shortcutText: "Super + N"
        featureId: "quicksettings"
        featureExplored: typeof tourCtrl !== "undefined" ? tourCtrl.featureTried : false
        onShortcutTriggered: if (typeof tourCtrl !== "undefined") tourCtrl.toggleLiveFeature()

        // Right Column Artwork: Liquid Glass Control Center Panel (exact match to Image 2 center panel)
        Rectangle {
            anchors.centerIn: parent
            width: 286
            height: 304
            radius: 28
            color: "#D80E1728" // tdl-allow
            border.width: 1.5
            border.color: "#5560A5FA" // tdl-allow

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                // Row 1: 4 circular connectivity toggles (Wi-Fi, Bluetooth, Airplane, Lock)
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    Repeater {
                        model: [
                            { glyph: "󰖩", active: root.wifiOn, idx: 0 },
                            { glyph: "󰂯", active: root.btOn, idx: 1 },
                            { glyph: "✈", active: root.airplaneOn, idx: 2 },
                            { glyph: "🔒", active: root.lockOn, idx: 3 }
                        ]

                        Rectangle {
                            width: 48
                            height: 48
                            radius: 24
                            color: modelData.active ? "#1D7AFC" : "#1B263B" // tdl-allow
                            border.width: 1
                            border.color: modelData.active ? "#60A5FA" : "#33FFFFFF" // tdl-allow

                            Text {
                                anchors.centerIn: parent
                                text: modelData.glyph
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: "#FFFFFF"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.idx === 0) root.wifiOn = !root.wifiOn;
                                    else if (modelData.idx === 1) root.btOn = !root.btOn;
                                    else if (modelData.idx === 2) root.airplaneOn = !root.airplaneOn;
                                    else root.lockOn = !root.lockOn;
                                    if (typeof tourCtrl !== "undefined") tourCtrl.playSound("tap");
                                }
                            }
                        }
                    }
                }

                // Row 2: Brightness + Sound sliders on left, vertical pill slider on right
                Item {
                    width: parent.width
                    height: 92

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width - 48
                        radius: 16
                        color: "#152033" // tdl-allow
                        border.width: 1
                        border.color: "#26FFFFFF"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 14

                            // Brightness bar
                            Row {
                                width: parent.width
                                spacing: 10
                                Text { text: "☀"; font.pixelSize: 13; color: "#94A3B8"; anchors.verticalCenter: parent.verticalCenter } // tdl-allow
                                Rectangle {
                                    width: parent.width - 26; height: 8; radius: 4; color: "#28354A" // tdl-allow
                                    anchors.verticalCenter: parent.verticalCenter
                                    Rectangle {
                                        width: parent.width * root.brightnessVal
                                        height: parent.height; radius: 4; color: "#93C5FD" // tdl-allow
                                    }
                                }
                            }

                            // Volume pill slider
                            Rectangle {
                                width: parent.width
                                height: 28
                                radius: 14
                                color: "#223046" // tdl-allow

                                Rectangle {
                                    width: Math.max(36, parent.width * root.volumeVal)
                                    height: parent.height
                                    radius: 14
                                    color: "#BFDBFE" // tdl-allow

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "🔊"
                                        font.pixelSize: 12
                                        color: "#0F172A" // tdl-allow
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        root.volumeVal = Math.max(0.2, Math.min(1.0, mouse.x / width));
                                    }
                                }
                            }
                        }
                    }

                    // Right vertical pill slider
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 36
                        radius: 18
                        color: "#93C5FD" // tdl-allow
                        border.width: 1
                        border.color: "#60A5FA" // tdl-allow
                    }
                }

                // Row 3: Media mini-card ("Nothing Playing")
                Rectangle {
                    width: parent.width
                    height: 54
                    radius: 14
                    color: "#152033" // tdl-allow
                    border.width: 1
                    border.color: "#22FFFFFF"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Rectangle {
                            width: 32; height: 32; radius: 8
                            color: "#24344D" // tdl-allow
                            Text { anchors.centerIn: parent; text: "A"; font.family: "Inter"; font.pixelSize: 14; font.weight: Font.Bold; color: "#93C5FD" } // tdl-allow
                        }

                        Column {
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: "Nothing Playing"; font.family: "Inter"; font.pixelSize: 12; font.weight: Font.DemiBold; color: "#E2E8F0" } // tdl-allow
                            Text { text: "⏮    ⏯    ⏭"; font.family: "Inter"; font.pixelSize: 10; color: "#94A3B8" } // tdl-allow
                        }
                    }
                }

                // Row 4: 4 bottom quick icons (Bell, Moon/DND, Sync/Profile, Power)
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 28

                    Repeater {
                        model: ["🔔", "🌙", "⟳", "⏻"]
                        Text {
                            text: modelData
                            font.pixelSize: 15
                            color: "#CBD5E1" // tdl-allow

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (typeof tourCtrl !== "undefined") tourCtrl.toggleLiveFeature()
                            }
                        }
                    }
                }
            }
        }
    }
}
