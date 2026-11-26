import QtQuick
import QtQuick.Shapes
import "../components"

/**
 * IntelligenceScene — Slide 07: "Intelligence Under the Hood"
 * Matches panel 7/10 in Image 2 (media_1795534773489_da4d70fb.jpg):
 *   - Left: "Intelligence\nUnder the Hood",
 *           "THM intelligently manages resources for smooth performance."
 *   - Right: Glowing frosted telemetry card with 3 circular ring gauges
 *            (CPU 12% cyan, RAM 28% cyan, Temp 42°C coral-red) and a smooth
 *            cyan waveform area chart along the bottom.
 */
Item {
    id: root

    property real animFactor: 1.0
    readonly property int liveCpu: typeof tourCtrl !== "undefined" ? Math.max(8, Math.round(tourCtrl.cpuUsage * 100)) : 12
    readonly property int liveRam: typeof tourCtrl !== "undefined" ? Math.max(18, Math.round(tourCtrl.ramUsage * 100)) : 28
    readonly property int liveTemp: typeof tourCtrl !== "undefined" ? tourCtrl.cpuTemp : 42

    onVisibleChanged: {
        if (visible && (typeof tourCtrl === "undefined" || !tourCtrl.reducedMotion)) {
            countUpAnim.restart();
        } else {
            animFactor = 1.0;
        }
    }

    NumberAnimation {
        id: countUpAnim
        target: root
        property: "animFactor"
        from: 0.15
        to: 1.0
        duration: 550
        easing.type: Easing.OutCubic
    }

    SlideContainer {
        anchors.fill: parent
        title: "Intelligence\nUnder the Hood"
        subtitle: "THM intelligently manages\nresources for smooth performance."
        featureId: "sysmon"
        featureExplored: typeof tourCtrl !== "undefined" ? tourCtrl.featureTried : false
        onShortcutTriggered: if (typeof tourCtrl !== "undefined") tourCtrl.toggleLiveFeature()

        // Right Column Artwork: 3 Circular Ring Gauges + Bottom Waveform Area Graph
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width, 412)
            height: 252
            radius: 22
            color: "#D8091220" // tdl-allow
            border.width: 1.5
            border.color: "#5500D2FF"
            clip: true

            // Three Circular Ring Gauges (CPU, RAM, Temp)
            Row {
                anchors.top: parent.top
                anchors.topMargin: 22
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 32

                Repeater {
                    model: [
                        { label: "CPU",  textVal: Math.round(root.liveCpu * root.animFactor) + "%",  arcColor: "#00D2FF", ratio: 0.32 },
                        { label: "RAM",  textVal: Math.round(root.liveRam * root.animFactor) + "%",  arcColor: "#22D3EE", ratio: 0.48 }, // tdl-allow
                        { label: "Temp", textVal: Math.round(root.liveTemp * root.animFactor) + "°C", arcColor: "#FB7185", ratio: 0.56 }  // tdl-allow
                    ]

                    Column {
                        spacing: 8

                        Item {
                            width: 86
                            height: 86

                            // Track ring
                            Rectangle {
                                anchors.fill: parent
                                radius: 43
                                color: "transparent"
                                border.width: 7
                                border.color: "#1B283D" // tdl-allow
                            }

                            // Colored arc ring via ShapePathPathAngleArc
                            Shape {
                                anchors.fill: parent
                                preferredRendererType: Shape.CurveRenderer

                                ShapePath {
                                    fillColor: "transparent"
                                    strokeColor: modelData.arcColor
                                    strokeWidth: 7
                                    capStyle: ShapePath.RoundCap

                                    PathAngleArc {
                                        centerX: 43
                                        centerY: 43
                                        radiusX: 39.5
                                        radiusY: 39.5
                                        startAngle: -125
                                        sweepAngle: 250 * modelData.ratio * root.animFactor
                                    }
                                }
                            }

                            // Value text inside ring
                            Text {
                                anchors.centerIn: parent
                                text: modelData.textVal
                                font.family: "Inter"
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                color: "#FFFFFF"
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: "#CBD5E1" // tdl-allow
                        }
                    }
                }
            }

            // Bottom Cyan Area Waveform Chart (matching Image 2 panel 7/10)
            Item {
                id: chartBox
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                anchors.bottomMargin: 18
                height: 68

                // Subtle chart baseline grid lines
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: "#2238BDF8"
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 1
                    color: "#1438BDF8"
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    // Translucent cyan area fill under the waveform
                    ShapePath {
                        strokeWidth: 0
                        strokeColor: "transparent"
                        fillGradient: LinearGradient {
                            x1: 0; y1: 0
                            x2: 0; y2: chartBox.height
                            GradientStop { position: 0.0; color: "#5500D2FF" }
                            GradientStop { position: 1.0; color: "#0500D2FF" }
                        }
                        startX: 0; startY: chartBox.height
                        PathLine { x: 0; y: chartBox.height * 0.62 }
                        PathLine { x: chartBox.width * 0.14; y: chartBox.height * 0.44 }
                        PathLine { x: chartBox.width * 0.28; y: chartBox.height * 0.56 }
                        PathLine { x: chartBox.width * 0.42; y: chartBox.height * 0.34 }
                        PathLine { x: chartBox.width * 0.56; y: chartBox.height * 0.52 }
                        PathLine { x: chartBox.width * 0.70; y: chartBox.height * 0.40 }
                        PathLine { x: chartBox.width * 0.85; y: chartBox.height * 0.24 }
                        PathLine { x: chartBox.width; y: chartBox.height * 0.32 }
                        PathLine { x: chartBox.width; y: chartBox.height }
                        PathLine { x: 0; y: chartBox.height }
                    }

                    // Glowing cyan top waveform line
                    ShapePath {
                        strokeColor: "#00D2FF"
                        strokeWidth: 2.4
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        startX: 0; startY: chartBox.height * 0.62
                        PathLine { x: chartBox.width * 0.14; y: chartBox.height * 0.44 }
                        PathLine { x: chartBox.width * 0.28; y: chartBox.height * 0.56 }
                        PathLine { x: chartBox.width * 0.42; y: chartBox.height * 0.34 }
                        PathLine { x: chartBox.width * 0.56; y: chartBox.height * 0.52 }
                        PathLine { x: chartBox.width * 0.70; y: chartBox.height * 0.40 }
                        PathLine { x: chartBox.width * 0.85; y: chartBox.height * 0.24 }
                        PathLine { x: chartBox.width; y: chartBox.height * 0.32 }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (typeof tourCtrl !== "undefined") tourCtrl.toggleLiveFeature()
            }
        }
    }
}
