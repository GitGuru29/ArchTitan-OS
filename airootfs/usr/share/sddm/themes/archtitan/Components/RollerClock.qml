import QtQuick
import QtQuick.Controls

Item {
    id: clockRoot
    width: clockRow.width
    height: clockColumn.height

    property bool is24Hour: true
    property string timeStr: ""
    property string dateStr: ""

    function updateTime() {
        var now = new Date()
        var format = is24Hour ? "hh:mm" : "hh:mm ap"
        var h = is24Hour ? Qt.formatDateTime(now, "hh") : Qt.formatDateTime(now, "hh")
        var m = Qt.formatDateTime(now, "mm")
        
        digitH1.digit = h.charAt(0)
        digitH2.digit = h.charAt(1)
        digitM1.digit = m.charAt(0)
        digitM2.digit = m.charAt(1)

        // Format: THU • 13 OCT
        var dName = Qt.formatDateTime(now, "ddd").toUpperCase()
        var dayNum = Qt.formatDateTime(now, "d")
        var mName = Qt.formatDateTime(now, "MMM").toUpperCase()
        dateText.text = dName + "  •  " + dayNum + " " + mName
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clockRoot.updateTime()
    }

    Column {
        id: clockColumn
        spacing: 16

        // Row of 4 roller drums + colon
        Row {
            id: clockRow
            spacing: 6

            // Hour Digit 1
            DigitDrum { id: digitH1 }
            // Hour Digit 2
            DigitDrum { id: digitH2 }

            // Colon separator
            Item {
                width: 14
                height: 96
                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    Rectangle {
                        width: 4
                        height: 4
                        radius: 2
                        color: "#8B95AA"
                    }
                    Rectangle {
                        width: 4
                        height: 4
                        radius: 2
                        color: "#8B95AA"
                    }
                }
            }

            // Minute Digit 1
            DigitDrum { id: digitM1 }
            // Minute Digit 2
            DigitDrum { id: digitM2 }
        }

        // Date Display: THU • 13 OCT
        Text {
            id: dateText
            text: "THU  •  13 OCT"
            color: "#8E98AC"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            font.letterSpacing: 3.5
            font.family: "JetBrainsMono Nerd Font"
        }
    }

    // Individual mechanical roller drum component
    component DigitDrum: Rectangle {
        id: drum
        width: 64
        height: 96
        radius: 8
        color: "#161922"
        border.width: 1
        border.color: "#282E3D"
        clip: true

        property string digit: "0"

        // Metallic gradient
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#11131A" }
            GradientStop { position: 0.2; color: "#1A1D27" }
            GradientStop { position: 0.5; color: "#222735" }
            GradientStop { position: 0.8; color: "#1A1D27" }
            GradientStop { position: 1.0; color: "#11131A" }
        }

        // Text digit with roll animation
        Text {
            id: digitDisplay
            anchors.centerIn: parent
            text: drum.digit
            color: "#F0F3F9"
            font.pixelSize: 58
            font.weight: Font.Bold
            font.family: "JetBrainsMono Nerd Font"

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: digitDisplay; property: "scale"; to: 0.85; duration: 120; easing.type: Easing.InQuad }
                    NumberAnimation { target: digitDisplay; property: "scale"; to: 1.0; duration: 160; easing.type: Easing.OutBack }
                }
            }
        }

        // Horizontal slit groove across the middle
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 1
            color: "#0A0B10"
            opacity: 0.85
        }

        // Top curvature shadow overlay
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 28
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#99000000" }
                GradientStop { position: 1.0; color: "#00000000" }
            }
        }

        // Bottom curvature shadow overlay
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 28
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 1.0; color: "#99000000" }
            }
        }
    }
}
