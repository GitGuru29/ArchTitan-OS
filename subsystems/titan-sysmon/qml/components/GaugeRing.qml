import QtQuick
import ArchTitan.TitanUI

/**
 * GaugeRing — GPU SceneGraph progress arc with a centred value and caption.
 *
 * Used for the three hero metrics (CPU / MEM / TEMP). Powered by native C++
 * TitanArcItem triangle strips running directly on the GPU with 0% CPU overhead
 * and 144Hz fluid motion interpolation.
 */
Item {
    id: root

    property real   value: 0.0                 // 0.0 .. 1.0
    property color  ringColor: TitanTheme.accent
    property color  trackColor: TitanTheme.alphaColor(root.ringColor, 0.20)
    property int    thickness: 7
    property string display: ""
    property string caption: ""
    property color  displayColor: TitanTheme.textHigh

    implicitWidth: 96
    implicitHeight: 96

    // ── Instrument backing disc with tinted ambient core ─────────────────
    Rectangle {
        id: backingDisc
        anchors.centerIn: parent
        width: parent.width - 2
        height: width
        radius: width / 2
        color: TitanTheme.alphaColor(TitanTheme.crust, 0.78)
        border.width: 1
        border.color: TitanTheme.alphaColor(root.ringColor, 0.22)

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.72
            height: width
            radius: width / 2
            color: TitanTheme.alphaColor(root.ringColor, 0.09)
        }
    }

    TitanArcItem {
        anchors.fill: parent
        color: root.ringColor
        trackColor: root.trackColor
        lineWidth: root.thickness
        startAngle: -90.0
        sweepAngle: 360.0 * Math.min(1.0, Math.max(0.0, root.value))
        showTrack: true
        roundCaps: true

        Behavior on sweepAngle {
            NumberAnimation {
                duration: TitanTheme.durSlow
                easing.type: TitanTheme.easingStandard
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: TitanTheme.durFast
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 1
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.display
            color: root.displayColor
            font.family: TitanTheme.fontFamily
            font.pixelSize: 20
            font.weight: TitanTheme.weightBold
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.caption
            color: TitanTheme.textLow
            font.family: TitanTheme.fontFamily
            font.pixelSize: 9
            font.weight: TitanTheme.weightMedium
            font.letterSpacing: 0.6
        }
    }
}
