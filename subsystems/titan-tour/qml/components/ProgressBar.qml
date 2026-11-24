import QtQuick

/**
 * ProgressBar — Dual-mode progress indicator matching Image 1 & Image 2:
 *   - On Slide 01 (Welcome, segmentedMode = true): 5 segmented pill bars at bottom-left
 *     where the first pill is glowing electric cyan (#00D2FF) and the rest are dark slate.
 *   - On Slides 02..10 (segmentedMode = false): "2 / 10" counter + smooth horizontal
 *     progress line (350 ms OutCubic) at bottom-left.
 *   Clicking segments jumps to any visited step.
 */
Item {
    id: root

    property int currentIndex: typeof tourCtrl !== "undefined" ? tourCtrl.currentIndex : 0
    property int totalSteps: typeof tourCtrl !== "undefined" ? tourCtrl.totalSteps : 10
    property bool segmentedMode: currentIndex === 0
    property bool reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false

    signal stepSelected(int index)

    implicitWidth: 220
    implicitHeight: 28

    // Mode A: Image 1 Welcome Screen — 5 segmented horizontal pill bars
    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        visible: root.segmentedMode

        Repeater {
            model: 5

            Rectangle {
                readonly property bool isFirst: index === 0
                width: isFirst ? 36 : 24
                height: 5
                radius: 2.5
                color: isFirst ? "#00D2FF" : "#263042" // tdl-allow

                // Subtle cyan glow around the active first segment
                Rectangle {
                    visible: parent.isFirst
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: 5
                    color: "#3300D2FF"
                    z: -1
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.stepSelected(index)
                }
            }
        }
    }

    // Mode B: Image 2 Slides 02..10 — "2 / 10" + smooth cyan progress line
    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14
        visible: !root.segmentedMode

        Text {
            text: (root.currentIndex + 1) + " / " + Math.max(1, root.totalSteps)
            font.family: "Inter"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: "#94A3B8" // tdl-allow
            anchors.verticalCenter: parent.verticalCenter
        }

        // Smooth progress track
        Rectangle {
            id: lineTrack
            width: 136
            height: 4
            radius: 2
            color: "#1E293B" // tdl-allow
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: Math.max(14, parent.width * ((root.currentIndex + 1) / Math.max(1, root.totalSteps)))
                height: parent.height
                radius: 2
                color: "#00D2FF"

                Behavior on width {
                    NumberAnimation {
                        duration: root.reducedMotion ? 50 : 350
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse) {
                    var idx = Math.floor((mouse.x / lineTrack.width) * root.totalSteps);
                    idx = Math.max(0, Math.min(root.totalSteps - 1, idx));
                    root.stepSelected(idx);
                }
            }
        }
    }
}
