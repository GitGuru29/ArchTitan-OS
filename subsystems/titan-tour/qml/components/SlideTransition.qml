import QtQuick
import "../animations"

/**
 * SlideTransition — coordinates horizontal cinematic movement (+35px → 0 enter
 * in 420ms OutCubic, 0 → -35px exit in 180ms InCubic, scale 0.985 → 1.0).
 */
Item {
    id: root

    property Item targetItem: null
    property bool forward: true
    property bool reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false

    function trigger(isForward) {
        forward = (isForward === undefined) ? true : isForward;
        if (!targetItem) return;
        enterAnim.fromX = forward ? 35 : -35;
        enterAnim.restart();
    }

    SlideEnter {
        id: enterAnim
        targetItem: root.targetItem
        reducedMotion: root.reducedMotion
        fromX: root.forward ? 35 : -35
        durationMs: 420
    }
}
