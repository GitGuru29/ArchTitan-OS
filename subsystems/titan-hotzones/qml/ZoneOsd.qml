// titan-zone-osd — ArchTitan hot-zone on-screen display
//
// A full-screen, input-transparent LayerShell overlay. The compositor keeps the
// surface mapped across the whole output and the pill inside it is placed next
// to whichever hot zone is active; animating inside the surface avoids relying
// on the compositor to reposition a layer surface after it has been mapped.
//
// Driven by `titan-hotzones` over a local socket. Colour values mirror
// ArchTitan.TitanUI's TitanTheme tokens and are inlined so the OSD has no
// install-path dependency on the QML module.
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

    // Bound to the OsdController context property.
    property bool   active:   osd.active
    property string kind:     osd.kind
    property string zoneName: osd.zone
    property string label:    osd.label
    property string subtitle: osd.subtitle
    property string icon:     osd.icon
    property real   progress: osd.progress

    // ── TDL tokens (mirror of ArchTitan.TitanUI) ──────────────────────────
    readonly property color cSurface: "#F21E1E2E"
    readonly property color cBorder:  "#3D89B4FA"
    readonly property color cAccent:  "#89B4FA"
    readonly property color cTrack:   "#313244"
    readonly property color cText:    "#CDD6F4"
    readonly property color cSubtext: "#7F849C"

    readonly property int pillW: 236
    readonly property int pillH: 92
    readonly property int edge: 14
    readonly property int topInset: 58 // clear of Waybar

    Item {
        id: content
        anchors.fill: parent
        opacity: root.active ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: pill
            width: root.pillW
            height: root.pillH
            radius: 20
            color: root.cSurface
            border.width: 1
            border.color: root.cBorder

            x: {
                if (root.zoneName === "top_left" || root.zoneName === "bottom_left" ||
                    root.zoneName === "left_center")
                    return root.edge;
                if (root.zoneName === "top_right" || root.zoneName === "bottom_right" ||
                    root.zoneName === "right_center")
                    return root.width - width - root.edge;
                return (root.width - width) / 2;
            }
            y: {
                if (root.kind === "workspace")
                    return (root.height - height) / 2;
                if (root.zoneName === "top_left" || root.zoneName === "top_right")
                    return root.topInset;
                if (root.zoneName === "bottom_left" || root.zoneName === "bottom_right" ||
                    root.zoneName === "bottom_center")
                    return root.height - height - root.edge;
                return (root.height - height) / 2;
            }
            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Row {
                anchors.centerIn: parent
                spacing: 14

                Item {
                    width: 56
                    height: 56
                    anchors.verticalCenter: parent.verticalCenter

                    Canvas {
                        id: ring
                        anchors.fill: parent
                        property real progress: root.progress
                        onProgressChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var cx = width / 2, cy = height / 2;
                            var r = Math.min(cx, cy) - 4;
                            ctx.lineWidth = 4;
                            ctx.lineCap = "round";

                            ctx.strokeStyle = root.cTrack;
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                            ctx.stroke();

                            if (progress > 0.001) {
                                ctx.strokeStyle = root.cAccent;
                                ctx.beginPath();
                                ctx.arc(cx, cy, r,
                                        -Math.PI / 2,
                                        -Math.PI / 2 + 2 * Math.PI * progress);
                                ctx.stroke();
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.icon
                        color: root.cAccent
                        font.pixelSize: 24
                        font.bold: true
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: root.label
                        color: root.cText
                        font.pixelSize: 16
                        font.bold: true
                        font.family: "Inter"
                    }

                    Text {
                        text: root.subtitle
                        color: root.cSubtext
                        font.pixelSize: 11
                        font.family: "Inter"
                    }
                }
            }
        }
    }
}
