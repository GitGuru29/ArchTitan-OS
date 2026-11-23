import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // ── Hero Section ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 18

            // Logo with subtle ambient halo
            Item {
                width: 54
                height: 54

                Rectangle {
                    anchors.centerIn: parent
                    width: 50
                    height: 50
                    radius: 25
                    color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.12)
                    border.width: 1
                    border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.3)
                }

                Image {
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    source: tourCtrl.logoUrl
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "Welcome to ArchTitan OS"
                    color: TitanTheme.textHigh
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }

                Text {
                    text: "A high-velocity, memory-guarded Linux desktop powered by Hyprland and C++20 daemons."
                    color: TitanTheme.textMid
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }

        // ── Live Media Banner (shown only on live ISO) ──────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 46
            radius: 10
            visible: tourCtrl.isLiveMode
            color: Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.10)
            border.width: 1
            border.color: Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.35)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 12
                spacing: 12

                Text {
                    text: "\uf05a" // Info icon
                    color: TitanTheme.warning
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 14
                }

                Text {
                    text: "Live Media Mode: Test your hardware, audio, and Wi-Fi, or install ArchTitan to your SSD."
                    color: TitanTheme.textHigh
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitHeight: 28
                    implicitWidth: liveBtnRow.implicitWidth + 16
                    radius: 6
                    color: liveMouse.containsMouse ? Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.3)
                                                   : Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.18)
                    border.width: 1
                    border.color: Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.5)

                    Row {
                        id: liveBtnRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "\uf019"
                            color: TitanTheme.warning
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Launch Installer"
                            color: TitanTheme.textHigh
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: liveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tourCtrl.launchInstaller()
                    }
                }
            }
        }

        // ── 3 Core Pillars (Bento Cards) ────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // Pillar 1: THM v3
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.6)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.16)
                        border.width: 1
                        border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.35)

                        Text {
                            anchors.centerIn: parent
                            text: "\uf2db" // Microchip
                            color: TitanTheme.accent
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 14
                        }
                    }

                    Text {
                        text: "Titan Hardware Manager"
                        color: TitanTheme.textHigh
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Continuous Linux PSI engine with asymmetric cgroups v2. Reserves 25ms CPU headroom and protects interactive UI from memory thrashing."
                        color: TitanTheme.textLow
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Pillar 2: TitanFocus & Zen
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.6)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: Qt.rgba(TitanTheme.teal.r, TitanTheme.teal.g, TitanTheme.teal.b, 0.16)
                        border.width: 1
                        border.color: Qt.rgba(TitanTheme.teal.r, TitanTheme.teal.g, TitanTheme.teal.b, 0.35)

                        Text {
                            anchors.centerIn: parent
                            text: "\uf06e" // Eye / Focus
                            color: TitanTheme.teal
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 14
                        }
                    }

                    Text {
                        text: "TitanFocus & HUDs"
                        color: TitanTheme.textHigh
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Native C++20 Wayland status overlays, MPRIS dynamic media island, and distraction-free workflow timer summoned with Super+Alt+F."
                        color: TitanTheme.textLow
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Pillar 3: Hyprland Speed
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.6)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: Qt.rgba(TitanTheme.mauve.r, TitanTheme.mauve.g, TitanTheme.mauve.b, 0.16)
                        border.width: 1
                        border.color: Qt.rgba(TitanTheme.mauve.r, TitanTheme.mauve.g, TitanTheme.mauve.b, 0.35)

                        Text {
                            anchors.centerIn: parent
                            text: "\uf0e7" // Lightning
                            color: TitanTheme.mauve
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 14
                        }
                    }

                    Text {
                        text: "Hyprland Tiling"
                        color: TitanTheme.textHigh
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Fluid Wayland compositor with dynamic dwindle tree, multi-workspace routing, and instantaneous fuzzy spotlight launcher with Super+Space."
                        color: TitanTheme.textLow
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
