import QtQuick
import QtQuick.Layouts

/**
 * GlowingCard — Cinematic frosted sapphire glass card with interactive hover illumination.
 */
Rectangle {
    id: cardRoot
    radius: 16
    color: isHovered ? Qt.rgba(0.12, 0.16, 0.24, 0.88) : Qt.rgba(0.08, 0.11, 0.17, 0.78)
    border.color: isHovered ? Qt.rgba(0.05, 0.65, 1.0, 0.65) : Qt.rgba(1, 1, 1, 0.10)
    border.width: 1
    clip: true

    property bool interactive: true
    property alias isHovered: hoverArea.containsMouse
    property color glowColor: Qt.rgba(0.05, 0.65, 1.0, 0.15)

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    // Ambient radial backlight
    Rectangle {
        anchors.fill: parent
        radius: cardRoot.radius
        opacity: cardRoot.isHovered ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 250 } }
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: cardRoot.glowColor }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: cardRoot.interactive
        cursorShape: cardRoot.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}

