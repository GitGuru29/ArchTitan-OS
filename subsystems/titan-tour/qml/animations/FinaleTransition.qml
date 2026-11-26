import QtQuick

/**
 * FinaleTransition — 1200 ms Rise, Titan finale transition when entering
 * the desktop or revealing the Completion screen's cyan light sweep.
 */
SequentialAnimation {
    id: root

    property Item targetItem: null
    property bool reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false
    signal finishedFade()

    NumberAnimation {
        target: root.targetItem
        property: "opacity"
        from: 1.0
        to: 0.0
        duration: root.reducedMotion ? 80 : 480
        easing.type: Easing.InOutCubic
    }

    ScriptAction {
        script: root.finishedFade()
    }
}
