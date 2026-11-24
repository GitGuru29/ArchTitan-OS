import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    radius: 18

    property int coachStep: 0
    signal expandGuideRequested()
    signal closeRequested()

    readonly property var steps: [
        {
            title: "Spotlight Command Bar",
            stepTag: "HANDS-ON • 1 OF 5",
            keys: ["SUPER", "Space"],
            icon: "\uf002",
            col: "#0A84FF",
            prompt: "Press ⌘ Super + Space or click Summon to test instant search & math.",
            actionLabel: "Summon Spotlight",
            trigger: function() { tourCtrl.toggleSpotlight(); }
        },
        {
            title: "Control Center",
            stepTag: "HANDS-ON • 2 OF 5",
            keys: ["SUPER", "N"],
            icon: "\uf1de",
            col: "#5E5CE6",
            prompt: "Press ⌘ Super + N or click Summon for Wi-Fi, Bluetooth & Audio.",
            actionLabel: "Summon Control",
            trigger: function() { tourCtrl.toggleControlCenter(); }
        },
        {
            title: "Application Menu & Top Bar",
            stepTag: "HANDS-ON • 3 OF 5",
            keys: ["SUPER"],
            icon: "\uf009",
            col: "#BF5AF2",
            prompt: "Click the top-left ArchTitan emblem or Summon to browse apps.",
            actionLabel: "Summon App Menu",
            trigger: function() { tourCtrl.toggleMenu(); }
        },
        {
            title: "TitanFocus Deep Work",
            stepTag: "HANDS-ON • 4 OF 5",
            keys: ["SUPER", "Alt", "F"],
            icon: "\uf06e",
            col: "#00C7BE",
            prompt: "Press ⌘ Super + Alt + F to toggle the top-edge Pomodoro timer.",
            actionLabel: "Toggle TitanFocus",
            trigger: function() { tourCtrl.toggleFocus(); }
        },
        {
            title: "System Monitor & THM v3",
            stepTag: "HANDS-ON • 5 OF 5",
            keys: ["SUPER", "M"],
            icon: "\uf080",
            col: "#30D158",
            prompt: "Press ⌘ Super + M to inspect live CPU headroom & Memory PSI.",
            actionLabel: "Summon Sysmon",
            trigger: function() { tourCtrl.toggleSysmon(); }
        }
    ]

    gradient: Gradient {
        GradientStop { position: 0.0; color: "#22232A" }
        GradientStop { position: 1.0; color: "#15161B" }
    }

    border.width: 2
    border.color: root.steps[root.coachStep].col

    Behavior on border.color { ColorAnimation { duration: 180 } }

    // Allow dragging the floating coach capsule anywhere on screen
    DragHandler {
        target: null
        onActiveChanged: {
            if (active && typeof rootWindow !== "undefined") {
                rootWindow.startSystemMove();
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 8

        // ── Top Row: Squircle Icon + Step Title + Keycaps + Expand Guide Button ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 30; height: 30; radius: 8
                color: root.steps[root.coachStep].col
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.28)
                Text {
                    anchors.centerIn: parent
                    text: root.steps[root.coachStep].icon
                    color: "#FFFFFF"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                }
            }

            ColumnLayout {
                spacing: 0
                Text {
                    text: root.steps[root.coachStep].stepTag
                    color: root.steps[root.coachStep].col
                    font.family: "Inter"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }
                Text {
                    text: root.steps[root.coachStep].title
                    color: "#FFFFFF"
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }
            }

            Row {
                spacing: 4
                Repeater {
                    model: root.steps[root.coachStep].keys
                    Keycap {
                        text: modelData
                        isAccent: true
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Return to Full Guide Button
            Rectangle {
                implicitHeight: 26
                implicitWidth: expRow.implicitWidth + 16
                radius: 7
                color: expMouse.containsMouse ? "#3A3A40" : "#2C2C32"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.16)

                Row {
                    id: expRow
                    anchors.centerIn: parent
                    spacing: 5
                    Text { text: "⤢"; color: "#64D2FF"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Bold }
                    Text { text: "Full Guide"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 11; font.weight: 600 }
                }

                MouseArea {
                    id: expMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expandGuideRequested()
                }
            }
        }

        // ── Bottom Row: Prompt Text + Summon Live Button + Prev/Next Step ───
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: root.steps[root.coachStep].prompt
                color: "#AEAEB2"
                font.family: "Inter"
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Summon Overlay Now Button
            Rectangle {
                implicitHeight: 28
                implicitWidth: sumRow.implicitWidth + 18
                radius: 7
                color: root.steps[root.coachStep].col
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.25)

                Row {
                    id: sumRow
                    anchors.centerIn: parent
                    spacing: 5
                    Text { text: "▶"; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: root.steps[root.coachStep].actionLabel; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.steps[root.coachStep].trigger()
                }
            }

            // Next Step Button
            Rectangle {
                implicitHeight: 28
                implicitWidth: 68
                radius: 7
                color: nxtMouse.containsMouse ? "#3A3A40" : "#2C2C32"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)

                Text {
                    anchors.centerIn: parent
                    text: root.coachStep < root.steps.length - 1 ? "Next →" : "Done ✓"
                    color: "#F5F5F7"
                    font.family: "Inter"
                    font.pixelSize: 11
                    font.weight: 600
                }

                MouseArea {
                    id: nxtMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tourCtrl.playSound("tap");
                        if (root.coachStep < root.steps.length - 1) {
                            root.coachStep++;
                        } else {
                            root.expandGuideRequested();
                        }
                    }
                }
            }
        }
    }
}
