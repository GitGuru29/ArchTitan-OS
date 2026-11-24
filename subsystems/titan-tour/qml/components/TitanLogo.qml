import QtQuick
import QtQuick.Shapes
import "../animations"

/**
 * TitanLogo — Sculpted 3D metallic & electric-cyan ArchTitan diamond/chevron emblem
 * matching Image 1 & Image 2, with concentric reticle rings, anamorphic cyan flare
 * lines, breathing glow (never rotating), and optional finale cyan light sweep.
 */
Item {
    id: root

    property int size: 136
    property bool glowing: true
    property bool showFlare: true
    property bool showRings: true
    property bool metallicStyle: true   // true = silver/cyan 3D diamond (Image 1), false = pure cyan A-peak (Image 2)
    property real sweepProgress: -1.0   // 0..1 cyan light sweep for Completion finale

    implicitWidth: size
    implicitHeight: size

    GlowPulse {
        id: pulse
        active: root.visible
    }

    // Soft feathered radial cyan aura behind the emblem (zero hard circle edges)
    Shape {
        anchors.centerIn: parent
        width: root.size * 2.2
        height: root.size * 2.2
        opacity: 0.7 + 0.3 * pulse.value

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: root.size * 1.1
                centerY: root.size * 1.1
                centerRadius: root.size * 1.1
                focalX: centerX
                focalY: centerY
                GradientStop { position: 0.0; color: "#4400D2FF" }
                GradientStop { position: 0.45; color: "#1E0284C7" }
                GradientStop { position: 1.0; color: "transparent" }
            }
            PathRectangle { x: 0; y: 0; width: root.size * 2.2; height: root.size * 2.2 }
        }
    }

    // Concentric subtle circular reticle rings (Image 1)
    Rectangle {
        visible: root.showRings
        anchors.centerIn: parent
        width: root.size * 1.48
        height: root.size * 1.48
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: "#1F00D2FF"
    }

    Rectangle {
        visible: root.showRings
        anchors.centerIn: parent
        width: root.size * 1.12
        height: root.size * 1.12
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: "#2E00D2FF"
    }

    // Horizontal anamorphic cyan lens flare
    Rectangle {
        visible: root.showFlare
        anchors.centerIn: parent
        width: root.size * 2.5
        height: 1.5
        opacity: 0.55 + 0.35 * pulse.value
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.32; color: "#4400D2FF" }
            GradientStop { position: 0.5; color: "#EE00D2FF" }
            GradientStop { position: 0.68; color: "#4400D2FF" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Vertical top light ray
    Rectangle {
        visible: root.showFlare
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        width: 1.5
        height: root.size * 1.15
        opacity: 0.45 + 0.3 * pulse.value
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.7; color: "#5500D2FF" }
            GradientStop { position: 1.0; color: "#CCFFFFFF" }
        }
    }

    // 3D Faceted Diamond / Chevron Peak Emblem (100x100 normalized coordinate space)
    Shape {
        id: emblemShape
        anchors.centerIn: parent
        width: root.size
        height: root.size
         preferredRendererType: Shape.CurveRenderer

        readonly property real s: root.size / 100.0

        // 1. Upper-Left Metallic Silver Wing Facet
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 50 * emblemShape.s; y1: 12 * emblemShape.s
                x2: 14 * emblemShape.s; y2: 56 * emblemShape.s
                GradientStop { position: 0.0; color: root.metallicStyle ? "#FFFFFF" : "#38BDF8" }
                GradientStop { position: 0.55; color: root.metallicStyle ? "#CBD5E1" : "#00D2FF" } // tdl-allow
                GradientStop { position: 1.0; color: root.metallicStyle ? "#64748B" : "#0284C7" } // tdl-allow
            }
            startX: 50 * emblemShape.s; startY: 12 * emblemShape.s
            PathLine { x: 14 * emblemShape.s; y: 52 * emblemShape.s }
            PathLine { x: 27 * emblemShape.s; y: 52 * emblemShape.s }
            PathLine { x: 50 * emblemShape.s; y: 27 * emblemShape.s }
            PathLine { x: 50 * emblemShape.s; y: 12 * emblemShape.s }
        }

        // 2. Upper-Right Dark Titanium Wing Facet
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 50 * emblemShape.s; y1: 12 * emblemShape.s
                x2: 86 * emblemShape.s; y2: 56 * emblemShape.s
                GradientStop { position: 0.0; color: root.metallicStyle ? "#E2E8F0" : "#00D2FF" } // tdl-allow
                GradientStop { position: 0.5; color: root.metallicStyle ? "#475569" : "#0284C7" } // tdl-allow
                GradientStop { position: 1.0; color: root.metallicStyle ? "#1E293B" : "#181825" } // tdl-allow
            }
            startX: 50 * emblemShape.s; startY: 12 * emblemShape.s
            PathLine { x: 86 * emblemShape.s; y: 52 * emblemShape.s }
            PathLine { x: 73 * emblemShape.s; y: 52 * emblemShape.s }
            PathLine { x: 50 * emblemShape.s; y: 27 * emblemShape.s }
            PathLine { x: 50 * emblemShape.s; y: 12 * emblemShape.s }
        }

        // 3. Inner Shadow Recess under Top Chevron
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: "#0B1322" // tdl-allow
            startX: 50 * emblemShape.s; startY: 27 * emblemShape.s
            PathLine { x: 27 * emblemShape.s; y: 52 * emblemShape.s }
            PathLine { x: 50 * emblemShape.s; y: 44 * emblemShape.s }
            PathLine { x: 73 * emblemShape.s; y: 52 * emblemShape.s }
            PathLine { x: 50 * emblemShape.s; y: 27 * emblemShape.s }
        }

        // 4. Lower-Left Cyan Pyramid Facet
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 30 * emblemShape.s; y1: 50 * emblemShape.s
                x2: 50 * emblemShape.s; y2: 86 * emblemShape.s
                GradientStop { position: 0.0; color: "#38BDF8" }
                GradientStop { position: 0.5; color: "#00D2FF" }
                GradientStop { position: 1.0; color: "#0284C7" }
            }
            startX: 50 * emblemShape.s; startY: 50 * emblemShape.s
            PathLine { x: 31 * emblemShape.s; y: 63 * emblemShape.s }
            PathLine { x: 50 * emblemShape.s; y: 86 * emblemShape.s }
            PathLine { x: 50 * emblemShape.s; y: 50 * emblemShape.s }
        }

        // 5. Lower-Right Deep Sapphire Pyramid Facet
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 50 * emblemShape.s; y1: 50 * emblemShape.s
                x2: 70 * emblemShape.s; y2: 86 * emblemShape.s
                GradientStop { position: 0.0; color: "#00D2FF" }
                GradientStop { position: 0.6; color: "#0284C7" }
                GradientStop { position: 1.0; color: "#0C4A6E" } // tdl-allow
            }
            startX: 50 * emblemShape.s; startY: 50 * emblemShape.s
            PathLine { x: 69 * emblemShape.s; y: 63 * emblemShape.s }
            PathLine { x: 50 * emblemShape.s; y: 86 * emblemShape.s }
            PathLine { x: 50 * emblemShape.s; y: 50 * emblemShape.s }
        }

        // 6. Glowing Electric-Cyan Sweeping Inner Arc (the signature blue arch in Image 1)
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 22 * emblemShape.s; y1: 50 * emblemShape.s
                x2: 78 * emblemShape.s; y2: 50 * emblemShape.s
                GradientStop { position: 0.0; color: "#00D2FF" }
                GradientStop { position: 0.5; color: "#7DD3FC" } // tdl-allow
                GradientStop { position: 1.0; color: "#0284C7" }
            }
            startX: 50 * emblemShape.s; startY: 42 * emblemShape.s
            PathQuad {
                x: 77 * emblemShape.s; y: 66 * emblemShape.s
                controlX: 65 * emblemShape.s; controlY: 50 * emblemShape.s
            }
            PathQuad {
                x: 50 * emblemShape.s; y: 50 * emblemShape.s
                controlX: 63 * emblemShape.s; controlY: 54 * emblemShape.s
            }
            PathQuad {
                x: 23 * emblemShape.s; y: 66 * emblemShape.s
                controlX: 37 * emblemShape.s; controlY: 54 * emblemShape.s
            }
            PathQuad {
                x: 50 * emblemShape.s; y: 42 * emblemShape.s
                controlX: 35 * emblemShape.s; controlY: 50 * emblemShape.s
            }
        }
    }

    // Finale cyan light sweep across the logo (Slide 10 signature effect)
    Rectangle {
        visible: root.sweepProgress >= 0.0 && root.sweepProgress <= 1.0
        x: (root.sweepProgress * 1.4 - 0.2) * root.width
        y: 0
        width: root.size * 0.28
        height: root.height
        rotation: 24
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: "#8800D2FF" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
}
