import QtQuick

/**
 * SlideExit — outgoing slide content animation (180 ms, InCubic).
 * Horizontal displacement: 0 → -35px (or +35px when going back)
 * Opacity: 1 → 0
 */
ParallelAnimation {
    id: root

    property Item targetItem: null
    property real toX: -35
    property bool reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false
    property int durationMs: 180

    NumberAnimation {
        target: root.targetItem
        property: "opacity"
        from: 1.0
        to: 0.0
        duration: root.reducedMotion ? 40 : root.durationMs
        easing.type: Easing.InCubic
    }

    NumberAnimation {
        target: root.targetItem
        property: "x"
        from: 0
        to: root.reducedMotion ? 0 : root.toX
        duration: root.reducedMotion ? 40 : root.durationMs
        easing.type: Easing.InCubic
    }
}
