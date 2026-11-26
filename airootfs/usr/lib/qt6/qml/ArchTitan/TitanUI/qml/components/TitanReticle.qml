import QtQuick
import ArchTitan.TitanUI

/* TitanReticle — futuristic HUD reticle corner markers (┌ ┐ └ ┘).
 * Standardized focus frame for cards, viewports, and modal slices. */
Item {
    id: root

    property color color: TitanTheme.accent
    property int bracketLength: 14
    property int bracketThickness: 2
    property bool pulsing: false

    anchors.fill: parent

    opacity: pulsing ? pulseAnim.opacityVal : 1.0

    QtObject {
        id: pulseAnim
        property real opacityVal: 1.0
        SequentialAnimation on opacityVal {
            running: root.pulsing && root.visible
            loops: Animation.Infinite
            NumberAnimation { to: 0.45; duration: TitanTheme.durSlow * 3; easing.type: TitanTheme.easingStandard }
            NumberAnimation { to: 1.0; duration: TitanTheme.durSlow * 3; easing.type: TitanTheme.easingStandard }
        }
    }

    // Top-Left
    Rectangle {
        x: 0; y: 0; width: root.bracketLength; height: root.bracketThickness; color: root.color
    }
    Rectangle {
        x: 0; y: 0; width: root.bracketThickness; height: root.bracketLength; color: root.color
    }

    // Top-Right
    Rectangle {
        x: parent.width - root.bracketLength; y: 0; width: root.bracketLength; height: root.bracketThickness; color: root.color
    }
    Rectangle {
        x: parent.width - root.bracketThickness; y: 0; width: root.bracketThickness; height: root.bracketLength; color: root.color
    }

    // Bottom-Left
    Rectangle {
        x: 0; y: parent.height - root.bracketThickness; width: root.bracketLength; height: root.bracketThickness; color: root.color
    }
    Rectangle {
        x: 0; y: parent.height - root.bracketLength; width: root.bracketThickness; height: root.bracketLength; color: root.color
    }

    // Bottom-Right
    Rectangle {
        x: parent.width - root.bracketLength; y: parent.height - root.bracketThickness; width: root.bracketLength; height: root.bracketThickness; color: root.color
    }
    Rectangle {
        x: parent.width - root.bracketThickness; y: parent.height - root.bracketLength; width: root.bracketThickness; height: root.bracketLength; color: root.color
    }
}

