import QtQuick
import QtQuick.Controls

Rectangle {
    id: drawerRoot
    width: 360
    height: 480
    radius: 16
    color: "#12141C"
    border.width: 1
    border.color: "#2E3444"
    clip: true

    property string currentRingMode: "music"
    property color currentAccent: "#FFFFFF"
    property bool is24HourClock: true
    property bool simulateMusic: false

    signal ringModeChanged(string mode)
    signal accentColorChanged(color col)
    signal clockFormatChanged(bool is24h)
    signal simulateMusicToggled(bool active)
    signal closeRequested()

    Column {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 18

        // Header
        Item {
            width: parent.width
            height: 20

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "CUSTOMIZE SDDM"
                color: "#E2E8F0"
                font.pixelSize: 13
                font.weight: Font.Bold
                font.letterSpacing: 2
                font.family: "JetBrainsMono Nerd Font"
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "✕"
                color: "#7E8597"
                font.pixelSize: 15
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: drawerRoot.closeRequested()
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#222735" }

        // 1. Ring Lighting Mode
        Column {
            width: parent.width
            spacing: 8

            Text {
                text: "RING LIGHTING EFFECT"
                color: "#7E8597"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 1.5
                font.family: "JetBrainsMono Nerd Font"
            }

            Grid {
                columns: 2
                spacing: 6
                width: parent.width

                ModeButton {
                    text: "Music RGB (Auto)"
                    modeKey: "music"
                    selected: drawerRoot.currentRingMode === "music"
                    onSelectedTriggered: drawerRoot.ringModeChanged("music")
                }
                ModeButton {
                    text: "Always RGB"
                    modeKey: "rgb"
                    selected: drawerRoot.currentRingMode === "rgb"
                    onSelectedTriggered: drawerRoot.ringModeChanged("rgb")
                }
                ModeButton {
                    text: "Solid White"
                    modeKey: "monochrome"
                    selected: drawerRoot.currentRingMode === "monochrome"
                    onSelectedTriggered: drawerRoot.ringModeChanged("monochrome")
                }
                ModeButton {
                    text: "Custom Accent"
                    modeKey: "accent"
                    selected: drawerRoot.currentRingMode === "accent"
                    onSelectedTriggered: drawerRoot.ringModeChanged("accent")
                }
            }
        }

        // 2. Custom Color Palette
        Column {
            width: parent.width
            spacing: 8
            visible: drawerRoot.currentRingMode === "accent"

            Text {
                text: "ACCENT PALETTE"
                color: "#7E8597"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 1.5
                font.family: "JetBrainsMono Nerd Font"
            }

            Row {
                spacing: 10
                ColorDot { dotColor: "#FFFFFF" }
                ColorDot { dotColor: "#00F0FF" }
                ColorDot { dotColor: "#BB9AF7" }
                ColorDot { dotColor: "#00FF9F" }
                ColorDot { dotColor: "#FF0055" }
                ColorDot { dotColor: "#FFB800" }
            }
        }

        // 3. Music Test Simulation Toggle
        Column {
            width: parent.width
            spacing: 8

            Row {
                width: parent.width
                spacing: 12

                Column {
                    width: parent.width - 60
                    Text {
                        text: "Simulate Music State"
                        color: "#DCE1EE"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                    Text {
                        text: "Preview RGB pulse animation"
                        color: "#6B7280"
                        font.pixelSize: 10
                    }
                }

                Switch {
                    id: musicSwitch
                    checked: drawerRoot.simulateMusic
                    onToggled: drawerRoot.simulateMusicToggled(checked)
                }
            }
        }

        // 4. Clock format toggle
        Column {
            width: parent.width
            spacing: 8

            Row {
                width: parent.width
                spacing: 12

                Column {
                    width: parent.width - 60
                    Text {
                        text: "24-Hour Clock"
                        color: "#DCE1EE"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                    Text {
                        text: "Toggle 24h or 12h roller format"
                        color: "#6B7280"
                        font.pixelSize: 10
                    }
                }

                Switch {
                    checked: drawerRoot.is24HourClock
                    onToggled: drawerRoot.clockFormatChanged(checked)
                }
            }
        }

        Item { height: 6 }

        // Done / Close button
        Button {
            width: parent.width
            height: 38
            text: "APPLY & CLOSE"
            font.pixelSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 1.5
            font.family: "JetBrainsMono Nerd Font"

            contentItem: Text {
                text: "APPLY & CLOSE"
                color: "#0A0B0E"
                font: parent.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 6
                color: parent.pressed ? "#CBD5E1" : (parent.hovered ? "#F8FAFC" : "#FFFFFF")
            }

            onClicked: drawerRoot.closeRequested()
        }
    }

    // Mode button component
    component ModeButton: Rectangle {
        property string text: ""
        property string modeKey: ""
        property bool selected: false
        signal selectedTriggered()

        width: 154
        height: 34
        radius: 6
        color: selected ? "#242A38" : (btnMouse.containsMouse ? "#1A1D27" : "#141720")
        border.width: 1
        border.color: selected ? "#00F0FF" : "#282E3D"

        Text {
            anchors.centerIn: parent
            text: parent.text
            color: selected ? "#FFFFFF" : "#8E98AC"
            font.pixelSize: 11
            font.weight: selected ? Font.Bold : Font.Normal
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: selectedTriggered()
        }
    }

    // Color swatch component
    component ColorDot: Rectangle {
        property color dotColor: "#FFFFFF"
        width: 24
        height: 24
        radius: 12
        color: dotColor
        border.width: (drawerRoot.currentAccent === dotColor) ? 2 : 0
        border.color: "#FFFFFF"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: drawerRoot.accentColorChanged(dotColor)
        }
    }
}
