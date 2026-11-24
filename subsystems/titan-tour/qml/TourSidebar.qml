import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    width: 244
    color: Qt.rgba(0.09, 0.09, 0.12, 0.82)

    property int currentChapter: 0
    property string searchQuery: ""
    signal chapterSelected(int index)
    signal startCoachRequested()
    signal closeRequested()

    readonly property var chapters: [
        { idx: 0, section: "GETTING STARTED",    title: "Welcome to ArchTitan",   icon: "\uf015", col: "#0A84FF", keywords: "welcome start overview intro hello" },
        { idx: 1, section: "",                   title: "Appearance & Energy",    icon: "\uf03e", col: "#FF375F", keywords: "wallpaper theme look dark battery power energy" },
        { idx: 2, section: "DESKTOP & WORKFLOW", title: "Top Bar & Media Island", icon: "\uf001", col: "#BF5AF2", keywords: "waybar top bar music media mpris clock workspaces" },
        { idx: 3, section: "",                   title: "Control Center",         icon: "\uf1de", col: "#5E5CE6", keywords: "wifi bluetooth audio volume brightness quick settings" },
        { idx: 4, section: "",                   title: "Spotlight Command Bar",  icon: "\uf002", col: "#32ADE6", keywords: "spotlight search launch apps calculator math command" },
        { idx: 5, section: "",                   title: "Window Tiling & Spaces", icon: "\uf009", col: "#FF9F0A", keywords: "hyprland tiling shortcuts keybinds workspaces split float" },
        { idx: 6, section: "INTELLIGENCE & CARE",title: "TitanFocus Deep Work",   icon: "\uf06e", col: "#00C7BE", keywords: "focus pomodoro timer zen notifications do not disturb" },
        { idx: 7, section: "",                   title: "Hardware Guard (THM v3)",icon: "\uf2db", col: "#30D158", keywords: "hardware cpu memory ram psi cgroups sysmon telemetry" }
    ]

    function matchesSearch(item) {
        if (root.searchQuery.trim() === "") return true;
        var q = root.searchQuery.toLowerCase();
        return item.title.toLowerCase().indexOf(q) !== -1 || item.keywords.indexOf(q) !== -1;
    }

    // Right vertical hairline divider
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
        color: Qt.rgba(1, 1, 1, 0.08)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        spacing: 10

        // ── Top Inset: macOS Traffic Lights + Window Drag + Audio Toggle ────
        Item {
            Layout.fillWidth: true
            height: 24

            DragHandler {
                target: null
                onActiveChanged: {
                    if (active && typeof rootWindow !== "undefined") {
                        rootWindow.startSystemMove();
                    }
                }
            }

            Row {
                id: trafficRow
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                property bool groupHovered: closeArea.containsMouse || minArea.containsMouse || maxArea.containsMouse

                // Red: Close
                Rectangle {
                    width: 12; height: 12; radius: 6
                    color: "#FF5F57"
                    border.width: 1; border.color: "#E0443E"
                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        visible: trafficRow.groupHovered
                        color: "#4D0000"
                        font.family: "Inter"; font.pixelSize: 10; font.weight: Font.Bold
                    }
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent; anchors.margins: -3
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }

                // Yellow: Collapse into Floating Desktop Coach Pill
                Rectangle {
                    width: 12; height: 12; radius: 6
                    color: "#FEBC2E"
                    border.width: 1; border.color: "#DEA123"
                    Text {
                        anchors.centerIn: parent
                        text: "−"
                        visible: trafficRow.groupHovered
                        color: "#5A3E00"
                        font.family: "Inter"; font.pixelSize: 10; font.weight: Font.Bold
                    }
                    MouseArea {
                        id: minArea
                        anchors.fill: parent; anchors.margins: -3
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.startCoachRequested()
                    }
                }

                // Green: Next Chapter
                Rectangle {
                    width: 12; height: 12; radius: 6
                    color: "#28C840"
                    border.width: 1; border.color: "#1AAB29"
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        visible: trafficRow.groupHovered
                        color: "#004D0D"
                        font.family: "Inter"; font.pixelSize: 10; font.weight: Font.Bold
                    }
                    MouseArea {
                        id: maxArea
                        anchors.fill: parent; anchors.margins: -3
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.chapterSelected((root.currentChapter + 1) % root.chapters.length)
                    }
                }
            }

            // Right: Sound FX Toggle
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 24; height: 24; radius: 6
                color: sfxArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: tourCtrl.soundFxEnabled ? "\uf028" : "\uf026"
                    color: tourCtrl.soundFxEnabled ? "#98989D" : "#636366"
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                }
                MouseArea {
                    id: sfxArea
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: tourCtrl.soundFxEnabled = !tourCtrl.soundFxEnabled
                }
            }
        }

        // ── macOS Sidebar Search Field ──────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 30
            radius: 7
            color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1
            border.color: searchInput.activeFocus ? "#0A84FF" : Qt.rgba(1, 1, 1, 0.09)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "\uf002"
                    color: "#8E8E93"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search Guide…"
                        color: "#6E6E73"
                        font.family: "Inter"
                        font.pixelSize: 12
                        visible: searchInput.text.length === 0
                    }

                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#F5F5F7"
                        font.family: "Inter"
                        font.pixelSize: 12
                        clip: true
                        onTextChanged: root.searchQuery = text
                    }
                }

                Rectangle {
                    visible: searchInput.text.length > 0
                    width: 14; height: 14; radius: 7
                    color: "#636366"
                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: "#1C1C1E"
                        font.family: "Inter"; font.pixelSize: 10; font.weight: Font.Bold
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: searchInput.text = ""
                    }
                }
            }
        }

        // ── Categorized Chapter List ────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            Repeater {
                model: root.chapters

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: root.matchesSearch(modelData)

                    // Optional Section Header
                    Item {
                        visible: modelData.section !== "" && root.searchQuery.trim() === ""
                        Layout.fillWidth: true
                        height: modelData.idx === 0 ? 18 : 24

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            text: modelData.section
                            color: "#6E6E73"
                            font.family: "Inter"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 0.6
                        }
                    }

                    // macOS Sidebar Navigation Item
                    Rectangle {
                        id: navItem
                        property bool isCurrent: root.currentChapter === modelData.idx
                        Layout.fillWidth: true
                        height: 34
                        radius: 8

                        color: isCurrent ? Qt.rgba(10/255, 132/255, 255/255, 0.22)
                                         : (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                        border.width: isCurrent ? 1 : 0
                        border.color: Qt.rgba(10/255, 132/255, 255/255, 0.45)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            // Colorful macOS Rounded-Square Squircle Icon
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 6
                                color: modelData.col
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.24)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: "#FFFFFF"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                }
                            }

                            Text {
                                text: modelData.title
                                color: navItem.isCurrent ? "#FFFFFF" : "#D1D1D6"
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: navItem.isCurrent ? 600 : 500
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                tourCtrl.playSound("tap");
                                root.chapterSelected(modelData.idx);
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }

        // ── Bottom Sidebar Actions: Guided Desktop Coach + Login Checkbox ───
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.07)
        }

        // Interactive Desktop Coach Pill Button
        Rectangle {
            Layout.fillWidth: true
            height: 36
            radius: 8
            gradient: Gradient {
                GradientStop { position: 0.0; color: coachMouse.containsMouse ? "#2563EB" : "#1D4ED8" }
                GradientStop { position: 1.0; color: coachMouse.containsMouse ? "#1D4ED8" : "#1E3A8A" }
            }
            border.width: 1
            border.color: "#3B82F6"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Rectangle {
                    width: 20; height: 20; radius: 5
                    color: Qt.rgba(1, 1, 1, 0.16)
                    Text {
                        anchors.centerIn: parent
                        text: "\uf140"
                        color: "#64D2FF"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "Guide Me on Desktop"
                        color: "#FFFFFF"
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.weight: 600
                    }
                    Text {
                        text: "Floating Hands-On Coach"
                        color: "#93C5FD"
                        font.family: "Inter"
                        font.pixelSize: 9
                    }
                }

                Text {
                    text: "↗"
                    color: "#93C5FD"
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }
            }

            MouseArea {
                id: coachMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.startCoachRequested()
            }
        }

        // Show at Login Checkbox (or Live USB Install)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: !tourCtrl.isLiveMode

            Rectangle {
                width: 15; height: 15; radius: 4
                color: tourCtrl.showOnStartup ? "#0A84FF" : "#2C2C2E"
                border.width: 1
                border.color: tourCtrl.showOnStartup ? "#389BFF" : Qt.rgba(1, 1, 1, 0.22)

                Text {
                    visible: tourCtrl.showOnStartup
                    anchors.centerIn: parent
                    text: "\uf00c"
                    color: "#FFFFFF"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 8
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tourCtrl.playSound("tap");
                        tourCtrl.showOnStartup = !tourCtrl.showOnStartup;
                    }
                }
            }

            Text {
                text: "Show guide at login"
                color: "#8E8E93"
                font.family: "Inter"
                font.pixelSize: 11
                Layout.fillWidth: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tourCtrl.playSound("tap");
                        tourCtrl.showOnStartup = !tourCtrl.showOnStartup;
                    }
                }
            }
        }

        // Live ISO Quick Installer Action
        Rectangle {
            visible: tourCtrl.isLiveMode
            Layout.fillWidth: true
            height: 30
            radius: 7
            color: Qt.rgba(48/255, 209/255, 88/255, 0.18)
            border.width: 1
            border.color: "#30D158"

            Row {
                anchors.centerIn: parent
                spacing: 6
                Text { text: "\uf019"; color: "#30D158"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Install ArchTitan to Disk…"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 11; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: tourCtrl.launchInstaller()
            }
        }
    }
}
