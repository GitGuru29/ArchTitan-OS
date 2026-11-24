import QtQuick
import QtQuick.Layouts

Item {
    id: root
    height: 50

    property int currentSlide: 0
    property int totalSlides: 5
    signal slideRequested(int index)
    signal closeClicked()

    readonly property var steps: [
        { title: "Welcome",      icon: "\uf015" },
        { title: "Desktop Tour", icon: "\uf108" },
        { title: "Shortcuts",    icon: "\uf11c" },
        { title: "Appearance",   icon: "\uf03e" },
        { title: "Your System",  icon: "\uf2db" }
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
        color: Qt.rgba(1, 1, 1, 0.08)
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

        // ── Center: macOS Segmented Navigation Bar with Icons ───────────────
        Rectangle {
            implicitHeight: 32
            implicitWidth: navRow.implicitWidth + 8
            radius: 9
            color: Qt.rgba(0, 0, 0, 0.28)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            Row {
                id: navRow
                anchors.centerIn: parent
                spacing: 3

                Repeater {
                    model: root.steps

                    Rectangle {
                        id: segPill
                        property bool isCurrent: index === root.currentSlide

                        implicitHeight: 26
                        implicitWidth: segContent.implicitWidth + 20
                        radius: 7

                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: segPill.isCurrent ? "#424248"
                                                         : (segMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                            }
                            GradientStop {
                                position: 1.0
                                color: segPill.isCurrent ? "#323238"
                                                         : (segMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent")
                            }
                        }

                        border.width: isCurrent ? 1 : 0
                        border.color: Qt.rgba(1, 1, 1, 0.16)

                        Row {
                            id: segContent
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: modelData.icon
                                color: segPill.isCurrent ? "#0A84FF"
                                                         : (segMouse.containsMouse ? "#D1D1D6" : "#6E6E73")
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.title
                                color: segPill.isCurrent ? "#F5F5F7"
                                                         : (segMouse.containsMouse ? "#D1D1D6" : "#8E8E93")
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: segPill.isCurrent ? 600 : 500
                                anchors.verticalCenter: parent.verticalCenter
                            }
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

        // ── Right: Step Progress Pill & Sound Toggle ────────────────────────
        Row {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                implicitHeight: 22
                implicitWidth: stepBadgeTxt.implicitWidth + 12
                radius: 6
                color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                Text {
                    id: stepBadgeTxt
                    anchors.centerIn: parent
                    text: (root.currentSlide + 1) + " of " + root.totalSlides
                    color: "#8E8E93"
                    font.family: "Inter"
                    font.pixelSize: 11
                    font.weight: 600
                }
            }

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
