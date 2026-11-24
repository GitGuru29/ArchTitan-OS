import QtQuick

/**
 * StaggerReveal — reusable staggered reveal progress timer (0.0 → 1.0 over 550 ms)
 * so individual child items on a slide can reveal sequentially via itemIndex.
 */
Item {
    id: root

    property real progress: 1.0
    property int durationMs: 550
    property bool reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false

    function trigger() {
        if (reducedMotion) {
            progress = 1.0;
            return;
        }
        progress = 0.0;
        anim.restart();
    }

    function itemFactor(index, count) {
        if (reducedMotion || count <= 1) return 1.0;
        var start = (index / count) * 0.55;
        var span = 0.45;
        return Math.max(0.0, Math.min(1.0, (progress - start) / span));
    }

    NumberAnimation {
        id: anim
        target: root
        property: "progress"
        from: 0.0
        to: 1.0
        duration: root.durationMs
        easing.type: Easing.OutCubic
    }
}
