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
            badge: "⌘ Super + N",
            title: "Fluid Desktop & Control Center",
            desc: "Workspaces, live media playback, and quick system controls live cleanly along the top edge of your display.",
            targetSlide: 1
        },
        {
            icon: "\uf002",
            gradTop: "#7D7AFF",
            gradBot: "#4B48C8",
            badge: "⌘ Super + Space",
            title: "Spotlight & Effortless Tiling",
            desc: "Launch apps, search files, run calculations, and tile windows automatically with intuitive keyboard shortcuts.",
            targetSlide: 2
        },
        {
            icon: "\uf2db",
            gradTop: "#34D399",
            gradBot: "#059669",
            badge: "THM v3 Guard",
            title: "Adaptive Hardware Intelligence",
            desc: "Continuous CPU and memory protection prioritizes your active window so the desktop stays locked at 60–144 Hz.",
            targetSlide: 4
        }
    ]

    function currentWallpaperUrl() {
        var list = tourCtrl.wallpapers;
        for (var i = 0; i < list.length; i++) {
            if (list[i].path === tourCtrl.selectedWallpaper) return list[i].url;
        }
        return list.length > 0 ? list[0].url : "";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        spacing: 14

        // ── Top Panoramic macOS Sequoia Hero Showcase Banner ────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 184
            radius: 16
            color: "#111625"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.16)
            clip: true

            // Active Wallpaper Backdrop inside Hero Banner
            Image {
                anchors.fill: parent
                source: root.currentWallpaperUrl()
                fillMode: Image.PreserveAspectCrop
                opacity: 0.48
                asynchronous: true
            }

            // Rich Apple Keynote Dark Vignette Gradient
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(0.06, 0.07, 0.11, 0.94) }
                    GradientStop { position: 0.58; color: Qt.rgba(0.06, 0.08, 0.14, 0.78) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.05, 0.07, 0.12, 0.50) }
                }
            }

            // Top Specular Highlight
            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: 1
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 40
                height: 1
                color: Qt.rgba(1, 1, 1, 0.24)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 22
                spacing: 20

                // Left: 3D macOS Squircle Emblem
                Item {
                    width: 82
                    height: 82

                    Rectangle {
                        anchors.centerIn: parent
                        width: 82
                        height: 82
                        radius: 21
                        color: Qt.rgba(10/255, 132/255, 255/255, 0.14)
                        border.width: 1
                        border.color: Qt.rgba(100/255, 210/255, 255/255, 0.30)
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 72
                        height: 72
                        radius: 18
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#1E40AF" }
                            GradientStop { position: 0.5; color: "#172554" }
                            GradientStop { position: 1.0; color: "#0B1120" }
                        }
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.32)

                        Image {
                            anchors.centerIn: parent
                            width: 44
                            height: 44
                            source: tourCtrl.logoUrl
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }
                    }
                }

                // Middle: Hero Typography & Live Pill Badges
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Row {
                        spacing: 8

                        Rectangle {
                            implicitHeight: 20
                            implicitWidth: relText.implicitWidth + 14
                            radius: 10
                            color: Qt.rgba(10/255, 132/255, 255/255, 0.22)
                            border.width: 1
                            border.color: "#0A84FF"

                            Text {
                                id: relText
                                anchors.centerIn: parent
                                text: tourCtrl.isLiveMode ? "LIVE USB ENVIRONMENT" : "ARCHTITAN OS • 2026.11"
                                color: "#64D2FF"
                                font.family: "Inter"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }

                        Rectangle {
                            implicitHeight: 20
                            implicitWidth: wayText.implicitWidth + 12
                            radius: 10
                            color: Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.14)

                            Text {
                                id: wayText
                                anchors.centerIn: parent
                                text: "Wayland • Hyprland"
                                color: "#D1D1D6"
                                font.family: "Inter"
                                font.pixelSize: 10
                                font.weight: 600
                            }
                        }
                    }

                    Text {
                        text: "Welcome to ArchTitan"
                        color: "#FFFFFF"
                        font.family: "Inter"
                        font.pixelSize: 30
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Mac-inspired refinement meets bare-metal Linux speed, automatic window tiling, and real-time hardware intelligence."
                        color: "#D1D1D6"
                        font.family: "Inter"
                        font.pixelSize: 13
                        lineHeight: 1.3
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }

                // Right: Floating 3D Glass Desktop Widget Preview Stack
                Column {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter

                    // Floating Pill 1: Dynamic Media Island
                    Rectangle {
                        width: 196
                        height: 36
                        radius: 18
                        color: Qt.rgba(0.09, 0.10, 0.15, 0.88)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.20)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 12
                            spacing: 8

                            Rectangle {
                                width: 20; height: 20; radius: 10
                                color: "#BF5AF2"
                                Text { anchors.centerIn: parent; text: "\uf001"; color: "#FFFFFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9 }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text { text: "Now Playing Island"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 10; font.weight: 600 }
                                Text { text: "Live MPRIS2 • Top Bar"; color: "#98989D"; font.family: "Inter"; font.pixelSize: 9 }
                            }
                        }
                    }

                    // Floating Pill 2: THM v3 Kernel Guard
                    Rectangle {
                        width: 196
                        height: 36
                        radius: 18
                        color: Qt.rgba(0.09, 0.10, 0.15, 0.88)
                        border.width: 1
                        border.color: Qt.rgba(48/255, 209/255, 88/255, 0.40)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 12
                            spacing: 8

                            Rectangle {
                                width: 20; height: 20; radius: 10
                                color: "#30D158"
                                Text { anchors.centerIn: parent; text: "\uf0e7"; color: "#FFFFFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9 }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text { text: "25ms CPU Headroom"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 10; font.weight: 600 }
                                Text { text: "Zero UI Frame Drops"; color: "#30D158"; font.family: "Inter"; font.pixelSize: 9; font.weight: 600 }
                            }
                        }
                    }

                    // Floating Pill 3: TitanFocus Zen Mode
                    Rectangle {
                        width: 196
                        height: 36
                        radius: 18
                        color: Qt.rgba(0.09, 0.10, 0.15, 0.88)
                        border.width: 1
                        border.color: Qt.rgba(10/255, 132/255, 255/255, 0.40)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 12
                            spacing: 8

                            Rectangle {
                                width: 20; height: 20; radius: 10
                                color: "#0A84FF"
                                Text { anchors.centerIn: parent; text: "\uf06e"; color: "#FFFFFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9 }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text { text: "TitanFocus & Spotlight"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 10; font.weight: 600 }
                                Text { text: "Instant Wayland Overlays"; color: "#64D2FF"; font.family: "Inter"; font.pixelSize: 9 }
                            }
                        }
                    }
                }
            }
        }

        // ── 3 Interactive Apple "What's New" Feature Cards ──────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 9

            Repeater {
                model: root.features

                Rectangle {
                    id: featRow
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08)
                                                  : Qt.rgba(1, 1, 1, 0.045)
                    border.width: 1
                    border.color: rowMouse.containsMouse ? "#0A84FF"
                                                         : Qt.rgba(1, 1, 1, 0.08)

                    Behavior on color { ColorAnimation { duration: 140 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 16

                        // macOS Glossy Squircle Icon
                        Rectangle {
                            width: 44
                            height: 44
                            radius: 11
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: modelData.gradTop }
                                GradientStop { position: 1.0; color: modelData.gradBot }
                            }
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.30)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: "#FFFFFF"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 17
                            }
                        }

                        // Feature Title, Shortcut Tag & Description
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            RowLayout {
                                spacing: 8
                                Text {
                                    text: modelData.title
                                    color: "#F5F5F7"
                                    font.family: "Inter"
                                    font.pixelSize: 14
                                    font.weight: 600
                                }

                                Rectangle {
                                    implicitHeight: 18
                                    implicitWidth: bTxt.implicitWidth + 10
                                    radius: 5
                                    color: Qt.rgba(1, 1, 1, 0.07)
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.12)
                                    Text {
                                        id: bTxt
                                        anchors.centerIn: parent
                                        text: modelData.badge
                                        color: "#AEAEB2"
                                        font.family: "Inter"
                                        font.pixelSize: 10
                                        font.weight: 600
                                    }
                                }
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
                            implicitHeight: 28
                            implicitWidth: exploreRow.implicitWidth + 18
                            radius: 14
                            color: rowMouse.containsMouse ? "#0A84FF"
                                                          : Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1
                            border.color: rowMouse.containsMouse ? "#389BFF" : Qt.rgba(1, 1, 1, 0.12)

                            Row {
                                id: exploreRow
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    text: "Explore"
                                    color: rowMouse.containsMouse ? "#FFFFFF" : "#D1D1D6"
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    font.weight: 600
                                }

                                Text {
                                    text: "›"
                                    color: rowMouse.containsMouse ? "#FFFFFF" : "#D1D1D6"
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
