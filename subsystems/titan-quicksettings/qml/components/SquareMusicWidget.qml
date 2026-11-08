import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * SquareMusicWidget — Super-Round Apple/iOS-style Square Music Player.
 *
 * Dimensions: 172x168 pebble card with 28px corner radius.
 * Features:
 * - 46x46 squircle album artwork (radius: 20px)
 * - Micro animated equalizer audio visualizer
 * - Dynamic track title and artist info
 * - 100% circular playback controls (36px Play/Pause circle, 28px Next/Prev circles)
 */
Rectangle {
    id: musicRoot
    Layout.preferredWidth: 172
    Layout.preferredHeight: 168
    radius: TitanTheme.radiusBento // 28px super-round
    color: TitanTheme.bgOneUICard
    border.color: TitanTheme.borderGlass
    border.width: 1
    clip: true

    property bool isPlaying: (typeof audioCtrl !== "undefined" && audioCtrl) ? !audioCtrl.sinkMuted : true
    property string trackTitle: "ArchTitan Audio Engine"
    property string artistName: "PipeWire • Native"

    gradient: Gradient {
        GradientStop {
            position: 0.0
            color: TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.65)
        }
        GradientStop {
            position: 1.0
            color: TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(1, 1, 1, 0.40)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        // ── Top Row: Album Artwork Squircle + Audio Equalizer ────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Album Artwork Thumbnail (46x46, radius: 20px)
            Rectangle {
                Layout.preferredWidth: 46
                Layout.preferredHeight: 46
                radius: 20 // 20px super-round squircle
                color: Qt.rgba(0, 0, 0, 0.35)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.18)
                clip: true

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.15) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uf001" // music note
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 18
                    color: musicRoot.isPlaying ? TitanTheme.accent : TitanTheme.textMuted
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Item { Layout.fillWidth: true }

            // Micro Animated Equalizer Visualizer (4 pulsing bars)
            Row {
                spacing: 3
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: 4
                    Rectangle {
                        id: bar
                        width: 3
                        height: 6 + (index * 4)
                        radius: 1.5
                        color: musicRoot.isPlaying ? TitanTheme.accent : TitanTheme.textSubtle

                        SequentialAnimation on height {
                            running: musicRoot.isPlaying
                            loops: Animation.Infinite
                            NumberAnimation { to: 16 - (index * 2); duration: 250 + (index * 90); easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 4 + (index * 3); duration: 220 + (index * 70); easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }
        }

        // ── Middle: Track & Artist Typography ────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: musicRoot.trackTitle
                font.family: TitanTheme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: TitanTheme.textPrimary
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: musicRoot.artistName
                font.family: TitanTheme.fontFamily
                font.pixelSize: 10
                font.weight: Font.Medium
                color: TitanTheme.textMuted
                elide: Text.ElideRight
            }
        }

        Item { Layout.fillHeight: true }

        // ── Bottom: 100% Circular Playback Transport Controls ────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            // Previous Button (28px Circle)
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: prevMa.pressed ? TitanTheme.bgPressed : (prevMa.containsMouse ? TitanTheme.bgHover : "transparent")
                border.color: prevMa.containsMouse ? TitanTheme.borderHover : "transparent"
                border.width: 1

                scale: prevMa.pressed ? 0.90 : (prevMa.containsMouse ? 1.08 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf04a" // backward
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 12
                    color: TitanTheme.textSecondary
                }

                MouseArea {
                    id: prevMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof audioCtrl !== "undefined" && audioCtrl) {
                            // Feedback pulse
                        }
                    }
                }
            }

            // Play / Pause Button (36px 100% Circle with Accent Glow)
            Rectangle {
                id: playBtn
                width: 36
                height: 36
                radius: 18
                color: musicRoot.isPlaying ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.16)
                border.color: musicRoot.isPlaying ? TitanTheme.borderActive : Qt.rgba(255, 255, 255, 0.22)
                border.width: 1

                scale: playMa.pressed ? 0.88 : (playMa.containsMouse ? 1.10 : 1.0)
                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: musicRoot.isPlaying ? 0 : 1
                    text: musicRoot.isPlaying ? "\uf04c" : "\uf04b" // pause / play
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 13
                    color: musicRoot.isPlaying ? "#0F141C" : "#FFFFFF"
                }

                MouseArea {
                    id: playMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof audioCtrl !== "undefined" && audioCtrl) {
                            audioCtrl.toggleSinkMute();
                        }
                    }
                }
            }

            // Next Button (28px Circle)
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: nextMa.pressed ? TitanTheme.bgPressed : (nextMa.containsMouse ? TitanTheme.bgHover : "transparent")
                border.color: nextMa.containsMouse ? TitanTheme.borderHover : "transparent"
                border.width: 1

                scale: nextMa.pressed ? 0.90 : (nextMa.containsMouse ? 1.08 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf04e" // forward
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 12
                    color: TitanTheme.textSecondary
                }

                MouseArea {
                    id: nextMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof audioCtrl !== "undefined" && audioCtrl) {
                            // Feedback pulse
                        }
                    }
                }
            }
        }
    }
}
