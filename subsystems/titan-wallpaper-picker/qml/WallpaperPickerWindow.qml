import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: root

    width: Screen.width > 0 ? Screen.width : 1920
    height: Screen.height > 0 ? Screen.height : 1080
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    title: "titan-wallpaper-picker"

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (typeof WallpaperBackend !== "undefined" && WallpaperBackend.revertPreview) {
                WallpaperBackend.revertPreview();
            }
            Qt.quit();
        }
    }

    // Fullscreen Scrim (click-away dismissal)
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (typeof WallpaperBackend !== "undefined" && WallpaperBackend.revertPreview) {
                    WallpaperBackend.revertPreview();
                }
                Qt.quit();
            }
        }
    }

    // Centered Liquid Glass Picker Card
    Rectangle {
        id: card
        width: Math.min(940, parent.width - 64)
        height: Math.min(640, parent.height - 64)
        anchors.centerIn: parent

        color: typeof Theme !== "undefined" ? Theme.surface : Qt.rgba(0.08, 0.08, 0.12, 0.92)
        radius: 20
        border.width: 1
        border.color: typeof Theme !== "undefined" ? Theme.border : Qt.rgba(1, 1, 1, 0.12)

        // Specular inner glow / 3D edge highlight
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 19
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)
        }

        MouseArea {
            // Prevent clicks inside card from propagating to scrim
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "󰸉  Desktop Wallpaper"
                        font.family: "Inter, JetBrainsMono Nerd Font, sans-serif"
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        color: typeof Theme !== "undefined" ? Theme.textPrimary : "#ffffff"
                    }

                    Text {
                        text: "Select a background to apply across all workspaces"
                        font.family: "Inter, sans-serif"
                        font.pixelSize: 12
                        color: typeof Theme !== "undefined" ? Theme.textSecondary : Qt.rgba(1, 1, 1, 0.6)
                    }
                }

                // Close Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: closeBtnArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.10)

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 13
                        color: typeof Theme !== "undefined" ? Theme.textPrimary : "#ffffff"
                    }

                    MouseArea {
                        id: closeBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof WallpaperBackend !== "undefined" && WallpaperBackend.revertPreview) {
                                WallpaperBackend.revertPreview();
                            }
                            Qt.quit();
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // Wallpaper Grid
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                GridView {
                    id: grid
                    cellWidth: 280
                    cellHeight: 180
                    boundsBehavior: Flickable.StopAtBounds

                    model: (typeof WallpaperLibrary !== "undefined" && WallpaperLibrary.paths)
                           ? WallpaperLibrary.paths
                           : []

                    delegate: Item {
                        width: grid.cellWidth
                        height: grid.cellHeight

                        property bool isCurrent: (typeof WallpaperLibrary !== "undefined" && WallpaperLibrary.current === modelData)
                        property bool isHovered: tileMouseArea.containsMouse

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 8
                            radius: 12
                            color: Qt.rgba(0, 0, 0, 0.3)
                            clip: true
                            border.width: isCurrent ? 2.5 : (isHovered ? 1.5 : 1)
                            border.color: isCurrent
                                          ? (typeof Theme !== "undefined" ? Theme.accent : "#00d2ff")
                                          : (isHovered ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.10))

                            scale: isHovered ? 1.02 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            // Thumbnail preview
                            Image {
                                anchors.fill: parent
                                anchors.margins: isCurrent ? 2 : 1
                                source: "image://thumbs/" + modelData
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                mipmap: true

                                // Dim overlay on non-selected, non-hovered
                                Rectangle {
                                    anchors.fill: parent
                                    color: isHovered ? "transparent" : Qt.rgba(0, 0, 0, 0.15)
                                }
                            }

                            // Active Check Badge
                            Rectangle {
                                visible: isCurrent
                                width: 26
                                height: 26
                                radius: 13
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 8
                                color: typeof Theme !== "undefined" ? Theme.accent : "#00d2ff"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    font.bold: true
                                    font.pixelSize: 13
                                    color: "#11111b"
                                }
                            }

                            // Label banner on bottom
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 32
                                color: Qt.rgba(0, 0, 0, 0.70)

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    text: {
                                        var parts = (modelData || "").split("/");
                                        var name = parts[parts.length - 1] || "";
                                        return name.replace(/\.[^/.]+$/, "");
                                    }
                                    font.family: "Inter, sans-serif"
                                    font.pixelSize: 11
                                    font.weight: isCurrent ? Font.DemiBold : Font.Normal
                                    color: isCurrent ? (typeof Theme !== "undefined" ? Theme.accent : "#00d2ff") : "#ffffff"
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: tileMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    if (typeof WallpaperLibrary !== "undefined") {
                                        WallpaperLibrary.setCurrent(modelData);
                                    }
                                    if (typeof WallpaperBackend !== "undefined") {
                                        WallpaperBackend.apply(modelData, "fill", false);
                                    }
                                    Qt.quit();
                                }
                            }
                        }
                    }
                }
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: (grid.count || 0) + " wallpapers available"
                    font.family: "Inter, sans-serif"
                    font.pixelSize: 11
                    color: typeof Theme !== "undefined" ? Theme.textSecondary : Qt.rgba(1, 1, 1, 0.5)
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "Rescan"
                    onClicked: {
                        if (typeof WallpaperLibrary !== "undefined") {
                            WallpaperLibrary.rescan();
                        }
                    }
                }
            }
        }
    }
}
