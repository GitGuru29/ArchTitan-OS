import QtQuick
import QtQuick.Shapes
import "../components"

/**
 * CompletionScene — Slide 10: "You're Ready"
 * Matches the wide bottom banner 10/10 in Image 2 (media_1795534773489_da4d70fb.jpg):
 *   - Panoramic cosmic mountain & glowing moon backdrop on the right side
 *   - Left of center: Glowing 3D cyan ArchTitan "A" chevron logo with orbital rings
 *                     and cyan light sweep
 *   - Vertical divider line
 *   - Right of divider:
 *       "You're Ready"
 *       "Your workspace. Your rules. Your Titan."
 *       [ Enter ArchTitan → ]   [ Explore Features Again ]
 */
Item {
    id: root

    property real sweepVal: -1.0

    signal enterDesktopClicked()
    signal replayClicked()

    onVisibleChanged: {
        if (visible && (typeof tourCtrl === "undefined" || !tourCtrl.reducedMotion)) {
            sweepAnim.restart();
        }
    }

    NumberAnimation {
        id: sweepAnim
        target: root
        property: "sweepVal"
        from: 0.0
        to: 1.0
        duration: 1200
        easing.type: Easing.InOutCubic
    }

    // Cosmic Violet/Cyan Planet & Mountain Horizon on the Right Side (matching Image 2 10/10)
    Item {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * 0.54
        clip: true

        // High-res mountain wallpaper fading in on the right
        Image {
            anchors.fill: parent
            source: typeof tourCtrl !== "undefined" ? tourCtrl.activeWallpaperUrl : ""
            fillMode: Image.PreserveAspectCrop
            smooth: true
            opacity: 0.68
        }

        // Feathered cosmic violet/cyan moon glow above the mountain ridge
        Shape {
            width: 320
            height: 320
            x: parent.width * 0.28
            y: -20

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: 160; centerY: 160; centerRadius: 155
                    focalX: 160; focalY: 160
                    GradientStop { position: 0.0; color: "#AAEDE9FE" } // tdl-allow
                    GradientStop { position: 0.35; color: "#778B5CF6" } // tdl-allow
                    GradientStop { position: 0.7; color: "#3300D2FF" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                PathRectangle { x: 0; y: 0; width: 320; height: 320 }
            }
        }

        // Smooth left-to-right obsidian fade so the left side stays pure deep obsidian
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#060A12" } // tdl-allow
                GradientStop { position: 0.38; color: "#CC060A12" } // tdl-allow
                GradientStop { position: 1.0; color: "#22060A12" } // tdl-allow
            }
        }
    }

    // Center-Left Hero Layout: [ 3D Cyan Titan Logo ]  |  [ You're Ready + Buttons ]
    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -12
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.11
        spacing: 38

        // Left: 3D Cyan ArchTitan "A" Emblem with orbital rings & finale light sweep
        Item {
            width: 170
            height: 170
            anchors.verticalCenter: parent.verticalCenter

            // Tilted orbital ring around the finale logo
            Rectangle {
                anchors.centerIn: parent
                width: 184
                height: 62
                radius: 31
                rotation: -18
                color: "transparent"
                border.width: 1.4
                border.color: "#5500D2FF"
            }

            TitanLogo {
                anchors.centerIn: parent
                size: 136
                metallicStyle: false
                showFlare: true
                showRings: false
                sweepProgress: root.sweepVal
            }
        }

        // Vertical subtle divider line (matching Image 2 10/10)
        Rectangle {
            width: 1
            height: 128
            color: "#2E475569" // tdl-allow
            anchors.verticalCenter: parent.verticalCenter
        }

        // Right of divider: "You're Ready", "Your workspace. Your rules. Your Titan.", and Action Pills
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Text {
                text: "You're Ready"
                font.family: "Inter"
                font.pixelSize: 40
                font.weight: Font.Bold
                color: "#FFFFFF"
            }

            Text {
                text: "Your workspace. Your rules. Your Titan."
                font.family: "Inter"
                font.pixelSize: 16
                color: "#94A3B8" // tdl-allow
            }

            Row {
                spacing: 14

                // Primary cyan pill button: "Enter ArchTitan →"
                Rectangle {
                    width: enterRow.implicitWidth + 36
                    height: 40
                    radius: 20
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: enterArea.pressed ? "#0284C7" : "#00B4D8" } // tdl-allow
                        GradientStop { position: 1.0; color: enterArea.pressed ? "#00B4D8" : "#00D2FF" } // tdl-allow
                    }

                    scale: enterArea.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                    Row {
                        id: enterRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "Enter ArchTitan"
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: "#FFFFFF"
                        }

                        Text {
                            text: "→"
                            font.family: "Inter"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: "#FFFFFF"
                        }
                    }

                    MouseArea {
                        id: enterArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.enterDesktopClicked()
                    }
                }

                // Secondary dark glass pill button: "Explore Features Again"
                Rectangle {
                    width: replayTxt.implicitWidth + 36
                    height: 40
                    radius: 20
                    color: replayArea.pressed ? "#1E293B" : (replayArea.containsMouse ? "#152032" : "#0C1320") // tdl-allow
                    border.width: 1
                    border.color: replayArea.containsMouse ? "#475569" : "#283548" // tdl-allow

                    scale: replayArea.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                    Text {
                        id: replayTxt
                        anchors.centerIn: parent
                        text: "Explore Features Again"
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: "#CBD5E1" // tdl-allow
                    }

                    MouseArea {
                        id: replayArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.replayClicked()
                    }
                }
            }
        }
    }
}
