import QtQuick
import QtQuick.Layouts

Item {
    id: root
    signal finishRequested()

    readonly property var paletteSwatches: [
        ["#38BDF8", "#3B82F6", "#1E3A8A", "#F59E0B"],
        ["#89B4FA", "#CBA6F7", "#313244", "#1E1E2E"],
        ["#2DD4BF", "#14B8A6", "#0F766E", "#111827"],
        ["#EB6F92", "#C4A7E7", "#9CCFD8", "#191724"],
        ["#60A5FA", "#2563EB", "#1E293B", "#0F172A"],
        ["#A1A1AA", "#52525B", "#27272A", "#09090B"]
    ]

    function activeWallpaperIndex() {
        var list = tourCtrl.wallpapers;
        for (var i = 0; i < list.length; i++) {
            if (list[i].path === tourCtrl.selectedWallpaper) return i;
        }
        return 0;
    }

    function activeWallpaperObj() {
        var list = tourCtrl.wallpapers;
        var idx = activeWallpaperIndex();
        return list.length > idx ? list[idx] : { name: "Watchtower", tag: "LANDSCAPE", url: "", path: "" };
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
                text: "Select a curated 4K desktop wallpaper. Your selection transitions live on your desktop immediately."
                color: "#98989D"
                font.family: "Inter"
                font.pixelSize: 12
            }
        }

        // ── Upper Card: macOS System Settings Style Active Desktop Preview ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 112
            radius: 14
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.10)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 18

                // Miniature Mac Display Bezel showing Current Wallpaper
                Rectangle {
                    width: 174
                    height: 88
                    radius: 8
                    color: "#0D1322"
                    border.width: 2
                    border.color: "#0A84FF"
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
                        color: Qt.rgba(0.08, 0.09, 0.12, 0.88)

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Rectangle { width: 4; height: 4; radius: 2; color: "#0A84FF" }
                            Rectangle { width: 8; height: 3; radius: 1.5; color: "#64D2FF"; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    // Mini floating window silhouette inside preview
                    Rectangle {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 3
                        width: 84
                        height: 46
                        radius: 5
                        color: Qt.rgba(0.11, 0.12, 0.16, 0.90)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.24)

                        Row {
                            x: 5; y: 4; spacing: 2.5
                            Rectangle { width: 3.5; height: 3.5; radius: 1.75; color: "#FF5F57" }
                            Rectangle { width: 3.5; height: 3.5; radius: 1.75; color: "#FEBC2E" }
                            Rectangle { width: 3.5; height: 3.5; radius: 1.75; color: "#28C840" }
                        }
                    }
                }

                // Current Wallpaper Details + Color Palette Swatches
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    RowLayout {
                        spacing: 8
                        Text {
                            text: root.activeWallpaperObj().name
                            color: "#F5F5F7"
                            font.family: "Inter"
                            font.pixelSize: 17
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
                                text: "✓ Active Desktop"
                                color: "#30D158"
                                font.family: "Inter"
                                font.pixelSize: 10
                                font.weight: 600
                            }
                        }
                    }

                    Text {
                        text: "Curated 4K Desktop Environment • Adaptive Waybar & Accent Palette"
                        color: "#98989D"
                        font.family: "Inter"
                        font.pixelSize: 12
                    }

                    // Palette Swatch Row
                    Row {
                        spacing: 6
                        Text {
                            text: "Theme Accents:"
                            color: "#8E8E93"
                            font.family: "Inter"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Repeater {
                            model: root.paletteSwatches[root.activeWallpaperIndex() % root.paletteSwatches.length]
                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                color: modelData
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.35)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                // Button to Open Full Appearance Settings
                Rectangle {
                    implicitHeight: 32
                    implicitWidth: moreRow.implicitWidth + 18
                    radius: 8
                    color: moreMouse.containsMouse ? "#3A3A3E" : "#2E2E32"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.16)

                    Row {
                        id: moreRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "\uf013"
                            color: "#64D2FF"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Appearance Settings…"
                            color: "#F5F5F7"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: 600
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
                                             : (wpMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.32) : Qt.rgba(1, 1, 1, 0.10))
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

                    // Top-Left Theme Tag Badge
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 8
                        implicitHeight: 18
                        implicitWidth: tTag.implicitWidth + 10
                        radius: 5
                        color: Qt.rgba(0.06, 0.07, 0.10, 0.78)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.16)

                        Text {
                            id: tTag
                            anchors.centerIn: parent
                            text: modelData.tag
                            color: "#D1D1D6"
                            font.family: "Inter"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }

                    // Bottom Gradient Scrim + Wallpaper Title
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 32
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.86) }
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
                                font.pixelSize: 12
                                font.weight: 600
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: wpCard.isSelected
                                width: 18
                                height: 18
                                radius: 9
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
