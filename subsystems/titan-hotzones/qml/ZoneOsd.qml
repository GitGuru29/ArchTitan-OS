// titan-zone-osd — ArchTitan hot-zone on-screen display
//
// Supports: activation pill (zone), workspace toast (workspace), and a steady
// screen-edge frame that marks the workspace boundary for hot-zones.
import QtQuick
import QtQuick.Window

Window {
    id: root
    width: 1920
    height: 1080
    color: "transparent"
    flags: Qt.WindowTransparentForInput
    title: "Titan Zone OSD"
    visible: false

    property bool   active:   osd.active
    property string kind:     osd.kind
    property string zoneName: osd.zone
    property string label:    osd.label
    property string subtitle: osd.subtitle
    property string icon:     osd.icon
    property real   progress: osd.progress
    property bool   frame:    osd.frame

    readonly property color cSurface: "#F21E1E2E"
    readonly property color cBorder:  "#3D89B4FA"
    readonly property color cAccent:  "#89B4FA"
    readonly property color cTrack:   "#313244"
    readonly property color cText:    "#CDD6F4"
    readonly property color cSubtext: "#7F849C"

    // Workspace frame colors: ArchTitan blue -> violet gradient
    readonly property color cFrameA:  "#89B4FA"
    readonly property color cFrameB:  "#CBA6F7"
    readonly property color cGlow:    "#4089B4FA"

    readonly property int pillW: 236
    readonly property int pillH: 92
    readonly property int edge: 14
    readonly property int topInset: 58

    readonly property bool zoneArming: active && kind === "zone" && zoneName !== ""

    // ── Steady Workspace Border ─────────────────────────────────────────────
    // Clear, clean border marking the workspace hotcorners without blinking spots.
    // Brightens subtly with an inner glow when the user dwells near a hotzone.
    Item {
        id: frameLayer
        anchors.fill: parent
        readonly property int borderThick: 2
        readonly property int glowDist: 14

        opacity: root.frame ? (root.zoneArming ? 1.0 : 0.6) : 0.0
        visible: opacity > 0.001
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        // Subtle glow when dwelling / arming a hotzone
        Item {
            anchors.fill: parent
            opacity: root.zoneArming ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: frameLayer.glowDist
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.cGlow }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: frameLayer.glowDist
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: root.cGlow }
                }
            }
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: frameLayer.glowDist
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.cGlow }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
            Rectangle {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                width: frameLayer.glowDist
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: root.cGlow }
                }
            }
        }

        // Steady 4-edge border lines
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: frameLayer.borderThick
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: root.cFrameA }
                GradientStop { position: 1.0; color: root.cFrameB }
            }
        }
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: frameLayer.borderThick
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: root.cFrameB }
                GradientStop { position: 1.0; color: root.cFrameA }
            }
        }
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: frameLayer.borderThick
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.cFrameA }
                GradientStop { position: 1.0; color: root.cFrameB }
            }
        }
        Rectangle {
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: frameLayer.borderThick
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.cFrameB }
                GradientStop { position: 1.0; color: root.cFrameA }
            }
        }
    }

    // ── Zone Dwell / Workspace Toast Pill ───────────────────────────────────
    Item {
        id: content
        anchors.fill: parent
        opacity: root.active ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Rectangle {
            id: pill
            visible: root.zoneName !== "" || root.kind === "workspace"
            width: root.pillW
            height: root.pillH
            radius: 20
            color: root.cSurface
            border.width: 1
            border.color: root.cBorder
            opacity: root.active ? 1.0 : 0.0
            x: {
                if (root.zoneName === "top_left" || root.zoneName === "bottom_left" || root.zoneName === "left_center") return root.edge
                if (root.zoneName === "top_right" || root.zoneName === "bottom_right" || root.zoneName === "right_center") return root.width - width - root.edge
                return (root.width - width) / 2
            }
            y: {
                if (root.kind === "workspace") return (root.height - height) / 2
                if (root.zoneName === "top_left" || root.zoneName === "top_right") return root.topInset
                if (root.zoneName === "bottom_left" || root.zoneName === "bottom_right" || root.zoneName === "bottom_center") return root.height - height - root.edge
                return (root.height - height) / 2
            }
            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Row {
                anchors.centerIn: parent
                spacing: 14
                Item {
                    width: 56; height: 56; anchors.verticalCenter: parent.verticalCenter
                    Canvas {
                        id: ring
                        anchors.fill: parent
                        property real progress: root.progress
                        onProgressChanged: requestPaint()
                        onWidthChanged: requestPaint(); onHeightChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset()
                            var cx = width/2, cy = height/2, r = Math.min(cx,cy)-4
                            ctx.lineWidth = 4; ctx.lineCap = "round"
                            ctx.strokeStyle = root.cTrack
                            ctx.beginPath(); ctx.arc(cx,cy,r,0,2*Math.PI); ctx.stroke()
                            if (progress > 0.001) {
                                ctx.strokeStyle = root.cAccent
                                ctx.beginPath(); ctx.arc(cx,cy,r,-Math.PI/2,-Math.PI/2+2*Math.PI*progress); ctx.stroke()
                            }
                        }
                    }
                    Text { anchors.centerIn: parent; text: root.icon; color: root.cAccent; font.pixelSize: 24; font.bold: true }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text { text: root.label; color: root.cText; font.pixelSize: 16; font.bold: true; font.family: "Inter" }
                    Text { text: root.subtitle; color: root.cSubtext; font.pixelSize: 11; font.family: "Inter" }
                }
            }
        }
    }
}
