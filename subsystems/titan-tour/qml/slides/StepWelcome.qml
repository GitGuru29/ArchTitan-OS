import QtQuick
import QtQuick.Layouts

Item {
    id: root
    signal jumpToSlide(int slideIndex)

    readonly property var features: [
        {
            icon: "\uf108",
            gradTop: "#2E9BFF",
            gradBot: "#0066CC",
            title: "Fluid Desktop & Control Center",
            desc: "Workspaces, live media playback, and quick system settings live cleanly along the top edge of your screen.",
            targetSlide: 1
        },
        {
            icon: "\uf002",
            gradTop: "#7D7AFF",
            gradBot: "#4B48C8",
            title: "Spotlight & Effortless Tiling",
            desc: "Press Super + Space anytime to launch apps or search files, and tile windows automatically with simple shortcuts.",
            targetSlide: 2
        },
        {
            icon: "\uf2db",
            gradTop: "#34D399",
            gradBot: "#059669",
            title: "Adaptive Hardware Intelligence",
            desc: "Continuous CPU and memory protection prioritizes your active window so the desktop stays responsive under heavy load.",
            targetSlide: 4
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 18
        anchors.bottomMargin: 16
        anchors.leftMargin: 48
        anchors.rightMargin: 48
        spacing: 16

        // ── Centered Hero Emblem & Title (Apple Welcome Splash Style) ───────
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 72
                height: 72

                // Concentric outer squircle halo
                Rectangle {
                    anchors.centerIn: parent
                    width: 76
                    height: 76
                    radius: 20
                    color: Qt.rgba(10/255, 132/255, 255/255, 0.10)
                    border.width: 1
                    border.color: Qt.rgba(10/255, 132/255, 255/255, 0.22)
                }

                // macOS App Icon Squircle
                Rectangle {
                    anchors.centerIn: parent
                    width: 68
                    height: 68
                    radius: 17
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#1E3A8A" }
                        GradientStop { position: 0.5; color: "#172554" }
                        GradientStop { position: 1.0; color: "#0B1120" }
                    }
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.24)

                    // Top inner specular highlight
                    Rectangle {
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 14
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.35)
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 40
                        height: 40
                        source: tourCtrl.logoUrl
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Welcome to ArchTitan"
                color: "#F5F5F7"
                font.family: "Inter"
                font.pixelSize: 28
                font.weight: Font.Bold
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Get acquainted with your new desktop—crafted for effortless speed, fluid multitasking, and quiet intelligence."
                color: "#98989D"
                font.family: "Inter"
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                Layout.maximumWidth: 560
                wrapMode: Text.WordWrap
            }
        }

        // ── 3 Apple "What's New" Feature Rows ───────────────────────────────
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 670
            spacing: 10

            Repeater {
                model: root.features

                Rectangle {
                    id: featRow
                    Layout.fillWidth: true
                    implicitHeight: 68
                    radius: 12
                    color: rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.075)
                                                  : Qt.rgba(1, 1, 1, 0.045)
                    border.width: 1
                    border.color: rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15)
                                                         : Qt.rgba(1, 1, 1, 0.07)

                    Behavior on color { ColorAnimation { duration: 140 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 16

                        // macOS Colorful Squircle Icon
                        Rectangle {
                            width: 42
                            height: 42
                            radius: 10
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: modelData.gradTop }
                                GradientStop { position: 1.0; color: modelData.gradBot }
                            }
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.28)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: "#FFFFFF"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                            }
                        }

                        // Feature Title & Description
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: modelData.title
                                color: "#F5F5F7"
                                font.family: "Inter"
                                font.pixelSize: 14
                                font.weight: 600
                            }

                            Text {
                                text: modelData.desc
                                color: "#98989D"
                                font.family: "Inter"
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }

                        // Subtle Explore Pill
                        Rectangle {
                            implicitHeight: 26
                            implicitWidth: exploreRow.implicitWidth + 16
                            radius: 13
                            color: rowMouse.containsMouse ? Qt.rgba(10/255, 132/255, 255/255, 0.20)
                                                          : Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1
                            border.color: rowMouse.containsMouse ? "#0A84FF" : Qt.rgba(1, 1, 1, 0.10)

                            Row {
                                id: exploreRow
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    text: "Explore"
                                    color: rowMouse.containsMouse ? "#64D2FF" : "#AEAEB2"
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    font.weight: 600
                                }

                                Text {
                                    text: "›"
                                    color: rowMouse.containsMouse ? "#64D2FF" : "#AEAEB2"
                                    font.family: "Inter"
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            tourCtrl.playSound("tap");
                            root.jumpToSlide(modelData.targetSlide);
                        }
                    }
                }
            }
        }
    }
}
