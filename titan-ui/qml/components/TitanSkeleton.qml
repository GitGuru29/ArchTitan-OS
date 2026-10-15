import QtQuick
import ArchTitan.TitanUI

/* TitanSkeleton — shimmering placeholder block for loading content.
 * Compose several to mimic list rows, cards or text lines. */
Rectangle {
    id: root

    property bool shimmer: true

    implicitWidth: 120
    implicitHeight: 16
    radius: Math.min(TitanTheme.radiusSm, height / 2)
    color: TitanTheme.surface0
    clip: true

    Rectangle {
        id: sweep
        visible: root.shimmer
        width: root.width * 0.5
        height: root.height
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.08) }
            GradientStop { position: 1.0; color: "transparent" }
        }

        NumberAnimation on x {
            running: root.shimmer && root.visible
            from: -root.width * 0.5
            to: root.width
            duration: TitanTheme.durShimmer
            loops: Animation.Infinite
            easing.type: Easing.InOutSine
        }
    }
}
