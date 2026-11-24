import QtQuick

/**
 * SlideEnter — incoming slide content animation (420 ms, OutCubic).
 * Horizontal displacement: +35px → 0 (or -35px → 0 when navigating backward)
 * Opacity: 0 → 1
 * Scale: 0.985 → 1.0
 */
ParallelAnimation {
    id: root

    property Item targetItem: null
    property real fromX: 35
    property bool reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false
    property int durationMs: 420

    NumberAnimation {
        target: root.targetItem
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: root.reducedMotion ? 60 : root.durationMs
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        target: root.targetItem
        property: "x"
        from: root.reducedMotion ? 0 : root.fromX
        to: 0
        duration: root.reducedMotion ? 60 : root.durationMs
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        target: root.targetItem
        property: "scale"
        from: root.reducedMotion ? 1.0 : 0.985
        to: 1.0
        duration: root.reducedMotion ? 60 : root.durationMs
        easing.type: Easing.OutCubic
    }
}
