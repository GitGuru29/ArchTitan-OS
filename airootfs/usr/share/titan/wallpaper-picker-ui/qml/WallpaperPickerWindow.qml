import QtQuick
import QtQuick.Window
import QtQuick.Shapes
import ArchTitan.TitanUI

/**
 * WallpaperPickerWindow — Pure Cyberpunk Wallpaper Carousel
 *
 * A modern, textless, distraction-free wallpaper browser for ArchTitan / Hyprland.
 *
 * Features:
 * - Wallpaper carousel takes center stage with a fluid 3D parabolic ribbon.
 * - Active center slice is sharply focused with an electric cyan HUD reticle
 *   and translucent inner wireframe of tiling application windows.
 * - Zero bottom clutter: click the active slice or press Enter/Space to apply.
 * - Pure visual UI elements only — strictly zero visible text, numbers, or labels.
 */
Window {
    id: root

    width: Screen.width > 0 ? Screen.width : 1920
    height: Screen.height > 0 ? Screen.height : 1080
    visible: true
    visibility: Window.FullScreen
    color: "transparent"
    flags: Qt.FramelessWindowHint
    title: "titan-wallpaper-picker"

    // ── State ────────────────────────────────────────────────────────────────
    property var wallpapers: []
    property string selectedPath: ""
    property string scaleMode: "fill"
    property string currentPath: (typeof WallpaperBackend !== "undefined" && WallpaperBackend && WallpaperBackend.currentPath)
                                ? WallpaperBackend.currentPath : ""
    property bool rebuilding: false

    readonly property real ribbonHeight: Math.min(root.height * 0.62, 640)

    readonly property var systemFallbacks: [
        "/usr/share/backgrounds/archtitan/wallpaper.png",
        "/usr/share/backgrounds/archtitan/1-matte-black.jpg",
        "/usr/share/backgrounds/archtitan/1-nord.png",
        "/usr/share/backgrounds/archtitan/watchtower-mountains-and-forests.jpg",
        "/usr/share/backgrounds/archtitan/titan-tokyonight.jpg",
        "/usr/share/backgrounds/archtitan/titan-mocha.jpg",
        "/usr/share/backgrounds/archtitan/titan-dracula.jpg",
        "/usr/share/backgrounds/archtitan/titan-gruvbox.jpg",
        "/usr/share/backgrounds/archtitan/titan-everforest.jpg",
        "/usr/share/backgrounds/archtitan/titan-kanagawa.jpg",
        "/usr/share/backgrounds/archtitan/titan-rosepine.jpg",
        "/usr/share/backgrounds/archtitan/titan-latte.jpg",
        "/usr/share/backgrounds/archtitan/titan-custom.jpg",
        "/usr/share/backgrounds/archtitan/titan-blue.jpg",
        "/usr/share/backgrounds/archtitan/titan-green.jpg",
        "/usr/share/backgrounds/archtitan/titan-lavender.jpg",
        "/usr/share/backgrounds/archtitan/titan-mauve.jpg",
        "/usr/share/backgrounds/archtitan/titan-peach.jpg",
        "/usr/share/backgrounds/archtitan/titan-pink.jpg",
        "/usr/share/backgrounds/archtitan/titan-teal.jpg"
    ]

    // ── Helpers ──────────────────────────────────────────────────────────────
    function glow(color, alpha) {
        if (!color) return Qt.rgba(0, 0, 0, alpha)
        var c = (color.r !== undefined) ? color : Qt.color(color)
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }

    function baseName(path) {
        var name = String(path || "").split("/").pop() || String(path || "")
        name = name.replace(/\.[^/.]+$/, "")
        return name.replace(/[-_]+/g, " ").trim()
    }

    function rebuildModel() {
        var source = (typeof WallpaperLibrary !== "undefined" && WallpaperLibrary && WallpaperLibrary.paths)
                   ? WallpaperLibrary.paths : []
        if (!source || source.length === 0) source = root.systemFallbacks

        var out = []
        for (var i = 0; i < source.length; i++) {
            var path = String(source[i])
            out.push({
                path: path,
                name: root.baseName(path)
            })
        }

        out.sort(function (a, b) {
            return a.name.localeCompare(b.name)
        })

        root.rebuilding = true
        root.wallpapers = out

        var targetIndex = -1
        for (var j = 0; j < out.length; j++) {
            if (out[j].path === root.selectedPath) {
                targetIndex = j
                break
            }
        }
        if (targetIndex < 0) {
            targetIndex = out.length > 0 ? 0 : -1
            root.selectedPath = targetIndex >= 0 ? out[targetIndex].path : ""
        }

        if (ribbon.currentIndex !== targetIndex) {
            ribbon.currentIndex = targetIndex
        }
        root.rebuilding = false
    }

    function selectIndex(index) {
        if (index < 0 || index >= root.wallpapers.length) return
        if (ribbon.currentIndex !== index) {
            ribbon.currentIndex = index
        }
        root.selectedPath = root.wallpapers[index].path
    }

    function step(delta) {
        if (root.wallpapers.length === 0) return
        var count = root.wallpapers.length
        var next = (ribbon.currentIndex + delta + count) % count
        root.selectIndex(next)
    }

    function applySelected() {
        if (root.selectedPath.length === 0) return
        if (typeof WallpaperBackend !== "undefined" && WallpaperBackend && WallpaperBackend.apply) {
            WallpaperBackend.apply(root.selectedPath, root.scaleMode, false)
        }
        Qt.quit()
    }

    function cancel() {
        if (typeof WallpaperBackend !== "undefined" && WallpaperBackend && WallpaperBackend.revertPreview) {
            WallpaperBackend.revertPreview()
        }
        Qt.quit()
    }

    Component.onCompleted: {
        if (typeof WallpaperBackend !== "undefined" && WallpaperBackend && WallpaperBackend.currentMode) {
            root.scaleMode = WallpaperBackend.currentMode
        }
        if (typeof WallpaperLibrary !== "undefined" && WallpaperLibrary && WallpaperLibrary.current) {
            root.selectedPath = WallpaperLibrary.current
        }
        root.rebuildModel()
        Qt.callLater(function () {
            ribbon.forceActiveFocus()
        })
    }

    Connections {
        target: (typeof WallpaperLibrary !== "undefined" && WallpaperLibrary) ? WallpaperLibrary : null
        function onPathsChanged() { root.rebuildModel() }
        function onCurrentChanged() {
            if (typeof WallpaperLibrary !== "undefined" && WallpaperLibrary) {
                root.currentPath = WallpaperLibrary.current
            }
        }
    }

    Connections {
        target: (typeof WallpaperBackend !== "undefined" && WallpaperBackend) ? WallpaperBackend : null
        function onCurrentModeChanged() {
            if (typeof WallpaperBackend !== "undefined" && WallpaperBackend && WallpaperBackend.currentMode) {
                root.scaleMode = WallpaperBackend.currentMode
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.cancel()
    }

    Shortcut {
        sequence: "Return"
        onActivated: root.applySelected()
    }

    Shortcut {
        sequence: "Enter"
        onActivated: root.applySelected()
    }

    Shortcut {
        sequence: "Space"
        onActivated: root.applySelected()
    }

    // ── Background Atmosphere & Lighting ────────────────────────────────────
    Image {
        id: bgBackdrop
        anchors.fill: parent
        source: root.selectedPath.length > 0 ? ("file://" + root.selectedPath) : (root.currentPath.length > 0 ? ("file://" + root.currentPath) : "")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        opacity: 0.28
        visible: status === Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        color: root.glow(TitanTheme.crust, 0.70)
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0;  color: root.glow(TitanTheme.crust, 0.92) }
            GradientStop { position: 0.35; color: root.glow(TitanTheme.crust, 0.38) }
            GradientStop { position: 0.70; color: root.glow(TitanTheme.crust, 0.58) }
            GradientStop { position: 1.0;  color: root.glow(TitanTheme.crust, 0.95) }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.cancel()
    }

    // ── Hero Wallpaper Carousel (Centered) ───────────────────────────────────
    PathView {
        id: ribbon

        anchors.centerIn: parent
        width: root.width
        height: root.ribbonHeight
        clip: false
        focus: true
        interactive: true
        model: root.wallpapers
        pathItemCount: Math.min(9, Math.max(1, root.wallpapers.length))
        currentIndex: -1
        snapMode: PathView.SnapToItem
        highlightRangeMode: PathView.StrictlyEnforceRange
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightMoveDuration: TitanTheme.durSlow
        flickDeceleration: 950
        maximumFlickVelocity: 2000

        onCurrentIndexChanged: {
            if (root.rebuilding) return
            if (currentIndex >= 0 && currentIndex < root.wallpapers.length) {
                root.selectedPath = root.wallpapers[currentIndex].path
            }
        }

        Keys.onLeftPressed: root.step(-1)
        Keys.onRightPressed: root.step(1)
        Keys.onUpPressed: root.step(-1)
        Keys.onDownPressed: root.step(1)
        Keys.onReturnPressed: root.applySelected()
        Keys.onEnterPressed: root.applySelected()
        Keys.onSpacePressed: root.applySelected()
        Keys.onEscapePressed: root.cancel()

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse
            onWheel: function (event) {
                if (event.angleDelta.y !== 0) {
                    root.step(event.angleDelta.y > 0 ? -1 : 1)
                    event.accepted = true
                }
            }
        }

        // Parabolic curved canopy
        path: Path {
            startX: -root.width * 0.22
            startY: root.ribbonHeight * 0.72

            PathAttribute { name: "sliceScale";    value: 0.65 }
            PathAttribute { name: "sliceOpacity";  value: 0.40 }
            PathAttribute { name: "sliceRotation"; value: -7 }
            PathAttribute { name: "sliceFocus";    value: 1 }

            PathQuad {
                x: root.width * 0.50
                y: root.ribbonHeight * 0.30
                controlX: root.width * 0.18
                controlY: root.ribbonHeight * 0.30
            }

            PathAttribute { name: "sliceScale";    value: 1.0 }
            PathAttribute { name: "sliceOpacity";  value: 1.0 }
            PathAttribute { name: "sliceRotation"; value: 0 }
            PathAttribute { name: "sliceFocus";    value: 12 }

            PathQuad {
                x: root.width * 1.22
                y: root.ribbonHeight * 0.72
                controlX: root.width * 0.82
                controlY: root.ribbonHeight * 0.30
            }

            PathAttribute { name: "sliceScale";    value: 0.65 }
            PathAttribute { name: "sliceOpacity";  value: 0.40 }
            PathAttribute { name: "sliceRotation"; value: 7 }
            PathAttribute { name: "sliceFocus";    value: 1 }
        }

        delegate: Item {
            id: slice

            readonly property var entry: modelData
            readonly property bool focusedSlice: index === ribbon.currentIndex
            readonly property bool currentWallpaper: entry && root.currentPath === entry.path
            readonly property bool hovered: sliceArea.containsMouse

            width: Math.min(540, root.width * 0.38)
            height: width * 0.625
            scale: (PathView.sliceScale !== undefined) ? PathView.sliceScale : 1.0
            opacity: (PathView.sliceOpacity !== undefined) ? PathView.sliceOpacity : 1.0
            rotation: (PathView.sliceRotation !== undefined) ? PathView.sliceRotation : 0
            z: (PathView.sliceFocus !== undefined) ? PathView.sliceFocus : 0

            Accessible.role: Accessible.Button
            Accessible.name: entry ? entry.name : ""

            // Outer cyan aura bloom for focused slice
            Rectangle {
                anchors.fill: parent
                anchors.margins: -10
                radius: 26
                color: "transparent"
                border.width: slice.focusedSlice ? 16 : 0
                border.color: root.glow(TitanTheme.accent, slice.focusedSlice ? 0.14 : 0.0)
            }

            // Glassmorphic thumbnail card
            Rectangle {
                id: glass
                anchors.fill: parent
                radius: 18
                color: slice.focusedSlice
                       ? root.glow(TitanTheme.surface0, 0.85)
                       : root.glow(TitanTheme.surface0, 0.45)
                border.width: slice.focusedSlice ? 1.8 : 1
                border.color: slice.focusedSlice
                              ? root.glow(TitanTheme.accent, 0.95)
                              : (slice.hovered ? TitanTheme.borderHover : TitanTheme.borderSubtle)

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 15
                    color: TitanTheme.surface0
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: slice.entry ? "image://thumbs/" + slice.entry.path : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        mipmap: true
                        sourceSize.width: slice.focusedSlice ? 1080 : 400
                        sourceSize.height: slice.focusedSlice ? 675 : 250
                    }

                    // Glass sheen overlay
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0;  color: root.glow(TitanTheme.crust, 0.10) }
                            GradientStop { position: 0.50; color: "transparent" }
                            GradientStop { position: 1.0;  color: root.glow(TitanTheme.crust, 0.82) }
                        }
                    }

                    // ── Translucent inner wireframe of tiling application windows ──
                    Item {
                        anchors.fill: parent
                        anchors.margins: 14
                        visible: slice.focusedSlice
                        opacity: 0.85

                        // Master window (Left pane)
                        Rectangle {
                            x: 0
                            y: 0
                            width: parent.width * 0.57
                            height: parent.height
                            radius: 6
                            color: root.glow(TitanTheme.accent, 0.045)
                            border.width: 1.2
                            border.color: root.glow(TitanTheme.accent, 0.55)

                            // Titlebar
                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 18
                                radius: 5
                                color: root.glow(TitanTheme.crust, 0.65)

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Rectangle { width: 4.5; height: 4.5; radius: 2.5; color: "#ff5f56" }
                                    Rectangle { width: 4.5; height: 4.5; radius: 2.5; color: "#ffbd2e" }
                                    Rectangle { width: 4.5; height: 4.5; radius: 2.5; color: "#27c93f" }
                                }
                            }

                            // Code editor syntax wireframe lines
                            Column {
                                anchors.top: parent.top
                                anchors.topMargin: 26
                                anchors.left: parent.left
                                anchors.leftMargin: 9
                                anchors.right: parent.right
                                anchors.rightMargin: 9
                                spacing: 6

                                Rectangle { width: parent.width * 0.50; height: 2; radius: 1; color: root.glow(TitanTheme.accent, 0.52) }
                                Rectangle { width: parent.width * 0.78; height: 2; radius: 1; color: root.glow(TitanTheme.accent, 0.35) }
                                Rectangle { width: parent.width * 0.42; height: 2; radius: 1; color: root.glow(TitanTheme.accent, 0.45) }
                                Rectangle { width: parent.width * 0.68; height: 2; radius: 1; color: root.glow(TitanTheme.accent, 0.30) }
                                Rectangle { width: parent.width * 0.32; height: 2; radius: 1; color: root.glow(TitanTheme.accent, 0.42) }
                            }
                        }

                        // Stack top window (Right pane top)
                        Rectangle {
                            x: parent.width * 0.60
                            y: 0
                            width: parent.width * 0.40
                            height: parent.height * 0.47
                            radius: 6
                            color: root.glow(TitanTheme.accent, 0.035)
                            border.width: 1
                            border.color: root.glow(TitanTheme.accent, 0.40)

                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 16
                                radius: 5
                                color: root.glow(TitanTheme.crust, 0.60)

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3.5

                                    Rectangle { width: 3.5; height: 3.5; radius: 2; color: root.glow(TitanTheme.accent, 0.65) }
                                    Rectangle { width: 3.5; height: 3.5; radius: 2; color: root.glow(TitanTheme.accent, 0.45) }
                                    Rectangle { width: 3.5; height: 3.5; radius: 2; color: root.glow(TitanTheme.accent, 0.45) }
                                }
                            }

                            Column {
                                anchors.top: parent.top
                                anchors.topMargin: 24
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                spacing: 5

                                Rectangle { width: parent.width * 0.65; height: 1.6; radius: 1; color: root.glow(TitanTheme.accent, 0.32) }
                                Rectangle { width: parent.width * 0.42; height: 1.6; radius: 1; color: root.glow(TitanTheme.accent, 0.22) }
                            }
                        }

                        // Stack bottom window (Right pane bottom)
                        Rectangle {
                            x: parent.width * 0.60
                            y: parent.height * 0.53
                            width: parent.width * 0.40
                            height: parent.height * 0.47
                            radius: 6
                            color: root.glow(TitanTheme.accent, 0.030)
                            border.width: 1
                            border.color: root.glow(TitanTheme.accent, 0.32)

                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 16
                                radius: 5
                                color: root.glow(TitanTheme.crust, 0.60)

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3.5

                                    Rectangle { width: 3.5; height: 3.5; radius: 2; color: root.glow(TitanTheme.accent, 0.55) }
                                    Rectangle { width: 3.5; height: 3.5; radius: 2; color: root.glow(TitanTheme.accent, 0.40) }
                                    Rectangle { width: 3.5; height: 3.5; radius: 2; color: root.glow(TitanTheme.accent, 0.40) }
                                }
                            }

                            // Terminal command prompt line
                            Row {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 10
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                spacing: 4

                                Rectangle { width: 4.5; height: 1.6; color: TitanTheme.accent }
                                Rectangle { width: parent.parent.width * 0.60; height: 1.6; color: root.glow(TitanTheme.accent, 0.38) }
                            }
                        }
                    }
                }

                // HUD corner brackets on focused slice
                Item {
                    anchors.fill: parent
                    visible: slice.focusedSlice

                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer

                        // Top-Left bracket
                        ShapePath {
                            strokeWidth: 2; strokeColor: TitanTheme.accent; fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: 14; startY: 3
                            PathLine { x: 3; y: 3 }
                            PathLine { x: 3; y: 14 }
                        }
                        // Top-Right bracket
                        ShapePath {
                            strokeWidth: 2; strokeColor: TitanTheme.accent; fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: glass.width - 14; startY: 3
                            PathLine { x: glass.width - 3; y: 3 }
                            PathLine { x: glass.width - 3; y: 14 }
                        }
                        // Bottom-Left bracket
                        ShapePath {
                            strokeWidth: 2; strokeColor: TitanTheme.accent; fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: 3; startY: glass.height - 14
                            PathLine { x: 3; y: glass.height - 3 }
                            PathLine { x: 14; y: glass.height - 3 }
                        }
                        // Bottom-Right bracket
                        ShapePath {
                            strokeWidth: 2; strokeColor: TitanTheme.accent; fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: glass.width - 14; startY: glass.height - 3
                            PathLine { x: glass.width - 3; y: glass.height - 3 }
                            PathLine { x: glass.width - 3; y: glass.height - 14 }
                        }
                    }
                }

                // Neon focus underline beam
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    width: slice.focusedSlice ? 84 : 0
                    height: 2.5
                    radius: 1.5
                    color: TitanTheme.accent
                }

                // Current wallpaper badge: concentric rings with neon center dot
                Item {
                    visible: slice.currentWallpaper
                    width: 24
                    height: 24
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 12

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: root.glow(TitanTheme.crust, 0.75)
                        border.width: 1.2
                        border.color: root.glow(TitanTheme.accent, 0.85)
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 8
                        height: 8
                        radius: 4
                        color: TitanTheme.accent
                    }
                }
            }

            MouseArea {
                id: sliceArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: slice.entry ? slice.entry.name : ""

                onClicked: {
                    if (slice.focusedSlice) {
                        root.applySelected()
                    } else {
                        root.selectIndex(index)
                    }
                }

                onDoubleClicked: {
                    root.selectIndex(index)
                    root.applySelected()
                }
            }
        }
    }

    // ── Dismiss HUD Node ─────────────────────────────────────────────────────
    Item {
        id: dismiss
        width: 40
        height: 40
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 24
        anchors.rightMargin: 24

        Accessible.role: Accessible.Button
        Accessible.name: "Close wallpaper picker"

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: dismissArea.containsMouse ? TitanTheme.stateHover : root.glow(TitanTheme.crust, 0.40)
            border.width: 1
            border.color: TitanTheme.borderSubtle
        }

        Shape {
            anchors.centerIn: parent
            width: 12
            height: 12
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 1.8
                strokeColor: dismissArea.containsMouse ? TitanTheme.textHigh : TitanTheme.textMid
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 2
                startY: 2
                PathLine { x: 10; y: 10 }
            }

            ShapePath {
                strokeWidth: 1.8
                strokeColor: dismissArea.containsMouse ? TitanTheme.textHigh : TitanTheme.textMid
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 10
                startY: 2
                PathLine { x: 2; y: 10 }
            }
        }

        MouseArea {
            id: dismissArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.cancel()
        }
    }
}
