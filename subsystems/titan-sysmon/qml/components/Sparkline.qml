import QtQuick

/**
 * Sparkline — filled trend line for a sequence of normalised (0..1) samples.
 *
 * `points` is replaced wholesale by SysmonController once per second, so the
 * change handler re-paints without any diffing. A soft gradient fills beneath
 * the stroke for a subtle "flow" effect against the glass.
 */
Canvas {
    id: root

    property var   points: []
    property color lineColor: "#89B4FA"
    property color fillTop: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.28)
    property color fillBottom: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.0)
    property real  strokeWidth: 1.6
    property real  minValue: 0.0
    property real  maxValue: 1.0

    antialiasing: true
    renderStrategy: Canvas.Cooperative

    onPointsChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onLineColorChanged: requestPaint()

    function yFor(v) {
        var lo = root.minValue;
        var hi = root.maxValue;
        var t = hi > lo ? (v - lo) / (hi - lo) : 0;
        t = Math.max(0, Math.min(1, t));
        return (root.height - 2) - t * (root.height - 4);
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        var n = root.points ? root.points.length : 0;
        if (n < 2)
            return;

        var padX = 1;
        var step = (root.width - padX * 2) / (n - 1);

        // Stroke path
        ctx.beginPath();
        for (var i = 0; i < n; ++i) {
            var x = padX + i * step;
            var y = yFor(root.points[i]);
            if (i === 0) ctx.moveTo(x, y);
            else         ctx.lineTo(x, y);
        }
        var strokePath = ctx;

        // Fill underneath
        ctx.save();
        ctx.lineTo(root.width - padX, root.height);
        ctx.lineTo(padX, root.height);
        ctx.closePath();
        var g = ctx.createLinearGradient(0, 0, 0, root.height);
        g.addColorStop(0, root.fillTop);
        g.addColorStop(1, root.fillBottom);
        ctx.fillStyle = g;
        ctx.fill();
        ctx.restore();

        // Re-trace for a clean stroke on top of the fill
        ctx.beginPath();
        for (var j = 0; j < n; ++j) {
            var xx = padX + j * step;
            var yy = yFor(root.points[j]);
            if (j === 0) ctx.moveTo(xx, yy);
            else         ctx.lineTo(xx, yy);
        }
        ctx.lineWidth = root.strokeWidth;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.strokeStyle = root.lineColor;
        ctx.stroke();
    }
}
