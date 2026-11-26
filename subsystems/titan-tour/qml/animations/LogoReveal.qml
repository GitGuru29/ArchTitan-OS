import QtQuick

/**
 * LogoReveal — 900 ms entrance + cyan light sweep for the 3D Titan emblem.
 */
ParallelAnimation {
    id: root

    property Item targetItem: null
    property bool reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false

    NumberAnimation {
        target: root.targetItem
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: root.reducedMotion ? 60 : 900
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        target: root.targetItem
        property: "scale"
        from: root.reducedMotion ? 1.0 : 0.88
        to: 1.0
        duration: root.reducedMotion ? 60 : 900
        easing.type: Easing.OutCubic
    }
}
