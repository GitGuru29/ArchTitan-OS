import QtQuick
import ArchTitan.TitanUI

/* TitanSpinner — indeterminate circular loading indicator.
 * Rotates a GPU-accelerated TitanArcItem triangle strip via RotationAnimator. */
Item {
    id: root

    property color color: TitanTheme.accent
    property color trackColor: TitanTheme.accentSoft
    property int size: 24
    property int lineWidth: 2
    property bool running: true

    implicitWidth: size
    implicitHeight: size

    TitanArcItem {
        anchors.fill: parent
        color: root.color
        trackColor: root.trackColor
        lineWidth: root.lineWidth
        startAngle: -90
        sweepAngle: 270
        showTrack: true
    }

    RotationAnimator on rotation {
        running: root.running && root.visible
        from: 0
        to: 360
        duration: 900
        loops: Animation.Infinite
    }
}
