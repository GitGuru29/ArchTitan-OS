import QtQuick

/**
 * NavigationControls — Bottom-right navigation controls matching Image 1 & Image 2:
 *   - Slide 01 (Welcome): Dark glass pill button with glowing cyan rim ("Explore ArchTitan →")
 *   - Slides 02..09: "Back" dark pill button + "Continue →" bright electric cyan pill button
 *   - Slide 10 (Completion): Handled centrally in CompletionScene ("Enter ArchTitan →" + "Explore Features Again")
 */
Item {
    id: root

    property int currentIndex: typeof tourCtrl !== "undefined" ? tourCtrl.currentIndex : 0
    property int totalSteps: typeof tourCtrl !== "undefined" ? tourCtrl.totalSteps : 10

    signal backClicked()
    signal continueClicked()
    signal skipClicked()

    implicitWidth: navRow.implicitWidth
    implicitHeight: 38

    Row {
        id: navRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // Slide 01: Image 1 "Explore ArchTitan →" dark glass pill with glowing cyan border
        Rectangle {
            visible: root.currentIndex === 0
            width: exploreRow.implicitWidth + 36
            height: 38
            radius: 19
            color: exploreArea.pressed ? "#162436" : (exploreArea.containsMouse ? "#111D2C" : "#0B131E") // tdl-allow
            border.width: 1
            border.color: exploreArea.containsMouse ? "#00D2FF" : "#5500D2FF"

            scale: exploreArea.pressed ? 0.97 : 1.0
            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }

            Row {
                id: exploreRow
                anchors.centerIn: parent
                spacing: 10

                Text {
                    text: "Explore ArchTitan"
                    font.family: "Inter"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "→"
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: "#CDD6F4"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: exploreArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.continueClicked()
            }
        }

        // Slides 02..09: "Back" dark pill button
        Rectangle {
            visible: root.currentIndex > 0 && root.currentIndex < root.totalSteps - 1
            width: 68
            height: 34
            radius: 17
            color: backArea.pressed ? "#1E293B" : (backArea.containsMouse ? "#172030" : "#101722") // tdl-allow
            border.width: 1
            border.color: backArea.containsMouse ? "#475569" : "#263244" // tdl-allow

            scale: backArea.pressed ? 0.97 : 1.0
            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

            Text {
                anchors.centerIn: parent
                text: "Back"
                font.family: "Inter"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: "#CDD6F4"
            }

            MouseArea {
                id: backArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.backClicked()
            }
        }

        // Slides 02..09: "Continue →" glowing cyan pill button
        Rectangle {
            visible: root.currentIndex > 0 && root.currentIndex < root.totalSteps - 1
            width: 108
            height: 34
            radius: 17
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: contArea.pressed ? "#0284C7" : "#00B4D8" } // tdl-allow
                GradientStop { position: 1.0; color: contArea.pressed ? "#00B4D8" : "#00D2FF" } // tdl-allow
            }

            scale: contArea.pressed ? 0.97 : 1.0
            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

            Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "Continue"
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "→"
                    font.family: "Inter"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: contArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.continueClicked()
            }
        }
    }
}
