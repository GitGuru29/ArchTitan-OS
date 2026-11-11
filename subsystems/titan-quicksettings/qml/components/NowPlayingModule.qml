import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * NowPlayingModule — macOS Control Center "Now Playing" Bento Card.
 *
 * Matches the macOS Control Center media widget:
 * - Header: "Now Playing"
 * - 52x52 vibrant multi-hue aurora album art square
 * - Track title ("Solaris Drift") + Artist subtitle
 * - Tactile media transport controls (Prev, Play/Pause, Next)
 */
Rectangle {
    id: mediaRoot
    Layout.fillWidth: true
    implicitHeight: 108
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                  ? TitanTheme.accent
                  : TitanTheme.borderHairline
    border.width: 1

    readonly property bool hasMedia: (typeof mprisCtrl !== "undefined" && mprisCtrl) ? mprisCtrl.hasMedia : false
    readonly property bool isPlaying: (typeof mprisCtrl !== "undefined" && mprisCtrl) ? mprisCtrl.isPlaying : false
    readonly property string title: {
        if (typeof mprisCtrl !== "undefined" && mprisCtrl && mprisCtrl.title && mprisCtrl.title.length > 0)
            return mprisCtrl.title;
        return "Not Playing";
    }
    readonly property string artist: {
        if (typeof mprisCtrl !== "undefined" && mprisCtrl && mprisCtrl.artist && mprisCtrl.artist.length > 0 && mprisCtrl.artist !== "Unknown Artist")
            return mprisCtrl.artist;
        if (typeof mprisCtrl !== "undefined" && mprisCtrl && mprisCtrl.playerName && mprisCtrl.playerName.length > 0)
            return mprisCtrl.playerName;
        return "Music Player";
    }
    readonly property string artUrl: (typeof mprisCtrl !== "undefined" && mprisCtrl) ? mprisCtrl.artUrl : ""

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 8
        anchors.bottomMargin: 10
        spacing: 6

        // ── Card Header ─────────────────────────────────────────────────────
        Text {
            text: "Now Playing"
            font.family: TitanTheme.fontFamily
            font.pixelSize: 11
            font.weight: Font.Bold
            color: TitanTheme.textPrimary
        }

        // ── Body Row ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Vibrant Multi-Hue Aurora Album Art Square (52x52)
            Rectangle {
                width: 52
                height: 52
                radius: 10
                clip: true
                border.color: Qt.rgba(1, 1, 1, 0.22)
                border.width: 1

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#0EA5E9" }
                    GradientStop { position: 0.45; color: "#6366F1" }
                    GradientStop { position: 0.78; color: "#EC4899" }
                    GradientStop { position: 1.0; color: "#0F172A" }
                }

                // Inner diagonal shimmer accent
                Rectangle {
                    visible: !albumImg.visible
                    width: 36
                    height: 36
                    radius: 18
                    x: -6
                    y: 22
                    color: Qt.rgba(0.0, 0.95, 0.85, 0.35)
                }

                Text {
                    visible: !albumImg.visible
                    anchors.centerIn: parent
                    text: "\uf001" // music note
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 16
                    color: Qt.rgba(1, 1, 1, 0.90)
                }

                Image {
                    id: albumImg
                    anchors.fill: parent
                    source: mediaRoot.artUrl
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready && mediaRoot.artUrl.length > 0
                    asynchronous: true
                }
            }

            // Track Metadata + Transport Controls
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2

                Text {
                    text: mediaRoot.title
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
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

                Item { Layout.fillHeight: true }

                // Transport Controls Row (Prev, Play/Pause, Next)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Item { Layout.fillWidth: true }

                    // Previous Track
                    Text {
                        text: "\uf04a" // backward
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 12
                        color: prevMa.containsMouse ? "#FFFFFF" : TitanTheme.textSecondary
                        scale: prevMa.pressed ? 0.85 : 1.0
                        Behavior on scale { NumberAnimation { duration: 90 } }

                        MouseArea {
                            id: prevMa
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) return;
                                if (typeof mprisCtrl !== "undefined" && mprisCtrl)
                                    mprisCtrl.previous();
                            }
                        }
                    }

                    // Play / Pause
                    Text {
                        text: mediaRoot.isPlaying ? "\uf04c" : "\uf04b" // pause : play
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 14
                        color: "#FFFFFF"
                        scale: playMa.pressed ? 0.85 : 1.0
                        Behavior on scale { NumberAnimation { duration: 90 } }

                        MouseArea {
                            id: playMa
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) return;
                                if (typeof mprisCtrl !== "undefined" && mprisCtrl)
                                    mprisCtrl.playPause();
                            }
                        }
                    }

                    // Next Track
                    Text {
                        text: "\uf04e" // forward
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 12
                        color: nextMa.containsMouse ? "#FFFFFF" : TitanTheme.textSecondary
                        scale: nextMa.pressed ? 0.85 : 1.0
                        Behavior on scale { NumberAnimation { duration: 90 } }

                        MouseArea {
                            id: nextMa
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) return;
                                if (typeof mprisCtrl !== "undefined" && mprisCtrl)
                                    mprisCtrl.next();
                            }
                        }
                    }
                }
            }
        }
    }
}
