import QtQuick
import QtQuick.Layouts

Item {
    id: root
    signal finishRequested()

    // Helper to find active wallpaper metadata
    function activeWallpaperObj() {
        var list = tourCtrl.wallpapers;
        for (var i = 0; i < list.length; i++) {
            if (list[i].path === tourCtrl.selectedWallpaper) {
                return list[i];
            }
        }
        return list.length > 0 ? list[0] : { name: "Watchtower", tag: "Dynamic 4K", url: "", path: "" };
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        spacing: 12

        // ── Centered macOS Title ────────────────────────────────────────────
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Choose Your Look"
                color: "#F5F5F7"
                font.family: "Inter"
                font.pixelSize: 22
                font.weight: Font.Bold
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Select a desktop wallpaper below. Your choice transitions live on your desktop immediately."
                color: "#98989D"
                font.family: "Inter"
                font.pixelSize: 12
            }
        }

        // ── Upper Card: macOS System Settings Style Active Desktop Preview ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 104
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.045)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 18

                // Miniature Mac Display Bezel showing Current Wallpaper
                Rectangle {
                    width: 162
                    height: 82
                    radius: 8
                    color: "#0D1322"
                    border.width: 2
                    border.color: Qt.rgba(1, 1, 1, 0.24)
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.activeWallpaperObj().url
                        fillMode: Image.PreserveAspectCrop
                    }

                    // Mini top bar inside preview
                    Rectangle {
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 5
                        anchors.rightMargin: 5
                        height: 9
                        radius: 3
                        color: Qt.rgba(0.08, 0.09, 0.12, 0.85)
                    }

                    // Mini floating window silhouette inside preview
                    Rectangle {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 4
                        width: 78
                        height: 44
                        radius: 5
                        color: Qt.rgba(0.12, 0.13, 0.16, 0.88)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.22)
                    }
                }

                // Current Wallpaper Details
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        spacing: 8
                        Text {
                            text: root.activeWallpaperObj().name
                            color: "#F5F5F7"
                            font.family: "Inter"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        Rectangle {
                            implicitHeight: 20
                            implicitWidth: tagTxt.implicitWidth + 12
                            radius: 10
                            color: Qt.rgba(48/255, 209/255, 88/255, 0.16)
                            border.width: 1
                            border.color: "#30D158"

                            Text {
                                id: tagTxt
                                anchors.centerIn: parent
                                text: "✓ Active Wallpaper"
                                color: "#30D158"
                                font.family: "Inter"
                                font.pixelSize: 10
                                font.weight: 600
                            }
                        }
                    }

                    Text {
                        text: "Curated ArchTitan 4K Desktop Environment • Instant Wayland Transition"
                        color: "#98989D"
                        font.family: "Inter"
                        font.pixelSize: 12
                    }
                }

                // Button to Open Full Appearance Settings
                Rectangle {
                    implicitHeight: 30
                    implicitWidth: moreRow.implicitWidth + 18
                    radius: 7
                    color: moreMouse.containsMouse ? "#3A3A3E" : "#2E2E32"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.14)

                    Row {
                        id: moreRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "\uf013"
                            color: "#AEAEB2"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Appearance Settings…"
                            color: "#F5F5F7"
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.weight: 500
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: moreMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tourCtrl.launchSettings()
                    }
                }
            }
        }

        // ── Lower Grid: 3x2 Curated macOS Wallpaper Thumbnails ──────────────
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 3
            columnSpacing: 12
            rowSpacing: 10

            Repeater {
                model: tourCtrl.wallpapers

                Rectangle {
                    id: wpCard
                    property bool isSelected: tourCtrl.selectedWallpaper === modelData.path
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: "#222226"
                    border.width: isSelected ? 2 : 1
                    border.color: isSelected ? "#0A84FF"
                                             : (wpMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.10))
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: wpCard.isSelected ? 2 : 1
                        source: modelData.url
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: wpMouse.containsMouse || wpCard.isSelected ? 1.0 : 0.85
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                    }

                    // Bottom Gradient Scrim + Wallpaper Title
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 30
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.82) }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 6

                            Text {
                                text: modelData.name
                                color: "#F5F5F7"
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.weight: 600
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: wpCard.isSelected
                                width: 16
                                height: 16
                                radius: 8
                                color: "#0A84FF"
                                border.width: 1
                                border.color: "#FFFFFF"
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf00c"
                                    color: "#FFFFFF"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 8
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: wpMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tourCtrl.applyWallpaper(modelData.path)
                    }
                }
            }
        }
    }
}
