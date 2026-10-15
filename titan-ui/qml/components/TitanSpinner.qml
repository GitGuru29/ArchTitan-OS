import QtQuick
import ArchTitan.TitanUI

/* TitanSpinner — indeterminate circular loading indicator.
 * Rotates a 1.5π accent arc over a faint track. */
Item {
    id: root

    property color color: TitanTheme.accent
    property int size: 24
    property int lineWidth: 2
    property bool running: true

    implicitWidth: size
    implicitHeight: size

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var cx = width / 2
            var cy = height / 2
            var r = Math.min(width, height) / 2 - root.lineWidth / 2
            var start = -Math.PI / 2

            ctx.lineWidth = root.lineWidth

            // Faint track.
            ctx.beginPath()
            ctx.strokeStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.18)
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.stroke()

            // Active sweep.
            ctx.beginPath()
            ctx.strokeStyle = root.color
            ctx.lineCap = "round"
            ctx.arc(cx, cy, r, start, start + Math.PI * 1.5)
            ctx.stroke()
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: root
            function onColorChanged() { canvas.requestPaint() }
            function onLineWidthChanged() { canvas.requestPaint() }
        }
    }

    RotationAnimator on rotation {
        running: root.running && root.visible
        from: 0
        to: 360
        duration: 900
        loops: Animation.Infinite
    }
}
