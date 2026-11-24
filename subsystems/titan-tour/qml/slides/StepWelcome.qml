import QtQuick
import QtQuick.Layouts
import "../components"

Item {
    id: root
    signal jumpToChapter(int chapterIdx)
    signal startCoachAt(int coachStepIdx)

    readonly property var quickCards: [
        {
            icon: "\uf03e",
            gradTop: "#FF375F",
            gradBot: "#D70015",
            tag: "QUICK SETUP",
            title: "Choose Your Look & Energy",
            desc: "Preview 4K desktop wallpapers live and select an adaptive power mode for your machine.",
            targetChapter: 1
        },
        {
            icon: "\uf002",
            gradTop: "#0A84FF",
            gradBot: "#0055D4",
            tag: "DESKTOP WORKFLOW",
            title: "Explore Top Bar, Control & Spotlight",
            desc: "See live motion demonstrations of your Dynamic Media Island, Control Center, and Spotlight.",
            targetChapter: 2
        },
        {
            icon: "\uf009",
            gradTop: "#FF9F0A",
            gradBot: "#C93400",
            tag: "TILING & SHORTCUTS",
            title: "Master Hyprland Window Tiling",
            desc: "Learn the essential ⌘ Super keyboard chords to tile, float, and move windows across 10 spaces.",
            targetChapter: 5
        },
        {
            icon: "\uf2db",
            gradTop: "#30D158",
            gradBot: "#15803D",
            tag: "KERNEL INTELLIGENCE",
            title: "Hardware Guard (THM v3)",
            desc: "Inspect your detected hardware specs and see how THM v3 protects 144Hz desktop responsiveness.",
            targetChapter: 7
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // ── Top 60fps Panoramic Motion Hero Stage ───────────────────────────
        MotionStage {
            Layout.fillWidth: true
            Layout.preferredHeight: 176
            chapterIndex: 0
        }

        // ── Editorial Welcome Header ────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: "GETTING STARTED • ARCHTITAN USER GUIDE"
                    color: "#0A84FF"
                    font.family: "Inter"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.6
                }
                Text {
                    text: "Everything you need to master your new OS"
                    color: "#F5F5F7"
                    font.family: "Inter"
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }
            }

            // Live ISO Install Button (if running on Live Media)
            Rectangle {
                visible: tourCtrl.isLiveMode
                implicitHeight: 32
                implicitWidth: instRow.implicitWidth + 18
                radius: 8
                color: Qt.rgba(48/255, 209/255, 88/255, 0.20)
                border.width: 1
                border.color: "#30D158"
                Row {
                    id: instRow; anchors.centerIn: parent; spacing: 6
                    Text { text: "\uf019"; color: "#30D158"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                    Text { text: "Install ArchTitan…"; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600 }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: tourCtrl.launchInstaller()
                }
            }
        }

        // ── 2x2 Apple Editorial Quick-Jump Story Grid ───────────────────────
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 12

            Repeater {
                model: root.quickCards

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: cardMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.085)
                                                   : Qt.rgba(1, 1, 1, 0.045)
                    border.width: 1
                    border.color: cardMouse.containsMouse ? "#0A84FF"
                                                          : Qt.rgba(1, 1, 1, 0.08)

                    Behavior on color { ColorAnimation { duration: 140 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                width: 34; height: 34; radius: 8
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: modelData.gradTop }
                                    GradientStop { position: 1.0; color: modelData.gradBot }
                                }
                                border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.28)
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: "#FFFFFF"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: modelData.tag
                                    color: "#8E8E93"
                                    font.family: "Inter"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                }
                                Text {
                                    text: modelData.title
                                    color: "#F5F5F7"
                                    font.family: "Inter"
                                    font.pixelSize: 13
                                    font.weight: 600
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Text {
                                text: "›"
                                color: cardMouse.containsMouse ? "#0A84FF" : "#6E6E73"
                                font.family: "Inter"
                                font.pixelSize: 18
                                font.weight: Font.Bold
                            }
                        }

                        Text {
                            text: modelData.desc
                            color: "#98989D"
                            font.family: "Inter"
                            font.pixelSize: 11
                            lineHeight: 1.3
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            wrapMode: Text.WordWrap
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            tourCtrl.playSound("tap");
                            root.jumpToChapter(modelData.targetChapter);
                        }
                    }
                }
            }
        }

        // ── Bottom Editorial Footer Bar ─────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                implicitHeight: 34
                implicitWidth: coachBtnRow.implicitWidth + 22
                radius: 8
                color: cArea.containsMouse ? Qt.rgba(10/255, 132/255, 255/255, 0.24)
                                           : Qt.rgba(10/255, 132/255, 255/255, 0.14)
                border.width: 1
                border.color: "#0A84FF"

                Row {
                    id: coachBtnRow; anchors.centerIn: parent; spacing: 7
                    Text { text: "\uf140"; color: "#64D2FF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Launch Hands-On Desktop Coach"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                }

                MouseArea {
                    id: cArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.startCoachAt(0)
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitHeight: 34
                implicitWidth: nxtRow.implicitWidth + 24
                radius: 8
                gradient: Gradient {
                    GradientStop { position: 0.0; color: nArea.containsMouse ? "#2894FF" : "#188BFF" }
                    GradientStop { position: 1.0; color: nArea.containsMouse ? "#0A84FF" : "#007AFF" }
                }
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.25)

                Row {
                    id: nxtRow; anchors.centerIn: parent; spacing: 6
                    Text { text: "Next: Appearance & Energy"; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600 }
                    Text { text: "→"; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 13; font.weight: Font.Bold }
                }

                MouseArea {
                    id: nArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tourCtrl.playSound("tap");
                        root.jumpToChapter(1);
                    }
                }
            }
        }
    }
}
