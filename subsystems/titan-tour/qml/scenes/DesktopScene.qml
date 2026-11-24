import QtQuick
import "../components"
import "../animations"

/**
 * DesktopScene — Slide 02: "Your Desktop"
 * Matches panel 2/10 in Image 2 (media_1795534773489_da4d70fb.jpg):
 *   - Left: "Your Desktop", "A clean, powerful and beautiful workspace.",
 *           and 3 icon rows: Waybar · Dynamic Workspaces · Modern Glass UI
 *   - Right: Sleek desktop monitor card with cosmic wallpaper, top Waybar,
 *            and floating bottom glass dock with 7 glowing icons.
 */
Item {
    id: root

    property int selectedRow: 0
    property bool explored: false

    onVisibleChanged: if (visible) stagger.trigger()

    StaggerReveal {
        id: stagger
        durationMs: 550
    }

    SlideContainer {
        anchors.fill: parent
        title: "Your Desktop"
        subtitle: "A clean, powerful and\nbeautiful workspace."

        leftExtra: [
            Column {
                width: parent.width
                spacing: 11

                Repeater {
                    model: [
                        { icon: "▣", label: "Waybar" },
                        { icon: "⊞", label: "Dynamic Workspaces" },
                        { icon: "✦", label: "Modern Glass UI" }
                    ]

                    Row {
                        spacing: 12
                        opacity: stagger.itemFactor(index, 3)

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 7
                            color: root.selectedRow === index ? "#3300D2FF" : "#1800D2FF"
                            border.width: 1
                            border.color: root.selectedRow === index ? "#00D2FF" : "#4400D2FF"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: "Inter"
                                font.pixelSize: 12
                                color: "#00D2FF"
                            }
                        }

                        Text {
                            text: modelData.label
                            font.family: "Inter"
                            font.pixelSize: 14
                            font.weight: root.selectedRow === index ? Font.Bold : Font.Medium
                            color: root.selectedRow === index ? "#FFFFFF" : "#CBD5E1" // tdl-allow
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        MouseArea {
                            width: 210
                            height: 28
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedRow = index;
                                root.explored = true;
                                if (typeof tourCtrl !== "undefined") tourCtrl.playSound("tap");
                            }
                        }
                    }
                }
            }
        ]

        // Right Column Artwork: Desktop Monitor Frame with Waybar, Cosmic Planet Wallpaper & Glass Dock
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width, 460)
            height: Math.min(parent.height - 16, 285)
            radius: 16
            color: "#070C18" // tdl-allow
            border.width: 1.5
            border.color: "#3800D2FF"
            clip: true

            // Wallpaper image inside monitor
            Image {
                anchors.fill: parent
                anchors.margins: 2
                source: typeof tourCtrl !== "undefined" ? tourCtrl.activeWallpaperUrl : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
                opacity: 0.72
            }

            // Cosmic planet orb & mountain glow overlay matching Image 2's desktop preview
            Rectangle {
                width: 150
                height: 150
                radius: 75
                x: parent.width * 0.46
                y: parent.height * 0.18
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#AA8B5CF6" } // tdl-allow
                    GradientStop { position: 0.5; color: "#7700D2FF" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Top Waybar strip entering from top
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 8
                height: 22
                radius: 7
                color: "#CC090F1C" // tdl-allow
                border.width: root.selectedRow === 0 ? 1.5 : 1
                border.color: root.selectedRow === 0 ? "#00D2FF" : "#28FFFFFF"

                // Left workspace indicators
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Repeater {
                        model: 5
                        Rectangle {
                            width: index === 0 ? 12 : 5
                            height: 5
                            radius: 2.5
                            color: index === 0 ? "#00D2FF" : (root.selectedRow === 1 ? "#38BDF8" : "#475569") // tdl-allow
                        }
                    }
                }

                // Center clock pill
                Text {
                    anchors.centerIn: parent
                    text: "09:41  ·  ArchTitan"
                    font.family: "Inter"
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    color: "#CBD5E1" // tdl-allow
                }

                // Right system status icons
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Repeater {
                        model: ["#00D2FF", "#38BDF8", "#A6E3A1", "#CBA6F7"]
                        Rectangle {
                            width: 6; height: 6; radius: 3; color: modelData
                        }
                    }
                }
            }

            // Bottom floating glass dock with 7 app icons rising into position
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                anchors.horizontalCenter: parent.horizontalCenter
                width: 210
                height: 34
                radius: 11
                color: "#CC0D1526" // tdl-allow
                border.width: root.selectedRow === 2 ? 1.5 : 1
                border.color: root.selectedRow === 2 ? "#00D2FF" : "#33FFFFFF"

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Repeater {
                        model: [
                            "#00D2FF", "#3B82F6", "#8B5CF6", "#10B981", "#F59E0B", "#EC4899", "#64748B" // tdl-allow
                        ]

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 6
                            color: modelData
                            border.width: 1
                            border.color: "#44FFFFFF"
                        }
                    }
                }
            }
        }
    }
}
