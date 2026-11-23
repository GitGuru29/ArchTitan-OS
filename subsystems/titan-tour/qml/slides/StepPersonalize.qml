import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

Item {
    id: root

    signal finishRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // ── Top Header ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                spacing: 2
                Text {
                    text: "DESKTOP WALLPAPERS & PERSONALIZATION"
                    color: TitanTheme.accent
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.0
                }
                Text {
                    text: "Click any background below to instantly preview & apply it live to your desktop."
                    color: TitanTheme.textLow
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitHeight: 26
                implicitWidth: appliedRow.implicitWidth + 14
                radius: 13
                color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.14)
                border.width: 1
                border.color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.4)

                Row {
                    id: appliedRow
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "\uf00c"; color: TitanTheme.success; font.family: TitanTheme.monoFamily; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "1-Click Live Apply"; color: TitanTheme.success; font.family: TitanTheme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }

        // ── 3x2 Curated Wallpaper Grid ──────────────────────────────────────────
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
                    radius: 8
                    color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.6)
                    border.width: isSelected ? 2 : 1
                    border.color: isSelected ? TitanTheme.accent : (wpMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.08))
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: modelData.url
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: wpMouse.containsMouse ? 0.95 : 0.82
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    // Bottom info gradient scrim
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 32
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(0.04, 0.06, 0.10, 0.95) }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Text {
                                text: modelData.name
                                color: TitanTheme.textHigh
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Active checkmark badge
                            Rectangle {
                                visible: wpCard.isSelected
                                width: 14
                                height: 14
                                radius: 7
                                color: TitanTheme.accent
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf00c"
                                    color: TitanTheme.crust
                                    font.family: TitanTheme.monoFamily
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
                        onClicked: {
                            tourCtrl.applyWallpaper(modelData.path);
                        }
                    }
                }
            }
        }

        // ── Bottom Ready-to-Roll Banner ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 8
            color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.7)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                spacing: 12

                Text {
                    text: tourCtrl.isLiveMode ? "Ready to install ArchTitan permanently?" : "You're all set! Explore ArchTitan OS."
                    color: TitanTheme.textHigh
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 12
                    font.weight: 600
                    Layout.fillWidth: true
                }

                // Quick Launch Pills
                Row {
                    spacing: 8

                    Rectangle {
                        visible: !tourCtrl.isLiveMode
                        implicitHeight: 28
                        implicitWidth: termRow.implicitWidth + 16
                        radius: 6
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        Row {
                            id: termRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "\uf120"; color: TitanTheme.accent; font.family: TitanTheme.monoFamily; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Terminal"; color: TitanTheme.textHigh; font.family: TitanTheme.fontFamily; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: tourCtrl.launchTerminal()
                        }
                    }

                    Rectangle {
                        visible: !tourCtrl.isLiveMode
                        implicitHeight: 28
                        implicitWidth: setRow.implicitWidth + 16
                        radius: 6
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        Row {
                            id: setRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "\uf013"; color: TitanTheme.teal; font.family: TitanTheme.monoFamily; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Settings"; color: TitanTheme.textHigh; font.family: TitanTheme.fontFamily; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: tourCtrl.launchSettings()
                        }
                    }

                    Rectangle {
                        visible: tourCtrl.isLiveMode
                        implicitHeight: 28
                        implicitWidth: instRow.implicitWidth + 16
                        radius: 6
                        color: Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.22)
                        border.width: 1
                        border.color: Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.5)
                        Row {
                            id: instRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "\uf019"; color: TitanTheme.warning; font.family: TitanTheme.monoFamily; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Launch Calamares"; color: TitanTheme.textHigh; font.family: TitanTheme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: tourCtrl.launchInstaller()
                        }
                    }
                }
            }
        }
    }
}
