import QtQuick
import ArchTitan.Media 1.0
import ArchTitan.TitanUI

/**
 * AlbumArt — Rounded squircle album artwork with smooth crossfade,
 * breathing ambient glow when playing, and sleek obsidian fallback.
 */
Item {
    id: artRoot

    property int artSize: 50
    property int cornerRadius: 13
    property bool showGlow: true

    width: artSize
    height: artSize

    // ── AMBIENT NEON GLOW (behind art when playing) ──────────────────────
    Rectangle {
        id: ambientGlow
        anchors.centerIn: parent
        width: artRoot.artSize + 8
        height: artRoot.artSize + 8
        radius: artRoot.cornerRadius + 4
        color: "transparent"
        border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.45) // Accent aura
        border.width: 2
        visible: artRoot.showGlow && (Mpris && Mpris.isPlaying)
        opacity: 0.4

        SequentialAnimation on opacity {
            running: artRoot.showGlow && (Mpris && Mpris.isPlaying)
            loops: Animation.Infinite
            NumberAnimation { from: 0.3; to: 0.85; duration: 1400; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 0.85; to: 0.3; duration: 1400; easing.type: Easing.InOutQuad }
        }
    }

    // ── CLIPPED ART CONTAINER ────────────────────────────────────────────
    Rectangle {
        id: artContainer
        anchors.fill: parent
        radius: artRoot.cornerRadius
        clip: true
        color: "#181926"
        border.color: (Mpris && Mpris.isPlaying) ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.35) : "#20FFFFFF"
        border.width: 1

        // ── FALLBACK (sleek dark gradient + music icon) ──────────────────
        Rectangle {
            id: fallback
            anchors.fill: parent
            radius: artRoot.cornerRadius
            visible: !currentArt.visible || currentArt.status !== Image.Ready

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#28293D" }
                GradientStop { position: 0.6; color: "#181926" }
                GradientStop { position: 1.0; color: "#10111A" }
            }

            Text {
                anchors.centerIn: parent
                text: "♫"
                font.pixelSize: Math.max(16, Math.round(artRoot.artSize * 0.4))
                color: (Mpris && Mpris.isPlaying) ? TitanTheme.accent : "#7C7F93"
                opacity: 0.9

                SequentialAnimation on scale {
                    running: fallback.visible && (Mpris && Mpris.isPlaying)
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.12; duration: 900; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.12; to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
                }
            }
        }

        // ── OUTGOING ART (for crossfade) ─────────────────────────────────
        Image {
            id: outgoingArt
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            mipmap: true
            visible: opacity > 0.01
            opacity: 0.0
            smooth: true
        }

        // ── CURRENT ART ──────────────────────────────────────────────────
        Image {
            id: currentArt
            anchors.fill: parent
            source: Mpris ? Mpris.artUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            mipmap: true
            visible: status === Image.Ready
            smooth: true

            onSourceChanged: {
                if (outgoingArt.source.toString().length > 0) {
                    outgoingArt.source = currentArt.source
                    outgoingArt.opacity = 1.0
                    crossfadeOut.start()
                }
            }

            NumberAnimation {
                id: crossfadeOut
                target: outgoingArt
                property: "opacity"
                from: 1.0; to: 0.0
                duration: 250
                easing.type: Easing.OutQuad
            }
        }

        // ── INNER TOP SPECULAR HIGHLIGHT ─────────────────────────────────
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: "#30FFFFFF"
        }
    }
}
