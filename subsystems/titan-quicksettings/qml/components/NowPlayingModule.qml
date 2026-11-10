import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * NowPlayingModule — ArchTitan macOS-style Media Player Bento Module.
 *
 * Implements the ArchTitan media card with:
 * - Header: "Media Player" with options badge
 * - Solaris album art badge with neon depth
 * - Dynamic animated Sapphire Cyan soundwave / equalizer visualizer
 * - Tactile media controls (Prev, Play/Pause, Next)
 */
Rectangle {
    id: mediaRoot
    Layout.fillWidth: true
    implicitHeight: 110
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                  ? TitanTheme.accent
                  : (mediaMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)
    border.width: 1

    property bool isPlaying: true
    property string title: "Solaris"
    property string artist: "Solaris"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        // ── Card Header ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Media Player"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: TitanTheme.textPrimary
            }

            Item { Layout.fillWidth: true }

            // Audio settings / mixer button
            Rectangle {
                width: 22
                height: 22
                radius: 11
                color: mediaOptMa.containsMouse ? TitanTheme.bgHover : Qt.rgba(1, 1, 1, 0.06)

                Text {
                    anchors.centerIn: parent
                    text: "\uf025" // headphones / audio settings
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 10
                    color: mediaOptMa.containsMouse ? TitanTheme.accent : TitanTheme.textMuted
                }

                MouseArea {
                    id: mediaOptMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof systemCtrl !== "undefined" && systemCtrl)
                            systemCtrl.openMediaWidget();
                    }
                }
            }
        }

        // ── Body Row ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Album Art Medallion ("SOLARIS")
            Rectangle {
                width: 50
                height: 50
                radius: 10
                color: "#121A28"
                border.color: Qt.rgba(0.04, 0.52, 1.0, 0.35)
                border.width: 1
                clip: true

                // Deep sapphire nebula gradient
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#0B1528" }
                    GradientStop { position: 0.6; color: "#162846" }
                    GradientStop { position: 1.0; color: "#0E3A5F" }
                }

                // Album Art Label
                Text {
                    anchors.centerIn: parent
                    text: "SOLARIS"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 7
                    font.weight: Font.Black
                    font.letterSpacing: 1.2
                    color: Qt.rgba(1, 1, 1, 0.85)
                }

                // Tiny glowing starburst dot
                Rectangle {
                    width: 3
                    height: 3
                    radius: 1.5
                    color: "#FFFFFF"
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 6
                }
            }

            // Track Metadata + Dynamic Waveform + Controls
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2

                // Track & Artist Title
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: mediaRoot.title
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: TitanTheme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: mediaRoot.artist
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 9
                        color: TitanTheme.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Animated Soundwave / Waveform Visualizer
                RowLayout {
                    Layout.fillWidth: true
                    height: 14
                    spacing: 2

                    Repeater {
                        model: [6, 12, 5, 14, 9, 13, 6, 11, 4, 13, 8, 12, 6, 10]
                        Rectangle {
                            id: waveBar
                            width: 2
                            radius: 1
                            color: TitanTheme.accent
                            Layout.alignment: Qt.AlignVCenter
                            height: modelData

                            SequentialAnimation on height {
                                running: mediaRoot.isPlaying
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: Math.max(3, (modelData * (0.4 + (index % 5) * 0.15)))
                                    duration: 200 + (index * 45)
                                    easing.type: Easing.InOutQuad
                                }
                                NumberAnimation {
                                    to: Math.min(14, (modelData * (0.8 + ((index + 2) % 4) * 0.2)))
                                    duration: 220 + (index * 40)
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Playback Controls Row
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 8

                    // Previous Track
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: prevMa.containsMouse ? TitanTheme.bgHover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "\uf048" // step-backward
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
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

                    // Play / Pause
                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        color: playMa.containsMouse ? TitanTheme.bgHover : Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: mediaRoot.isPlaying ? "\uf04c" : "\uf04b" // pause : play
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                            color: TitanTheme.textPrimary
                        }

                        MouseArea {
                            id: playMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof audioCtrl !== "undefined" && audioCtrl) {
                                    audioCtrl.togglePlayPause();
                                } else {
                                    mediaRoot.isPlaying = !mediaRoot.isPlaying;
                                }
                            }
                        }
                    }

                    // Next Track
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: nextMa.containsMouse ? TitanTheme.bgHover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "\uf051" // step-forward
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
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
    }

    MouseArea {
        id: mediaMa
        anchors.fill: parent
        hoverEnabled: true
        z: -1
    }
}
