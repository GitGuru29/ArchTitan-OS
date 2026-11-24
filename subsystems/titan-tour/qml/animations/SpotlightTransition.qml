import QtQuick

/**
 * SpotlightTransition — spring-like interpolation for the live spotlight cutout
 * and floating coach capsule repositioning.
 */
ParallelAnimation {
    id: root

    property Item targetItem: null
    property bool reducedMotion: false
    property real toX: 0
    property real toY: 0
    property real toWidth: 300
    property real toHeight: 200
    property int durationMs: 280

    NumberAnimation {
        target: root.targetItem
        property: "x"
        to: root.toX
        duration: root.reducedMotion ? 60 : root.durationMs
        easing.type: Easing.OutBack
        easing.overshoot: 0.65
    }

    NumberAnimation {
        target: root.targetItem
        property: "y"
        to: root.toY
        duration: root.reducedMotion ? 60 : root.durationMs
        easing.type: Easing.OutBack
        easing.overshoot: 0.65
    }

    NumberAnimation {
        target: root.targetItem
        property: "width"
        to: root.toWidth
        duration: root.reducedMotion ? 60 : root.durationMs
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        target: root.targetItem
        property: "height"
        to: root.toHeight
        duration: root.reducedMotion ? 60 : root.durationMs
        easing.type: Easing.OutCubic
    }
}

