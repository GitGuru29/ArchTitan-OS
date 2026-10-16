import QtQuick
import ArchTitan.TitanUI

/**
 * GaugeRing — circular progress arc with a centred value and caption.
 *
 * Used for the three hero metrics (CPU / MEM / TEMP). The arc is painted with a
 * Canvas so there is no shader/dependency cost and it stays crisp at any size.
 */
Item {
    id: root

    property real   value: 0.0                 // 0.0 .. 1.0
    property color  ringColor: TitanTheme.accent
    property color  trackColor: TitanTheme.bgInset
    property int    thickness: 7
    property string display: ""
    property string caption: ""
    property color  displayColor: TitanTheme.textHigh

    implicitWidth: 96
    implicitHeight: 96

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var lw = root.thickness;
            var cx = width / 2;
            var cy = height / 2;
            var r = Math.min(cx, cy) - lw / 2 - 1;
            ctx.lineWidth = lw;
            ctx.lineCap = "round";

            ctx.strokeStyle = root.trackColor;
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.stroke();

            if (root.value > 0.001) {
                ctx.strokeStyle = root.ringColor;
                ctx.beginPath();
                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.min(1, root.value));
                ctx.stroke();
            }
        }
    }

    onValueChanged: canvas.requestPaint()
    Connections {
        target: root
        function onRingColorChanged() { canvas.requestPaint(); }
        function onTrackColorChanged() { canvas.requestPaint(); }
        function onThicknessChanged() { canvas.requestPaint(); }
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
