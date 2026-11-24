import QtQuick
import QtQuick.Shapes
import "../components"
import "../animations"

/**
 * SecurityScene — Slide 08: "Protection by Design"
 * Matches panel 8/10 in Image 2 (media_1795534773489_da4d70fb.jpg):
 *   - Left: "Protection\nby Design",
 *           "Stay safe with Titan Sandbox, ArchTitan Guard and snapshots."
 *   - Right: Luminous 3D Holographic Cyan Shield with the ArchTitan "A"
 *            chevron emblem inside and dual glowing orbital rings.
 */
Item {
    id: root

    GlowPulse {
        id: shieldGlow
        active: root.visible
    }

    SlideContainer {
        anchors.fill: parent
        title: "Protection\nby Design"
        subtitle: "Stay safe with Titan Sandbox,\nArchTitan Guard and snapshots."

        // Right Column Artwork: Glowing 3D Holographic Cyan Shield + Orbital Rings
        Item {
            id: shieldStage
            anchors.fill: parent

            // Feathered radial cyan bloom behind shield (zero hard circle edges)
            Shape {
                anchors.centerIn: parent
                width: 320
                height: 320
                opacity: 0.65 + 0.35 * shieldGlow.value

                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillGradient: RadialGradient {
                        centerX: 160; centerY: 160; centerRadius: 160
                        focalX: 160; focalY: 160
                        GradientStop { position: 0.0; color: "#4400D2FF" }
                        GradientStop { position: 0.5; color: "#1A0284C7" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    PathRectangle { x: 0; y: 0; width: 320; height: 320 }
                }
            }

            // Outer tilted orbital energy ring 1
            Rectangle {
                anchors.centerIn: parent
                width: 268
                height: 92
                radius: 46
                rotation: -16
                color: "transparent"
                border.width: 1.5
                border.color: "#5500D2FF"
            }

            // Outer tilted orbital energy ring 2
            Rectangle {
                anchors.centerIn: parent
                width: 248
                height: 82
                radius: 41
                rotation: 18
                color: "transparent"
                border.width: 1.2
                border.color: "#4438BDF8"
            }

            // 3D Vector Holographic Shield with ArchTitan "A" Chevron inside
            Shape {
                id: shieldShape
                anchors.centerIn: parent
                width: 210
                height: 236
                preferredRendererType: Shape.CurveRenderer

                readonly property real sx: width / 100.0
                readonly property real sy: height / 110.0

                // Outer shield glow body
                ShapePath {
                    strokeColor: "#00D2FF"
                    strokeWidth: 3.0
                    fillGradient: LinearGradient {
                        x1: 20 * shieldShape.sx; y1: 10 * shieldShape.sy
                        x2: 80 * shieldShape.sx; y2: 100 * shieldShape.sy
                        GradientStop { position: 0.0; color: "#5500D2FF" }
                        GradientStop { position: 0.45; color: "#280284C7" }
                        GradientStop { position: 1.0; color: "#4400D2FF" }
                    }
                    startX: 50 * shieldShape.sx; startY: 6 * shieldShape.sy
                    PathQuad {
                        x: 88 * shieldShape.sx; y: 18 * shieldShape.sy
                        controlX: 70 * shieldShape.sx; controlY: 14 * shieldShape.sy
                    }
                    PathQuad {
                        x: 50 * shieldShape.sx; y: 102 * shieldShape.sy
                        controlX: 88 * shieldShape.sx; controlY: 74 * shieldShape.sy
                    }
                    PathQuad {
                        x: 12 * shieldShape.sx; y: 18 * shieldShape.sy
                        controlX: 12 * shieldShape.sx; controlY: 74 * shieldShape.sy
                    }
                    PathQuad {
                        x: 50 * shieldShape.sx; y: 6 * shieldShape.sy
                        controlX: 30 * shieldShape.sx; controlY: 14 * shieldShape.sy
                    }
                }

                // Inner double-line shield rim
                ShapePath {
                    strokeColor: "#887DD3FC" // tdl-allow
                    strokeWidth: 1.5
                    fillColor: "#55061020" // tdl-allow
                    startX: 50 * shieldShape.sx; startY: 14 * shieldShape.sy
                    PathQuad {
                        x: 80 * shieldShape.sx; y: 24 * shieldShape.sy
                        controlX: 66 * shieldShape.sx; controlY: 20 * shieldShape.sy
                    }
                    PathQuad {
                        x: 50 * shieldShape.sx; y: 92 * shieldShape.sy
                        controlX: 80 * shieldShape.sx; controlY: 68 * shieldShape.sy
                    }
                    PathQuad {
                        x: 20 * shieldShape.sx; y: 24 * shieldShape.sy
                        controlX: 20 * shieldShape.sx; controlY: 68 * shieldShape.sy
                    }
                    PathQuad {
                        x: 50 * shieldShape.sx; y: 14 * shieldShape.sy
                        controlX: 34 * shieldShape.sx; controlY: 20 * shieldShape.sy
                    }
                }

                // ArchTitan "A" Chevron inside the Shield
                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillGradient: LinearGradient {
                        x1: 50 * shieldShape.sx; y1: 30 * shieldShape.sy
                        x2: 50 * shieldShape.sx; y2: 72 * shieldShape.sy
                        GradientStop { position: 0.0; color: "#FFFFFF" }
                        GradientStop { position: 0.45; color: "#38BDF8" }
                        GradientStop { position: 1.0; color: "#00D2FF" }
                    }
                    startX: 50 * shieldShape.sx; startY: 30 * shieldShape.sy
                    PathLine { x: 29 * shieldShape.sx; y: 68 * shieldShape.sy }
                    PathLine { x: 40 * shieldShape.sx; y: 68 * shieldShape.sy }
                    PathLine { x: 50 * shieldShape.sx; y: 48 * shieldShape.sy }
                    PathLine { x: 60 * shieldShape.sx; y: 68 * shieldShape.sy }
                    PathLine { x: 71 * shieldShape.sx; y: 68 * shieldShape.sy }
                    PathLine { x: 50 * shieldShape.sx; y: 30 * shieldShape.sy }
                }

                // Glowing cyan crossbar inside the "A"
                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillColor: "#00D2FF"
                    startX: 50 * shieldShape.sx; startY: 54 * shieldShape.sy
                    PathLine { x: 37 * shieldShape.sx; y: 64 * shieldShape.sy }
                    PathLine { x: 63 * shieldShape.sx; y: 64 * shieldShape.sy }
                    PathLine { x: 50 * shieldShape.sx; y: 54 * shieldShape.sy }
                }
            }
        }
    }
}
