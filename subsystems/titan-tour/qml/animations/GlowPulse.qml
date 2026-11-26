import QtQuick

/**
 * GlowPulse — restrained breathing glow controller (never rotates continuously).
 * Pauses automatically when reducedMotion is enabled or the window is hidden.
 */
QtObject {
    id: root

    property bool active: true
    property bool reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false
    property real value: 0.5

    SequentialAnimation on value {
        running: root.active && !root.reducedMotion
        loops: Animation.Infinite
        NumberAnimation { from: 0.25; to: 1.0; duration: 2400; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1.0; to: 0.25; duration: 2400; easing.type: Easing.InOutSine }
    }
}
