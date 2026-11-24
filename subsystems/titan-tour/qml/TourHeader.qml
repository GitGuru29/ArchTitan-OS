import QtQuick
import QtQuick.Layouts

Item {
    id: root
    height: 48

    property int currentSlide: 0
    property int totalSlides: 5
    signal slideRequested(int index)
    signal closeClicked()

    readonly property var steps: [
        { title: "Welcome" },
        { title: "Desktop Tour" },
        { title: "Shortcuts" },
        { title: "Appearance" },
        { title: "Your System" }
    ]

    // Allow moving the window by dragging the titlebar
    DragHandler {
        target: null
        onActiveChanged: {
            if (active && typeof rootWindow !== "undefined") {
                rootWindow.startSystemMove();
            }
        }
    }

    // Subtle macOS titlebar bottom divider
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(1, 1, 1, 0.06)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 12

        // ── Left: Authentic macOS Traffic Lights ────────────────────────────
        Row {
            id: trafficRow
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            property bool groupHovered: closeArea.containsMouse || minArea.containsMouse || maxArea.containsMouse

            // Red: Close
            Rectangle {
                width: 12
                height: 12
                radius: 6
                color: "#FF5F57"
                border.width: 1
                border.color: "#E0443E"

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    visible: trafficRow.groupHovered
                    color: "#4D0000"
                    font.family: "Inter"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tourCtrl.playSound("click");
                        root.closeClicked();
                    }
                }
            }

            // Yellow: Reset to Welcome
            Rectangle {
                width: 12
                height: 12
                radius: 6
                color: "#FEBC2E"
                border.width: 1
                border.color: "#DEA123"

                Text {
                    anchors.centerIn: parent
                    text: "−"
                    visible: trafficRow.groupHovered
                    color: "#5A3E00"
                    font.family: "Inter"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: minArea
                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tourCtrl.playSound("tap");
                        root.slideRequested(0);
                    }
                }
            }

            // Green: Advance Slide
            Rectangle {
                width: 12
                height: 12
                radius: 6
                color: "#28C840"
                border.width: 1
                border.color: "#1AAB29"

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    visible: trafficRow.groupHovered
                    color: "#004D0D"
                    font.family: "Inter"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: maxArea
                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tourCtrl.playSound("tap");
                        root.slideRequested((root.currentSlide + 1) % root.totalSlides);
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // ── Center: macOS Segmented Navigation Bar ──────────────────────────
        Rectangle {
            implicitHeight: 30
            implicitWidth: navRow.implicitWidth + 6
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.07)

            Row {
                id: navRow
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: root.steps

                    Rectangle {
                        id: segPill
                        property bool isCurrent: index === root.currentSlide

                        implicitHeight: 24
                        implicitWidth: segLabel.implicitWidth + 22
                        radius: 6

                        color: isCurrent ? "#3A3A3E"
                                         : (segMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
                        border.width: isCurrent ? 0.5 : 0
                        border.color: Qt.rgba(1, 1, 1, 0.14)

                        Behavior on color { ColorAnimation { duration: 140 } }

                        Text {
                            id: segLabel
                            anchors.centerIn: parent
                            text: modelData.title
                            color: segPill.isCurrent ? "#F5F5F7"
                                                     : (segMouse.containsMouse ? "#D1D1D6" : "#8E8E93")
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: segPill.isCurrent ? 600 : 500
                        }

                        MouseArea {
                            id: segMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                tourCtrl.playSound("tap");
                                root.slideRequested(index);
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // ── Right: Subtle Sound Toggle & Close Pill ─────────────────────────
        Row {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                width: 26
                height: 26
                radius: 6
                color: sfxMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: tourCtrl.soundFxEnabled ? "\uf028" : "\uf026"
                    color: tourCtrl.soundFxEnabled ? "#98989D" : "#636366"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                }

                MouseArea {
                    id: sfxMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tourCtrl.soundFxEnabled = !tourCtrl.soundFxEnabled
                }
            }
        }
    }
}
