import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * BannerMusicWidget — Full-Width Luxury Music Player Banner.
 *
 * Designed for when users place the Music Player on its own row
 * (e.g. at the bottom of Quick Settings). Features 24px super-round
 * card, expanded album artwork, seek bar, and circular controls.
 */
Rectangle {
    id: bannerRoot
    Layout.fillWidth: true
    implicitHeight: 96
    radius: TitanTheme.radiusCard // 24px super-round
    color: TitanTheme.bgOneUICard
    border.color: TitanTheme.borderGlass
    border.width: 1
    clip: true

    property bool isPlaying: (typeof audioCtrl !== "undefined" && audioCtrl) ? !audioCtrl.sinkMuted : true
    property string trackTitle: "ArchTitan Audio Engine"
    property string artistName: "PipeWire • WirePlumber Native"

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // 1. Album Artwork Squircle (54x54, radius: 18px)
        Rectangle {
            Layout.preferredWidth: 54
            Layout.preferredHeight: 54
            radius: 18
            color: Qt.rgba(0, 0, 0, 0.40)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.16)
            clip: true

            Text {
                anchors.centerIn: parent
                text: "\uf001" // music note
                font.family: TitanTheme.monoFamily
                font.pixelSize: 20
                color: bannerRoot.isPlaying ? TitanTheme.accent : TitanTheme.textMuted
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        // 2. Track Details & Progress
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: bannerRoot.trackTitle
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: TitanTheme.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Micro Equalizer Visualizer
                Row {
                    spacing: 2
                    visible: bannerRoot.isPlaying
                    Repeater {
                        model: 3
                        Rectangle {
                            width: 3
                            height: 6 + (index * 3)
                            radius: 1.5
                            color: TitanTheme.accent
                            SequentialAnimation on height {
                                running: bannerRoot.isPlaying
                                loops: Animation.Infinite
                                NumberAnimation { to: 14 - (index * 3); duration: 240 + (index * 80); easing.type: Easing.InOutQuad }
                                NumberAnimation { to: 4 + (index * 2); duration: 200 + (index * 60); easing.type: Easing.InOutQuad }
                            }
                        }
                    }
                }
            }

            Text {
                text: bannerRoot.artistName
                font.family: TitanTheme.fontFamily
                font.pixelSize: 10
                color: TitanTheme.textMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Progress Bar Track
            Rectangle {
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: TitanTheme.bgInset
                clip: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * 0.45
                    radius: 2
                    color: TitanTheme.accent
                }
            }
        }

        // 3. Circular Playback Controls
        RowLayout {
            spacing: 6

            // Prev Button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: prevMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
                border.color: TitanTheme.borderGlass
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "\uf048" // step-backward
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 10
                    color: TitanTheme.textPrimary
                }

                MouseArea {
                    id: prevMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.previousTrack()
                    }
                }
            }

            // Play / Pause Circle
            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: bannerRoot.isPlaying ? TitanTheme.accent : TitanTheme.bgOneUIPill
                border.color: bannerRoot.isPlaying ? TitanTheme.borderActive : TitanTheme.borderGlass
                border.width: 1
                scale: playMa.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: 110 } }

                Text {
                    anchors.centerIn: parent
                    text: bannerRoot.isPlaying ? "\uf04c" : "\uf04b" // pause / play
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 13
                    color: bannerRoot.isPlaying ? "#0F141C" : TitanTheme.textPrimary
                }

                MouseArea {
                    id: playMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.playPause()
                    }
                }
            }

            // Next Button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: nextMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
                border.color: TitanTheme.borderGlass
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "\uf051" // step-forward
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 10
                    color: TitanTheme.textPrimary
                }

                MouseArea {
                    id: nextMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.nextTrack()
                    }
                }
            }
        }
    }
}
