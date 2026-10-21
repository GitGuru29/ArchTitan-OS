import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: spireRoot
    width: 650
    height: 700

    property string ringMode: "music"    // "music", "rgb", "monochrome", "accent"
    property color customAccent: "#FFFFFF"
    property bool isMusicPlaying: false

    // ── TDL tokens — Catppuccin Mocha baseline (mirrors titan-ui's TitanTheme.qml)
    // SDDM is pre-login, so the shipped default palette is inlined here;
    // colour-lint keeps these on-palette with every other surface.
    readonly property color tdlAccent: "#89B4FA"
    property real audioPulse: 1.0

    // Internal rotation for RGB chromatic animation
    property real rgbAngle: 0.0

    NumberAnimation on rgbAngle {
        from: 0
        to: 360
        duration: 6000
        loops: Animation.Infinite
        running: spireRoot.effectiveIsRgb
    }

    // Whether RGB effect is currently active
    readonly property bool effectiveIsRgb: {
        if (ringMode === "rgb") return true
        if (ringMode === "music" && isMusicPlaying) return true
        return false
    }

    // Audio rhythm pulse animation when music is playing
    SequentialAnimation {
        running: spireRoot.effectiveIsRgb
        loops: Animation.Infinite
        NumberAnimation { target: spireRoot; property: "audioPulse"; to: 1.035; duration: 450; easing.type: Easing.OutSine }
        NumberAnimation { target: spireRoot; property: "audioPulse"; to: 0.995; duration: 350; easing.type: Easing.InOutSine }
        NumberAnimation { target: spireRoot; property: "audioPulse"; to: 1.020; duration: 400; easing.type: Easing.OutSine }
        NumberAnimation { target: spireRoot; property: "audioPulse"; to: 1.000; duration: 500; easing.type: Easing.InOutSine }
    }

    // Center coordinates of the ring
    readonly property real cx: width * 0.52
    readonly property real cy: height * 0.44
    readonly property real ringRadius: 215

    // ── 1. Diagonal Crosshair Laser Line (Behind everything) ───────────
    Canvas {
        id: diagonalLaser
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.save()

            // Diagonal line through center at ~35 degrees
            var angle = 36 * Math.PI / 180
            var cosA = Math.cos(angle)
            var sinA = Math.sin(angle)
            var len = 700

            ctx.beginPath()
            ctx.moveTo(spireRoot.cx - cosA * len, spireRoot.cy + sinA * len)
            ctx.lineTo(spireRoot.cx + cosA * len, spireRoot.cy - sinA * len)

            ctx.strokeStyle = "rgba(205, 214, 244, 0.45)"  // textHigh
            ctx.lineWidth = 1.2
            ctx.stroke()

            ctx.restore()
        }
    }

    // ── 2. Compass Dial & Ticks Canvas ────────────────────────────────
    Canvas {
        id: ticksCanvas
        anchors.fill: parent
        scale: spireRoot.audioPulse
        Behavior on scale { NumberAnimation { duration: 180 } }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.save()

            var r = spireRoot.ringRadius
            var cx = spireRoot.cx
            var cy = spireRoot.cy

            // Draw 72 radial tick marks around perimeter (every 5 degrees)
            for (var deg = 0; deg < 360; deg += 5) {
                var rad = deg * Math.PI / 180
                var cosVal = Math.cos(rad)
                var sinVal = Math.sin(rad)

                var isCardinal = (deg % 90 === 0)
                var isMajor = (deg % 30 === 0)

                var tickLen = isCardinal ? 14 : (isMajor ? 10 : 5)
                var innerR = r + 10
                var outerR = innerR + tickLen

                ctx.beginPath()
                ctx.moveTo(cx + cosVal * innerR, cy + sinVal * innerR)
                ctx.lineTo(cx + cosVal * outerR, cy + sinVal * outerR)

                if (isCardinal) {
                    ctx.strokeStyle = "rgba(255, 255, 255, 0.85)"
                    ctx.lineWidth = 1.8
                } else if (isMajor) {
                    ctx.strokeStyle = "rgba(205, 214, 244, 0.55)"  // textHigh
                    ctx.lineWidth = 1.2
                } else {
                    ctx.strokeStyle = "rgba(166, 173, 200, 0.35)"  // textMid
                    ctx.lineWidth = 0.9
                }
                ctx.stroke()
            }

            // Outer faint circular track
            ctx.beginPath()
            ctx.arc(cx, cy, r + 26, 0, 2 * Math.PI)
            ctx.strokeStyle = "rgba(255, 255, 255, 0.12)"
            ctx.lineWidth = 0.8
            ctx.stroke()

            ctx.restore()
        }
    }

    // ── 3. Glowing Circular Ring (Supports RGB Spectrum / Music) ───────
    Canvas {
        id: ringCanvas
        anchors.fill: parent
        scale: spireRoot.audioPulse
        Behavior on scale { NumberAnimation { duration: 180 } }

        Connections {
            target: spireRoot
            function onRgbAngleChanged() { ringCanvas.requestPaint() }
            function onRingModeChanged() { ringCanvas.requestPaint() }
            function onCustomAccentChanged() { ringCanvas.requestPaint() }
            function onEffectiveIsRgbChanged() { ringCanvas.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.save()

            var cx = spireRoot.cx
            var cy = spireRoot.cy
            var r = spireRoot.ringRadius

            ctx.lineCap = "round"
            ctx.lineWidth = 7.5

            if (spireRoot.effectiveIsRgb) {
                // Dynamic rotating RGB chromatic conic spectrum!
                var segments = 120
                var step = (2 * Math.PI) / segments
                var offsetRad = spireRoot.rgbAngle * Math.PI / 180

                for (var i = 0; i < segments; i++) {
                    var startA = i * step + offsetRad
                    var endA = (i + 1) * step + 0.03 + offsetRad
                    var hue = (i / segments) * 360

                    ctx.beginPath()
                    ctx.arc(cx, cy, r, startA, endA)
                    ctx.strokeStyle = "hsla(" + hue + ", 100%, 65%, 0.95)"
                    ctx.stroke()
                }

                // Inner and outer RGB soft glow
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                ctx.strokeStyle = "rgba(255, 255, 255, 0.4)"
                ctx.lineWidth = 2.0
                ctx.stroke()

            } else {
                // Monochrome or custom accent solid neon ring
                var colorStr = (spireRoot.ringMode === "accent") 
                                ? spireRoot.customAccent.toString() 
                                : "#FFFFFF"

                // Glow halo
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                ctx.strokeStyle = colorStr
                ctx.globalAlpha = 0.35
                ctx.lineWidth = 15.0
                ctx.stroke()

                // Sharp core ring
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                ctx.strokeStyle = colorStr
                ctx.globalAlpha = 0.98
                ctx.lineWidth = 6.5
                ctx.stroke()

                // Center laser highlight
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                ctx.strokeStyle = "#FFFFFF"
                ctx.globalAlpha = 0.8
                ctx.lineWidth = 1.5
                ctx.stroke()
            }

            ctx.restore()
        }
    }

    // ── 4. The 3D Stealth Faceted Monolithic Spire (Foreground) ───────
    Canvas {
        id: spireCanvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.save()

            var cx = spireRoot.cx
            var topY = spireRoot.cy - 275       // Peak of the obelisk
            var midY = spireRoot.cy - 120       // Shoulder transition
            var botY = height                   // Reaches bottom of screen

            // Facet 1: Far Left Outer Wing
            ctx.beginPath()
            ctx.moveTo(cx - 2, topY + 45)
            ctx.lineTo(cx - 48, midY)
            ctx.lineTo(cx - 56, botY)
            ctx.lineTo(cx - 26, botY)
            ctx.lineTo(cx - 22, midY + 10)
            ctx.closePath()
            var g1 = ctx.createLinearGradient(cx - 48, topY, cx, botY)
            g1.addColorStop(0.0, "#11111B")  // crust
            g1.addColorStop(0.5, "#181825")  // mantle
            g1.addColorStop(1.0, "#11111B")  // crust
            ctx.fillStyle = g1
            ctx.fill()

            // Facet 2: Left Main Slope (Deep Shadow)
            ctx.beginPath()
            ctx.moveTo(cx, topY)
            ctx.lineTo(cx - 2, topY + 45)
            ctx.lineTo(cx - 22, midY + 10)
            ctx.lineTo(cx - 26, botY)
            ctx.lineTo(cx - 8, botY)
            ctx.lineTo(cx - 7, midY + 30)
            ctx.lineTo(cx, topY + 90)
            ctx.closePath()
            var g2 = ctx.createLinearGradient(cx - 22, topY, cx, botY)
            g2.addColorStop(0.0, "#181825")  // mantle
            g2.addColorStop(0.4, "#1E1E2E")  // base
            g2.addColorStop(1.0, "#11111B")  // crust
            ctx.fillStyle = g2
            ctx.fill()

            // Facet 3: Center Recessed Trench / Spine (Black Obsidian)
            ctx.beginPath()
            ctx.moveTo(cx, topY + 90)
            ctx.lineTo(cx - 7, midY + 30)
            ctx.lineTo(cx - 8, botY)
            ctx.lineTo(cx + 8, botY)
            ctx.lineTo(cx + 7, midY + 30)
            ctx.closePath()
            var g3 = ctx.createLinearGradient(cx, topY, cx, botY)
            g3.addColorStop(0.0, "#11111B")  // crust
            g3.addColorStop(0.5, "#11111B")  // crust
            g3.addColorStop(1.0, "#11111B")  // crust
            ctx.fillStyle = g3
            ctx.fill()

            // Facet 4: Right Main Slope (Primary Illuminated Bevel)
            ctx.beginPath()
            ctx.moveTo(cx, topY)
            ctx.lineTo(cx + 2, topY + 45)
            ctx.lineTo(cx + 22, midY + 10)
            ctx.lineTo(cx + 26, botY)
            ctx.lineTo(cx + 8, botY)
            ctx.lineTo(cx + 7, midY + 30)
            ctx.lineTo(cx, topY + 90)
            ctx.closePath()
            var g4 = ctx.createLinearGradient(cx, topY, cx + 26, botY)
            g4.addColorStop(0.0, "#45475A")  // surface1
            g4.addColorStop(0.3, "#313244")  // surface0
            g4.addColorStop(0.7, "#1E1E2E")  // base
            g4.addColorStop(1.0, "#181825")  // mantle
            ctx.fillStyle = g4
            ctx.fill()

            // Facet 5: Far Right Outer Wing (Specular Highlight)
            ctx.beginPath()
            ctx.moveTo(cx + 2, topY + 45)
            ctx.lineTo(cx + 48, midY)
            ctx.lineTo(cx + 56, botY)
            ctx.lineTo(cx + 26, botY)
            ctx.lineTo(cx + 22, midY + 10)
            ctx.closePath()
            var g5 = ctx.createLinearGradient(cx + 22, topY, cx + 56, botY)
            g5.addColorStop(0.0, "#313244")  // surface0
            g5.addColorStop(0.5, "#1E1E2E")  // base
            g5.addColorStop(1.0, "#11111B")  // crust
            ctx.fillStyle = g5
            ctx.fill()

            // Crisp Bevel Edge Highlights
            ctx.beginPath()
            ctx.moveTo(cx, topY)
            ctx.lineTo(cx + 2, topY + 45)
            ctx.lineTo(cx + 22, midY + 10)
            ctx.lineTo(cx + 26, botY)
            ctx.strokeStyle = "rgba(255, 255, 255, 0.22)"
            ctx.lineWidth = 1.0
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(cx, topY)
            ctx.lineTo(cx, topY + 90)
            ctx.strokeStyle = "rgba(255, 255, 255, 0.35)"
            ctx.lineWidth = 1.2
            ctx.stroke()

            ctx.restore()
        }
    }

    // ── 5. Horizontal Horizon Glow Beam ──────────────────────────────
    Rectangle {
        id: horizonBeam
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 78
        height: 1.5
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.3; color: Qt.rgba(tdlAccent.r, tdlAccent.g, tdlAccent.b, 0.35) }
            GradientStop { position: 0.52; color: Qt.rgba(1, 1, 1, 0.85) }
            GradientStop { position: 0.75; color: Qt.rgba(tdlAccent.r, tdlAccent.g, tdlAccent.b, 0.35) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
}
