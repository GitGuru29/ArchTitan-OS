import QtQuick

/**
 * SlideContainer — standard two-column layout wrapper used by slides 02..09
 * in Image 2:
 *   Left column: Title, Subtitle, and interactive Shortcut Pill / Feature List
 *   Right column: Animated Feature Artwork Stage
 */
Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string shortcutText: ""
    property string featureId: ""
    property bool featureExplored: false
    default property alias artwork: artworkStage.data
    property alias leftExtra: leftExtraContainer.data

    signal shortcutTriggered()

    // Left column (Title, Subtitle, Shortcut pill / extra items)
    Column {
        id: leftCol
        anchors.left: parent.left
        anchors.leftMargin: 48
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -14
        width: parent.width * 0.36
        spacing: 16

        Text {
            width: parent.width
            text: root.title
            font.family: "Inter"
            font.pixelSize: 34
            font.weight: Font.Bold
            color: "#FFFFFF"
            lineHeight: 1.15
            wrapMode: Text.WordWrap
        }

        Text {
            width: parent.width
            text: root.subtitle
            font.family: "Inter"
            font.pixelSize: 15
            color: "#94A3B8" // tdl-allow
            lineHeight: 1.42
            wrapMode: Text.WordWrap
        }

        // Extra items (e.g. Waybar / Dynamic Workspaces / Modern Glass UI list on Slide 02)
        Column {
            id: leftExtraContainer
            width: parent.width
            spacing: 10
        }

        // Interactive Shortcut Pill ("[ ⌘  Super ]", "[ ⌘  Super + Tab ]", etc.)
        Row {
            visible: root.shortcutText.length > 0
            spacing: 10

            Rectangle {
                width: scRow.implicitWidth + 28
                height: 38
                radius: 11
                color: scMouse.containsMouse ? "#18263A" : "#0F1826" // tdl-allow
                border.width: 1
                border.color: scMouse.containsMouse ? "#00D2FF" : "#2D3F58" // tdl-allow

                scale: scMouse.pressed ? 0.97 : 1.0
                Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                Row {
                    id: scRow
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: "⌘"
                        font.family: "Inter"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: "#00D2FF"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.shortcutText
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: "#FFFFFF"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: scMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shortcutTriggered()
                }
            }

            // Responsive interaction state badge (shown once explored)
            Rectangle {
                visible: root.featureId.length > 0 && root.featureExplored
                width: stateText.implicitWidth + 18
                height: 26
                radius: 13
                anchors.verticalCenter: parent.verticalCenter
                color: "#22A6E3A1"
                border.width: 1
                border.color: "#66A6E3A1"

                Text {
                    id: stateText
                    anchors.centerIn: parent
                    text: "Explored ✓"
                    font.family: "Inter"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: "#A6E3A1"
                }
            }
        }
    }

    // Right column (Animated Feature Artwork Stage)
    Item {
        id: artworkStage
        anchors.right: parent.right
        anchors.rightMargin: 44
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -14
        width: parent.width * 0.52
        height: parent.height - 125
    }
}
