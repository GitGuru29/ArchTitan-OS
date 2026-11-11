import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

Item {
    id: root

    signal finishTourRequested()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 26

        // Left Column: Live Desktop Wallpaper Studio
        Rectangle {
            Layout.preferredWidth: 450
            Layout.fillHeight: true
            radius: 20
            color: Qt.rgba(TitanTheme.crust.r, TitanTheme.crust.g, TitanTheme.crust.b, 0.72)
            border.width: 1
            border.color: Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.3)

            TitanReticle {
                anchors.fill: parent
                anchors.margins: 10
                color: TitanTheme.warning
                bracketLength: 14
                bracketThickness: 2
                opacity: 0.45
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "LIVE ATMOSPHERE STUDIO // SWWW ENGINE"
                        color: TitanTheme.warning
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "CLICK TO APPLY LIVE"
                        color: TitanTheme.info
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }

                // 2x3 Interactive Wallpaper Thumbnail Grid
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 3
                    rowSpacing: 10
                    columnSpacing: 10

                    Repeater {
                        model: tourCtrl.wallpapers

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool isActive: tourCtrl.selectedWallpaper === modelData.path

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.8)
                            border.width: isActive ? 2 : 1
                            border.color: isActive ? TitanTheme.info : Qt.rgba(1, 1, 1, 0.14)
                            clip: true

                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                source: modelData.url
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 260
                                sourceSize.height: 160
                            }

                            // Bottom Label Scrim
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 26
                                color: Qt.rgba(0.02, 0.03, 0.06, 0.84)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 4

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: isActive ? TitanTheme.info : TitanTheme.textHigh
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        visible: isActive
                                        text: "\uf00c"
                                        color: TitanTheme.info
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    tourCtrl.applyWallpaper(modelData.path);
                                }
                            }
                        }
                    }
                }

                TitanButton {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    text: "Open Full Wallpaper Picker Studio (Super+W)"
                    glyph: "\uf03e"
                    variant: "secondary"
                    onClicked: tourCtrl.launchWallpaperPicker()
                }
            }
        }

        // Right Column: Dual-Mode Ignition Launchpad
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            RowLayout {
                spacing: 10
                Rectangle {
                    height: 24
                    width: ignTag.implicitWidth + 16
                    radius: 12
                    color: Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.16)
                    border.width: 1
                    border.color: Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.45)

                    Text {
                        id: ignTag
                        anchors.centerIn: parent
                        text: tourCtrl.isLiveMode ? "ACT 06 // LIVE ISO DEPLOYMENT" : "ACT 06 // WORKSTATION IGNITION"
                        color: TitanTheme.warning
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: tourCtrl.isLiveMode
                    ? "Ready to Install ArchTitan to Disk?"
                    : "Your ArchTitan Workstation Is Armed"
                color: TitanTheme.textHigh
                font.family: TitanTheme.fontFamily
                font.pixelSize: 26
                font.weight: Font.Black
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                text: tourCtrl.isLiveMode
                    ? "You are currently running in the Live ISO environment. Test your audio, explore the tiling desktop, or launch the Calamares installer to deploy ArchTitan onto NVMe/SSD."
                    : "Customize your live desktop atmosphere on the left or launch directly into your core tools below. You can recall this spatial tour anytime via Titan Spotlight."
                color: TitanTheme.textMid
                font.family: TitanTheme.fontFamily
                font.pixelSize: 12
                lineHeight: 1.35
                wrapMode: Text.WordWrap
            }

            // 2x2 Quick Action Launchpad Bento Grid
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: [
                        {
                            icon: "\uf002",
                            title: "Titan Spotlight",
                            sub: "Super + Space // Fuzzy App Bar",
                            color: TitanTheme.accent,
                            act: function() { tourCtrl.toggleSpotlight(); }
                        },
                        {
                            icon: "\uf1de",
                            title: "Control Center",
                            sub: "Super + N // Stepped Bento HUD",
                            color: TitanTheme.info,
                            act: function() { tourCtrl.toggleControlCenter(); }
                        },
                        {
                            icon: "\uf013",
                            title: "Titan Settings",
                            sub: "Display, Audio, Network & Theme",
                            color: TitanTheme.mauve,
                            act: function() { tourCtrl.launchSettings(); }
                        },
                        {
                            icon: "\uf120",
                            title: "Foot Terminal",
                            sub: "Super + T // Wayland GPU Shell",
                            color: TitanTheme.success,
                            act: function() { tourCtrl.launchTerminal(); }
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 14
                        color: tileMouse.containsMouse
                            ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.16)
                            : Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.55)
                        border.width: 1
                        border.color: tileMouse.containsMouse ? modelData.color : Qt.rgba(1, 1, 1, 0.08)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            Rectangle {
                                width: 40; height: 40; radius: 12
                                color: Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.16)
                                border.width: 1
                                border.color: modelData.color

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: modelData.color
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 16
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: modelData.title
                                    color: TitanTheme.textHigh
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.sub
                                    color: TitanTheme.textMid
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.act()
                        }
                    }
                }
            }

            // Hero Primary Ignition CTA Card
            Rectangle {
                Layout.fillWidth: true
                height: 76
                radius: 18
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.28) }
                    GradientStop { position: 1.0; color: Qt.rgba(TitanTheme.info.r, TitanTheme.info.g, TitanTheme.info.b, 0.22) }
                }
                border.width: 1.5
                border.color: TitanTheme.info

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: tourCtrl.isLiveMode
                                ? "CALAMARES SYSTEM INSTALLER"
                                : "COMPLETE SPATIAL ONBOARDING"
                            color: TitanTheme.info
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 1.0
                        }
                        Text {
                            text: tourCtrl.isLiveMode
                                ? "Partition disk, configure encryption & install ArchTitan"
                                : "Dismiss overlay and enter your Hyprland workspace"
                            color: TitanTheme.textHigh
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }
                    }

                    TitanButton {
                        implicitWidth: 210
                        implicitHeight: 44
                        text: tourCtrl.isLiveMode ? "Install ArchTitan Now" : "Launch Into Desktop"
                        glyph: tourCtrl.isLiveMode ? "\uf019" : "\uf135"
                        variant: "primary"
                        onClicked: {
                            if (tourCtrl.isLiveMode) {
                                tourCtrl.launchInstaller();
                            } else {
                                root.finishTourRequested();
                            }
                        }
                    }
                }
            }
        }
    }
}
