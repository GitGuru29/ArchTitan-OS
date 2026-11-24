import QtQuick

/**
 * AnimatedBackground — 3-layer Fluted Gradient Backdrop matching Image 1 & Image 2:
 *   Layer 1: Deep navy, electric cyan, violet, and warm coral/red gradient with slow 24s drift.
 *   Layer 2: Vertical fluted glass ridges (~72 vertical light columns with subtle opacity modulation).
 *   Layer 3: Ambient cyan/sapphire glow behind the centered floating dark window.
 */
Item {
    id: root

    property bool active: true
    property bool reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false
    property real driftPhase: 0.0
    property color slideAccent: "#00D2FF"

    NumberAnimation on driftPhase {
        running: root.active && root.visible && !root.reducedMotion
        from: 0.0
        to: 1.0
        duration: 24000
        loops: Animation.Infinite
        easing.type: Easing.InOutSine
    }

    // Layer 1: Base horizontal spectrum (Deep Navy → Electric Cyan → Royal Violet → Coral/Orange-Red)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: "#03091C" } // tdl-allow
            GradientStop { position: 0.16; color: "#042868" } // tdl-allow
            GradientStop { position: 0.36; color: "#0088DD" } // tdl-allow
            GradientStop { position: 0.56; color: "#00C8FF" } // tdl-allow
            GradientStop { position: 0.72; color: "#6A5ACD" } // tdl-allow
            GradientStop { position: 0.87; color: "#E05A47" } // tdl-allow
            GradientStop { position: 1.00; color: "#FF4B2B" } // tdl-allow
        }
    }

    // Vertical depth gradient (darker navy at top-left, warmer violet/cyan glow at bottom)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#55030712" } // tdl-allow
            GradientStop { position: 0.5; color: "transparent" }
            GradientStop { position: 1.0; color: "#441E1B4B" } // tdl-allow
        }
    }

    // Layer 2: Vertical Fluted Glass Ridges (76 subtle vertical columns)
    Row {
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: 76

            Item {
                width: root.width / 76
                height: root.height

                // Left specular highlight rib
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(1, parent.width * 0.42)
                    color: "#FFFFFF"
                    opacity: 0.05 + 0.05 * Math.sin((index / 76.0) * Math.PI * 3.0 + root.driftPhase * Math.PI * 2)
                }

                // Right flute trough shadow
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(1, parent.width * 0.35)
                    color: "#000000"
                    opacity: 0.10
                }
            }
        }
    }

    // Layer 3: Soft ambient glow behind the centered floating TourWindow
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.86
        height: parent.height * 0.84
        radius: 36
        color: root.slideAccent
        opacity: 0.14
    }
}
