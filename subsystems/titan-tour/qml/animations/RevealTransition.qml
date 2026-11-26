import QtQuick

/**
 * RevealTransition — horizontal cinematic scene transition with subtle depth.
 * Respects reducedMotion preference automatically.
 */
ParallelAnimation {
    id: root

    property Item targetItem: null
    property bool reducedMotion: false
    property real fromOffset: 28
    property int durationMs: 320

    NumberAnimation {
        target: root.targetItem
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: root.reducedMotion ? 80 : root.durationMs
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        target: root.targetItem
        property: "x"
        from: root.reducedMotion ? 0 : root.fromOffset
        to: 0
        duration: root.reducedMotion ? 80 : root.durationMs
        easing.type: Easing.OutQuart
    }

    NumberAnimation {
        target: root.targetItem
        property: "scale"
        from: root.reducedMotion ? 1.0 : 0.985
        to: 1.0
        duration: root.reducedMotion ? 80 : root.durationMs
        easing.type: Easing.OutCubic
    }
}

