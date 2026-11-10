import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * NowPlayingModule — macOS-style Native Now Playing Media Bento Module.
 *
 * Compact desktop media tile featuring album art badge, track metadata,
 * PipeWire live status, and integrated tactile playback controls.
 */
Rectangle {
    id: mediaRoot
    Layout.fillWidth: true
    implicitHeight: 64
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: TitanTheme.borderHairline
    border.width: 1

    property bool isPlaying: true
    property string title: "ArchTitan Audio Engine"
    property string artist: "PipeWire · Native High-Res"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        // Album Art / Audio Medallion
        Rectangle {
            width: 40
            height: 40
            radius: 10
            color: TitanTheme.bgInset
            border.color: TitanTheme.borderHairline
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "\uf001" // music
                font.family: TitanTheme.monoFamily
                font.pixelSize: 15
                color: TitanTheme.accent
            }
        }

        // Track Information
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: mediaRoot.title
                font.family: TitanTheme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: TitanTheme.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: mediaRoot.artist
                font.family: TitanTheme.fontFamily
                font.pixelSize: 10
                color: TitanTheme.textMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // Playback Controls
        RowLayout {
            spacing: 4

            // Previous
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: prevMa.containsMouse ? TitanTheme.bgHover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\uf048" // step-backward
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 11
                    color: TitanTheme.textSecondary
                }

                MouseArea {
                    id: prevMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.previousTrack();
                    }
                }
            }

            // Play / Pause Capsule
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: TitanTheme.accent
                scale: playMa.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 110 } }

                Text {
                    anchors.centerIn: parent
                    text: mediaRoot.isPlaying ? "\uf04c" : "\uf04b" // pause / play
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 11
                    color: "#0D1017"
                }

                MouseArea {
                    id: playMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mediaRoot.isPlaying = !mediaRoot.isPlaying;
                        if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.playPause();
                    }
                }
            }

            // Next
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: nextMa.containsMouse ? TitanTheme.bgHover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\uf051" // step-forward
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 11
                    color: TitanTheme.textSecondary
                }

                MouseArea {
                    id: nextMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.nextTrack();
                    }
                }
            }
        }
    }
}

