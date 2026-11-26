import QtQuick

/**
 * ProgressIndicator — minimal step capsules + smoothly animated thin laser-cyan
 * progress line along the bottom of the screen.
 */
Item {
    id: root

    property int currentIndex: typeof tourCtrl !== "undefined" ? tourCtrl.currentIndex : 0
    property int totalSteps: typeof tourCtrl !== "undefined" ? tourCtrl.totalSteps : 10
    property real progress: typeof tourCtrl !== "undefined" ? tourCtrl.progress : 0.0
    property bool reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false

    signal stepClicked(int index)

    implicitWidth: 520
    implicitHeight: 38

    // Floating dark glass pill housing the step dots and thin cyan rail
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width, pillRow.implicitWidth + 36)
        height: 36
        radius: 18
        color: "#CC181825"
        border.width: 1
        border.color: "#2EFFFFFF"

        // Smooth thin cyan progress line along the bottom rim
        Rectangle {
            id: railTrack
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 5
            height: 2
            radius: 1
            color: "#22FFFFFF"

            Rectangle {
                width: Math.max(8, parent.width * root.progress)
                height: parent.height
                radius: 1
                color: "#00D2FF"

                Behavior on width {
                    NumberAnimation {
                        duration: root.reducedMotion ? 50 : 280
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Row {
            id: pillRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 9
            spacing: 14

            // Step counter label ("03 / 10")
            Text {
                text: {
                    var c = root.currentIndex + 1;
                    var t = Math.max(1, root.totalSteps);
                    return (c < 10 ? "0" + c : "" + c) + " / " + (t < 10 ? "0" + t : "" + t);
                }
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.weight: Font.Bold
                color: "#00D2FF"
                anchors.verticalCenter: parent.verticalCenter
            }

            // Minimal step segments
            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: root.totalSteps

                    Rectangle {
                        id: seg
                        readonly property bool isCurrent: index === root.currentIndex
                        readonly property bool isPast: index < root.currentIndex

                        width: isCurrent ? 26 : 8
                        height: 6
                        radius: 3
                        color: isCurrent ? "#00D2FF" : (isPast ? "#0284C7" : "#38FFFFFF")

                        Behavior on width {
                            NumberAnimation {
                                duration: root.reducedMotion ? 40 : 220
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on color { ColorAnimation { duration: 160 } }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.stepClicked(index)
                        }
                    }
                }
            }

            // Keyboard hint
            Text {
                text: "← → · Esc"
                font.family: "Inter"
                font.pixelSize: 11
                color: "#7F849C"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}

