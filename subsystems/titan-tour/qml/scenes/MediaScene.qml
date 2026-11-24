import QtQuick
import QtQuick.Shapes
import "../components"

/**
 * MediaScene — Slide 06: "Always in the Loop"
 * Matches panel 6/10 in Image 2 (media_1795534773489_da4d70fb.jpg):
 *   - Left: "Always in the Loop", "Enjoy a sleek media HUD with real-time controls.",
 *           and "[ ⌘  Super + M ]" badge
 *   - Right: Flowing luminous cyan light ribbons across the dark canvas + floating
 *            Dynamic Island media capsule ("Dream Bigger · ArchTitan Music" + ⏮ ⏸ ⏭).
 */
Item {
    id: root

    property bool playing: true

    SlideContainer {
        anchors.fill: parent
        title: "Always in the Loop"
        subtitle: "Enjoy a sleek media HUD\nwith real-time controls."
        shortcutText: "Super + M"
        featureId: "media"
        featureExplored: typeof tourCtrl !== "undefined" ? tourCtrl.featureTried : false
        onShortcutTriggered: if (typeof tourCtrl !== "undefined") tourCtrl.toggleLiveFeature()

        // Right Column Artwork: Flowing Cyan Soundwave Ribbons + Dynamic Island Capsule
        Item {
            anchors.fill: parent

            // Luminous cyan wave ribbons below the capsule (matching Image 2 panel 6/10)
            Shape {
                anchors.fill: parent

                ShapePath {
                    strokeColor: "#8800D2FF"
                    strokeWidth: 2.2
                    fillColor: "transparent"
                    startX: 10; startY: parent.height * 0.86
                    PathCubic {
                        x: parent.width - 10; y: parent.height * 0.56
                        control1X: parent.width * 0.34; control1Y: parent.height * 0.62
                        control2X: parent.width * 0.68; control2Y: parent.height * 0.78
                    }
                }

                ShapePath {
                    strokeColor: "#5538BDF8"
                    strokeWidth: 1.6
                    fillColor: "transparent"
                    startX: 24; startY: parent.height * 0.92
                    PathCubic {
                        x: parent.width - 6; y: parent.height * 0.65
                        control1X: parent.width * 0.42; control1Y: parent.height * 0.70
                        control2X: parent.width * 0.74; control2Y: parent.height * 0.86
                    }
                }

                ShapePath {
                    strokeColor: "#3300D2FF"
                    strokeWidth: 1.2
                    fillColor: "transparent"
                    startX: 0; startY: parent.height * 0.76
                    PathCubic {
                        x: parent.width; y: parent.height * 0.48
                        control1X: parent.width * 0.30; control1Y: parent.height * 0.54
                        control2X: parent.width * 0.66; control2Y: parent.height * 0.68
                    }
                }
            }

            // Floating Dynamic Island Media Capsule
            Rectangle {
                id: mediaCapsule
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 28
                width: Math.min(parent.width - 16, 396)
                height: 82
                radius: 41
                color: "#E60A1324" // tdl-allow
                border.width: 1.5
                border.color: "#6638BDF8"

                // Ambient glow under capsule
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -12
                    width: parent.width * 0.65
                    height: 24
                    radius: 12
                    color: "#3300D2FF"
                    z: -1
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    // Circular violet-cyan album artwork disc with ArchTitan A mark
                    Rectangle {
                        width: 52
                        height: 52
                        radius: 26
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#C084FC" } // tdl-allow
                            GradientStop { position: 0.5; color: "#6366F1" } // tdl-allow
                            GradientStop { position: 1.0; color: "#00D2FF" }
                        }
                        border.width: 1.5
                        border.color: "#88FFFFFF"

                        Text {
                            anchors.centerIn: parent
                            text: "▲"
                            font.family: "Inter"
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            color: "#FFFFFF"
                        }
                    }

                    // Track title & subtitle
                    Column {
                        spacing: 3
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "Dream Bigger"
                            font.family: "Inter"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: "#FFFFFF"
                        }

                        Text {
                            text: "ArchTitan Music"
                            font.family: "Inter"
                            font.pixelSize: 12
                            color: "#94A3B8" // tdl-allow
                        }
                    }
                }

                // Right transport controls: ⏮   ⏸   ⏭
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 18

                    Text {
                        text: "⏮"
                        font.pixelSize: 15
                        color: "#CBD5E1" // tdl-allow
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.playing ? "⏸" : "▶"
                        font.pixelSize: 17
                        color: "#FFFFFF"
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.playing = !root.playing
                        }
                    }

                    Text {
                        text: "⏭"
                        font.pixelSize: 15
                        color: "#CBD5E1" // tdl-allow
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (typeof tourCtrl !== "undefined") tourCtrl.toggleLiveFeature()
                }
            }
        }
    }
}
