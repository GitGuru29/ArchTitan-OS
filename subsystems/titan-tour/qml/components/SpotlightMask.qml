import QtQuick
import QtQuick.Shapes

/**
 * SpotlightMask — dims the desktop background while punching a rounded-rectangle
 * spotlight aperture around the highlighted live feature or desktop region,
 * framed with a laser-cyan ring and subtle radial aura.
 */
Item {
    id: root

    property bool active: false
    property rect targetRect: Qt.rect(360, 140, 560, 360)
    property int cornerRadius: 20
    property real dimOpacity: 0.72
    property bool reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false

    // Smoothly interpolated cutout coordinates
    property real holeX: targetRect.x
    property real holeY: targetRect.y
    property real holeW: Math.max(48, targetRect.width)
    property real holeH: Math.max(36, targetRect.height)

    Behavior on holeX {
        NumberAnimation { duration: root.reducedMotion ? 50 : 280; easing.type: Easing.OutCubic }
    }
    Behavior on holeY {
        NumberAnimation { duration: root.reducedMotion ? 50 : 280; easing.type: Easing.OutCubic }
    }
    Behavior on holeW {
        NumberAnimation { duration: root.reducedMotion ? 50 : 280; easing.type: Easing.OutCubic }
    }
    Behavior on holeH {
        NumberAnimation { duration: root.reducedMotion ? 50 : 280; easing.type: Easing.OutCubic }
    }

    opacity: active ? 1.0 : 0.0
    visible: opacity > 0.01
    Behavior on opacity {
        NumberAnimation { duration: root.reducedMotion ? 60 : 240; easing.type: Easing.OutCubic }
    }

    // Odd-even dim mask with transparent cutout
    Shape {
        anchors.fill: parent

        ShapePath {
            fillRule: ShapePath.OddEvenFill
            fillColor: Qt.rgba(0.067, 0.067, 0.106, root.dimOpacity) // #11111B
            strokeColor: "transparent"

            PathRectangle {
                x: 0
                y: 0
                width: root.width
                height: root.height
            }

            PathRectangle {
                x: root.holeX
                y: root.holeY
                width: root.holeW
                height: root.holeH
                radius: root.cornerRadius
            }
        }
    }

    // Outer ambient cyan aura ring around the cutout
    Rectangle {
        x: root.holeX - 6
        y: root.holeY - 6
        width: root.holeW + 12
        height: root.holeH + 12
        radius: root.cornerRadius + 5
        color: "transparent"
        border.width: 2
        border.color: "#4400D2FF"
    }

    // Crisp laser-cyan spotlight frame
    Rectangle {
        id: frameBox
        x: root.holeX
        y: root.holeY
        width: root.holeW
        height: root.holeH
        radius: root.cornerRadius
        color: "transparent"
        border.width: 2
        border.color: "#00D2FF"

        // Top-left corner accent bracket
        Rectangle {
            x: -2; y: -2; width: 22; height: 3; radius: 1.5; color: "#00D2FF"
        }
        Rectangle {
            x: -2; y: -2; width: 3; height: 22; radius: 1.5; color: "#00D2FF"
        }

        // Top-right corner accent bracket
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: -2
            y: -2; width: 22; height: 3; radius: 1.5; color: "#00D2FF"
        }
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: -2
            y: -2; width: 3; height: 22; radius: 1.5; color: "#00D2FF"
        }

        // Bottom-left corner accent bracket
        Rectangle {
            x: -2
            anchors.bottom: parent.bottom; anchors.bottomMargin: -2
            width: 22; height: 3; radius: 1.5; color: "#00D2FF"
        }
        Rectangle {
            x: -2
            anchors.bottom: parent.bottom; anchors.bottomMargin: -2
            width: 3; height: 22; radius: 1.5; color: "#00D2FF"
        }

        // Bottom-right corner accent bracket
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: -2
            anchors.bottom: parent.bottom; anchors.bottomMargin: -2
            width: 22; height: 3; radius: 1.5; color: "#00D2FF"
        }
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: -2
            anchors.bottom: parent.bottom; anchors.bottomMargin: -2
            width: 3; height: 22; radius: 1.5; color: "#00D2FF"
        }
    }
}

