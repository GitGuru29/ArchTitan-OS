import QtQuick
import QtQuick.Shapes

/**
 * TourWindow — The floating dark obsidian card window matching Image 1 & Image 2.
 * Remains stable during slide transitions:
 *   - Deep obsidian interior with sweeping dark-cyan curved light arcs
 *   - Top-left macOS traffic-light dots (red close button, yellow, green)
 *   - Bottom footer hosting ProgressBar on left and NavigationControls on right
 */
Rectangle {
    id: root

    property int currentIndex: typeof tourCtrl !== "undefined" ? tourCtrl.currentIndex : 0
    property int totalSteps: typeof tourCtrl !== "undefined" ? tourCtrl.totalSteps : 10
    property real progressOpacity: 1.0
    property real buttonOpacity: 1.0
    property real buttonOffsetY: 0.0
    default property alias content: slideViewport.data

    signal closeRequested()
    signal backRequested()
    signal continueRequested()
    signal stepRequested(int index)

    radius: 18
    color: "#060A12" // tdl-allow
    border.width: 1
    border.color: "#2A3950" // tdl-allow
    clip: true

    // Interior deep obsidian gradient
    Rectangle {
        anchors.fill: parent
        radius: 18
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#080D18" } // tdl-allow
            GradientStop { position: 0.5; color: "#050810" } // tdl-allow
            GradientStop { position: 1.0; color: "#070D19" } // tdl-allow
        }
    }

    // Feathered interior cyan nebula glow (no hard circle edges)
    Shape {
        anchors.fill: parent

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: root.width * 0.52
                centerY: root.height * 0.46
                centerRadius: root.width * 0.44
                focalX: centerX
                focalY: centerY
                GradientStop { position: 0.0; color: "#2200D2FF" }
                GradientStop { position: 0.5; color: "#0D0284C7" }
                GradientStop { position: 1.0; color: "transparent" }
            }
            PathRectangle { x: 0; y: 0; width: root.width; height: root.height }
        }
    }

    // Sweeping dark-cyan light curves inside the black window (visible in Image 1 & Image 2)
    Shape {
        anchors.fill: parent
        opacity: 0.42

        // Upper-right sweeping cyan curve
        ShapePath {
            strokeColor: "#3300D2FF"
            strokeWidth: 1.5
            fillColor: "transparent"
            startX: root.width * 0.48; startY: root.height * 0.44
            PathCubic {
                x: root.width * 0.96; y: root.height * 0.04
                control1X: root.width * 0.64; control1Y: root.height * 0.34
                control2X: root.width * 0.80; control2Y: root.height * 0.14
            }
        }

        // Upper-left sweeping cyan curve
        ShapePath {
            strokeColor: "#1F38BDF8"
            strokeWidth: 1.2
            fillColor: "transparent"
            startX: root.width * 0.10; startY: root.height * 0.16
            PathCubic {
                x: root.width * 0.52; y: root.height * 0.44
                control1X: root.width * 0.24; control1Y: root.height * 0.28
                control2X: root.width * 0.38; control2Y: root.height * 0.38
            }
        }

        // Lower-left sweeping curve
        ShapePath {
            strokeColor: "#2400D2FF"
            strokeWidth: 1.3
            fillColor: "transparent"
            startX: root.width * 0.12; startY: root.height * 0.38
            PathCubic {
                x: root.width * 0.40; y: root.height * 0.85
                control1X: root.width * 0.25; control1Y: root.height * 0.50
                control2X: root.width * 0.35; control2Y: root.height * 0.68
            }
        }

        // Lower-right violet-cyan sweeping curve
        ShapePath {
            strokeColor: "#2889B4FA"
            strokeWidth: 1.4
            fillColor: "transparent"
            startX: root.width * 0.64; startY: root.height * 0.78
            PathCubic {
                x: root.width * 0.98; y: root.height * 0.36
                control1X: root.width * 0.72; control1Y: root.height * 0.56
                control2X: root.width * 0.84; control2Y: root.height * 0.42
            }
        }
    }

    // Top-left macOS traffic-light window controls (Image 1 & Image 2)
    Row {
        id: trafficLights
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 22
        anchors.topMargin: 18
        spacing: 8
        z: 30

        // Close dot
        Rectangle {
            width: 12
            height: 12
            radius: 6
            color: "#FF5F56" // tdl-allow

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }
        }

        // Minimize dot
        Rectangle {
            width: 12
            height: 12
            radius: 6
            color: root.currentIndex === 0 ? "#383E4C" : "#FFBD2E" // tdl-allow
        }

        // Zoom dot
        Rectangle {
            width: 12
            height: 12
            radius: 6
            color: root.currentIndex === 0 ? "#383E4C" : "#27C93F" // tdl-allow
        }
    }

    // Main slide content viewport
    Item {
        id: slideViewport
        anchors.fill: parent
    }

    // Bottom Footer: ProgressBar (left) & NavigationControls (right)
    Item {
        id: footerBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.bottomMargin: 20
        height: 40
        z: 30

        ProgressBar {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            currentIndex: root.currentIndex
            totalSteps: root.totalSteps
            segmentedMode: root.currentIndex === 0
            opacity: root.progressOpacity
            onStepSelected: function(idx) { root.stepRequested(idx); }
        }

        NavigationControls {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.buttonOffsetY
            currentIndex: root.currentIndex
            totalSteps: root.totalSteps
            opacity: root.buttonOpacity
            onBackClicked: root.backRequested()
            onContinueClicked: root.continueRequested()
        }
    }
}
