import QtQuick
import QtQuick.Shapes 1.15
import ArchTitan.Media 1.0
import ArchTitan.TitanUI

/**
 * TransportButton — Tactile, high-gloss media control button.
 * Renders pure white vector glyphs for Previous, Play/Pause, and Next,
 * with subtle hover aura and mechanical press scaling.
 */
Item {
    id: btnRoot

    property string type: "playpause" // "previous" | "playpause" | "next" | "custom"
    property bool isPlaying: Mpris ? Mpris.isPlaying : false
    property string iconText: ""
    property int iconSize: 12
    property int hitSize: 34

    signal activated()

    width: hitSize
    height: hitSize

    // Tactile press & hover scale
    scale: btnArea.pressed ? 0.86 : (btnArea.containsMouse ? 1.12 : 1.0)
    Behavior on scale {
        NumberAnimation {
            duration: btnArea.pressed ? 60 : 140
            easing.type: Easing.OutQuad
        }
    }

    // Hover glow circle behind the glyph
    Rectangle {
        id: hoverGlow
        anchors.centerIn: parent
        width: 32
        height: 32
        radius: 16
        color: btnArea.pressed ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.10)
        border.color: Qt.rgba(0.7, 0.6, 1.0, 0.3)
        border.width: 1
        opacity: btnArea.containsMouse ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }

    // ── PREVIOUS GLYPH: Double left triangle ─────────────────────────
    Item {
        id: prevGlyph
        visible: btnRoot.type === "previous"
        anchors.centerIn: parent
        width: 14
        height: 12

        Shape {
            anchors.fill: parent
            asynchronous: false
            ShapePath {
                fillColor: "#FFFFFF"
                strokeColor: "transparent"
                startX: 6; startY: 0
                PathLine { x: 0; y: 6 }
                PathLine { x: 6; y: 12 }
                PathLine { x: 6; y: 0 }
            }
            ShapePath {
                fillColor: "#FFFFFF"
                strokeColor: "transparent"
                startX: 14; startY: 0
                PathLine { x: 8; y: 6 }
                PathLine { x: 14; y: 12 }
                PathLine { x: 14; y: 0 }
            }
        }
    }

    // ── PLAY / PAUSE GLYPH ───────────────────────────────────────────
    Item {
        id: playPauseGlyph
        visible: btnRoot.type === "playpause"
        anchors.centerIn: parent
        width: 14
        height: 14

        // PAUSE: Two clean vertical rounded bars
        Row {
            anchors.centerIn: parent
            spacing: 3.5
            visible: btnRoot.isPlaying

            Rectangle {
                width: 3.5
                height: 14
                radius: 1.75
                color: "#FFFFFF"
            }
            Rectangle {
                width: 3.5
                height: 14
                radius: 1.75
                color: "#FFFFFF"
            }
        }

        // PLAY: Rightward triangle
        Shape {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 1
            width: 12
            height: 14
            visible: !btnRoot.isPlaying
            asynchronous: false

            ShapePath {
                fillColor: "#FFFFFF"
                strokeColor: "transparent"
                startX: 1; startY: 0
                PathLine { x: 12; y: 7 }
                PathLine { x: 1; y: 14 }
                PathLine { x: 1; y: 0 }
            }
        }
    }

    // ── NEXT GLYPH: Double right triangle ────────────────────────────
    Item {
        id: nextGlyph
        visible: btnRoot.type === "next"
        anchors.centerIn: parent
        width: 14
        height: 12

        Shape {
            anchors.fill: parent
            asynchronous: false
            ShapePath {
                fillColor: "#FFFFFF"
                strokeColor: "transparent"
                startX: 0; startY: 0
                PathLine { x: 6; y: 6 }
                PathLine { x: 0; y: 12 }
                PathLine { x: 0; y: 0 }
            }
            ShapePath {
                fillColor: "#FFFFFF"
                strokeColor: "transparent"
                startX: 8; startY: 0
                PathLine { x: 14; y: 6 }
                PathLine { x: 8; y: 12 }
                PathLine { x: 8; y: 0 }
            }
        }
    }

    // ── CUSTOM TEXT GLYPH (Fallback) ─────────────────────────────────
    Text {
        visible: btnRoot.type === "custom" || (btnRoot.type !== "previous" && btnRoot.type !== "playpause" && btnRoot.type !== "next")
        anchors.centerIn: parent
        text: btnRoot.iconText
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: btnRoot.iconSize
        font.weight: Font.Bold
        color: "#FFFFFF"
    }

    MouseArea {
        id: btnArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btnRoot.activated()
    }
}
