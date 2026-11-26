import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes 1.15
import ArchTitan.Media 1.0
import ArchTitan.TitanUI

Window {
    id: root
    title: "titan-media-hud"
    width: 508
    height: 104
    color: "transparent"
    visible: false

    // ── CONSTANTS & PALETTE ──────────────────────────────────────────────────
    readonly property int pillWidth: 476
    readonly property int pillHeight: 76
    readonly property int pillRadius: 38 // Perfect capsule pill (height / 2)

    // Dynamic accent with fallback to Taylor-grade lavender
    readonly property color accentColor: (typeof TitanTheme !== "undefined" && TitanTheme.accent)
                                         ? TitanTheme.accent : "#C084FC"
    readonly property color glowColor: (typeof TitanTheme !== "undefined" && TitanTheme.accent)
                                       ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.40)
                                       : "#50C084FC"

    // Volume toast state
    property bool showVolumeToast: false
    property real currentVolume: Mpris ? Mpris.volume : 1.0

    Timer {
        id: volumeToastTimer
        interval: 1200
        onTriggered: root.showVolumeToast = false
    }

    // ── KEYBOARD INTERACTION ────────────────────────────────────────────────
    Item {
        focus: Island.isVisible
        Keys.onEscapePressed: Island.dismiss()
        Keys.onSpacePressed: if (Mpris) Mpris.playPause()
        Keys.onLeftPressed: {
            if (Mpris && Mpris.length > 0) {
                var newPos = Math.max(0.0, Mpris.progress - 0.05);
                Mpris.seek(newPos);
            }
        }
        Keys.onRightPressed: {
            if (Mpris && Mpris.length > 0) {
                var newPos = Math.min(1.0, Mpris.progress + 0.05);
                Mpris.seek(newPos);
            }
        }
    }

    // ── CLIPPING & ANIMATION CONTAINER ──────────────────────────────────────
    Item {
        id: clipContainer
        anchors.fill: parent
        clip: false

        // ── THE LUXURY CAPSULE PILL ─────────────────────────────────────────
        Item {
            id: islandContent
            width: root.pillWidth
            height: root.pillHeight
            anchors.horizontalCenter: parent.horizontalCenter
            y: 12

            // ── LAYER 0: AMBIENT NEON HALO & DROP SHADOW (Behind) ───────────
            Rectangle {
                id: ambientHalo
                anchors.fill: parent
                anchors.margins: -7
                radius: root.pillRadius + 7
                color: "transparent"
                border.color: (Mpris && Mpris.isPlaying)
                              ? Qt.rgba(0.65, 0.45, 1.0, 0.32)
                              : Qt.rgba(0.50, 0.40, 0.8, 0.16)
                border.width: 3.5

                // Soft dark shadow underneath
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 4
                    radius: parent.radius
                    color: "#65000000"
                    z: -1
                }

                // Breathing pulse when playing
                SequentialAnimation on opacity {
                    running: Island.isVisible && (Mpris && Mpris.isPlaying)
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.55; to: 0.95; duration: 1600; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.95; to: 0.55; duration: 1600; easing.type: Easing.InOutQuad }
                }
            }

            // ── LAYER 1: OUTER OBSIDIAN METALLIC BEZEL (The Rim) ─────────────
            Rectangle {
                id: outerBezel
                anchors.fill: parent
                radius: root.pillRadius
                color: "#08090E" // Deep obsidian black glass base
                border.width: 1.5

                // Multi-stop metallic edge reflection
                border.color: (Mpris && Mpris.isPlaying) ? "#6D28D9" : "#4338CA"

                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "#0B0C14" }
                    GradientStop { position: 0.5; color: "#08090E" }
                    GradientStop { position: 1.0; color: "#05060A" }
                }

                // ── LAYER 2: INNER ELECTRIC NEON CONTOUR RING ────────────────
                Rectangle {
                    id: innerNeonLine
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: root.pillRadius - 2
                    color: "transparent"
                    border.width: 1

                    // Dual-accent cyan to lavender neon gradient border
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#70D6FF" } // Cyan neon glow on top-left
                        GradientStop { position: 0.45; color: "#A78BFA" } // Lavender
                        GradientStop { position: 1.0; color: "#C084FC" } // Radiant violet
                    }
                    opacity: (Mpris && Mpris.isPlaying) ? 0.70 : 0.40
                }

                // ── LAYER 3: SPECULAR CURVED GLASS REFLECTIONS (Clipped) ─────
                Item {
                    anchors.fill: parent
                    clip: true

                    // Top crisp 1px specular highlight
                    Rectangle {
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width * 0.72
                        height: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.25; color: "#30FFFFFF" }
                            GradientStop { position: 0.50; color: "#55FFFFFF" }
                            GradientStop { position: 0.75; color: "#30FFFFFF" }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    // Angled Diagonal Specular Sheen (Curved Glass Sheen)
                    Rectangle {
                        id: diagonalGlassSheen
                        width: 95
                        height: 250
                        x: parent.width * 0.44
                        y: -85
                        rotation: -32

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.30; color: "#00FFFFFF" }
                            GradientStop { position: 0.48; color: "#22FFFFFF" } // Bright glass glare
                            GradientStop { position: 0.68; color: "#0AFFFFFF" } // Soft falloff
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }
                }

                // ── LAYER 4: PILL CONTENTS ───────────────────────────────────
                // Mouse wheel handler for volume control anywhere on the pill
                WheelHandler {
                    onWheel: (event) => {
                        if (!Mpris) return;
                        var delta = event.angleDelta.y > 0 ? 0.05 : -0.05;
                        var newVol = Math.max(0.0, Math.min(1.0, Mpris.volume + delta));
                        Mpris.volume = newVol;
                        root.currentVolume = newVol;
                        root.showVolumeToast = true;
                        volumeToastTimer.restart();
                    }
                }

                // Left: Album Art
                AlbumArt {
                    id: albumArt
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    artSize: 48
                    cornerRadius: 12
                    showGlow: true
                }

                // Center: Artist, Title, and Scrubber Bar
                Item {
                    id: centerSection
                    anchors.left: albumArt.right
                    anchors.leftMargin: 13
                    anchors.right: transportRow.left
                    anchors.rightMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    height: 54

                    Column {
                        anchors.fill: parent
                        spacing: 2

                        // Top: Artist Name
                        Text {
                            width: parent.width
                            text: (Mpris && Mpris.artist.length > 0) ? Mpris.artist : "ArchTitan Audio"
                            font.family: "Adwaita Sans, JetBrainsMono Nerd Font, sans-serif"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: "#A4A4C8" // Muted lilac slate
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        // Middle: Track Title
                        Text {
                            width: parent.width
                            text: (Mpris && Mpris.title.length > 0) ? Mpris.title : "No Media Playing"
                            font.family: "Adwaita Sans, JetBrainsMono Nerd Font, sans-serif"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: "#FFFFFF" // Crisp brilliant white
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        // Bottom: Interactive Scrubber / Progress Bar
                        Item {
                            id: scrubberArea
                            width: parent.width
                            height: 18

                            property real scrubProgress: scrubberMouse.isDragging
                                                         ? scrubberMouse.dragProgress
                                                         : (Mpris ? Mpris.progress : 0.0)

                            // Track Background
                            Rectangle {
                                id: trackBg
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                height: 4
                                radius: 2
                                color: "#222332" // Dark glass slate

                                // Glowing Progress Fill
                                Rectangle {
                                    id: progressFill
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: Math.max(0, Math.min(parent.width, parent.width * scrubberArea.scrubProgress))
                                    radius: 2

                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "#8B5CF6" } // Violet
                                        GradientStop { position: 1.0; color: "#C084FC" } // Radiant lavender
                                    }
                                }
                            }

                            // Circular Scrubber Pip (Thumb)
                            Item {
                                id: scrubberPip
                                width: 14
                                height: 14
                                x: Math.max(0, Math.min(trackBg.width - width, (trackBg.width * scrubberArea.scrubProgress) - (width / 2)))
                                anchors.verticalCenter: parent.verticalCenter

                                // Outer glow halo
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: (scrubberMouse.containsMouse || scrubberMouse.isDragging) ? 16 : 12
                                    height: width
                                    radius: width / 2
                                    color: "transparent"
                                    border.color: "#60C084FC"
                                    border.width: 1.5
                                    opacity: (scrubberMouse.containsMouse || scrubberMouse.isDragging) ? 1.0 : 0.6

                                    Behavior on width {
                                        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                                    }
                                }

                                // Inner core pip (Pure white with lavender rim)
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: (scrubberMouse.containsMouse || scrubberMouse.isDragging) ? 10 : 8
                                    height: width
                                    radius: width / 2
                                    color: "#FFFFFF"
                                    border.color: "#A855F7"
                                    border.width: 1.5

                                    Behavior on width {
                                        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                                    }
                                }
                            }

                            // Interactive Drag & Click Area
                            MouseArea {
                                id: scrubberMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                property bool isDragging: false
                                property real dragProgress: 0.0

                                onPressed: (mouse) => {
                                    isDragging = true;
                                    seekToMouse(mouse.x);
                                }

                                onPositionChanged: (mouse) => {
                                    if (isDragging && pressed) {
                                        seekToMouse(mouse.x);
                                    }
                                }

                                onReleased: {
                                    isDragging = false;
                                }

                                function seekToMouse(mouseX) {
                                    if (!Mpris || Mpris.length <= 0) return;
                                    var norm = Math.max(0.0, Math.min(1.0, mouseX / width));
                                    dragProgress = norm;
                                    Mpris.seek(norm);
                                }
                            }

                            // Floating Timestamp Tooltip on Hover / Drag
                            Rectangle {
                                id: timeTooltip
                                visible: scrubberMouse.containsMouse || scrubberMouse.isDragging
                                opacity: visible ? 1.0 : 0.0
                                anchors.bottom: scrubberPip.top
                                anchors.bottomMargin: 4
                                anchors.horizontalCenter: scrubberPip.horizontalCenter
                                width: timeLabel.implicitWidth + 8
                                height: 16
                                radius: 4
                                color: "#E010111A"
                                border.color: "#35FFFFFF"
                                border.width: 1
                                z: 10

                                Text {
                                    id: timeLabel
                                    anchors.centerIn: parent
                                    text: (Mpris && Mpris.length > 0)
                                          ? (Mpris.positionText + " / " + Mpris.lengthText)
                                          : "0:00"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    color: "#FFFFFF"
                                }

                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }
                        }
                    }
                }

                // Right: Pure White Transport Controls
                Row {
                    id: transportRow
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    TransportButton {
                        type: "previous"
                        hitSize: 32
                        onActivated: if (Mpris) Mpris.previous()
                    }

                    TransportButton {
                        type: "playpause"
                        isPlaying: Mpris ? Mpris.isPlaying : false
                        hitSize: 34
                        onActivated: if (Mpris) Mpris.playPause()
                    }

                    TransportButton {
                        type: "next"
                        hitSize: 32
                        onActivated: if (Mpris) Mpris.next()
                    }
                }

                // ── VOLUME HUD TOAST (Overlaid when scrolling wheel) ─────────
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "#EE08090E"
                    border.color: "#A78BFA"
                    border.width: 1
                    visible: root.showVolumeToast
                    opacity: root.showVolumeToast ? 1.0 : 0.0

                    Row {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (root.currentVolume > 0.5) ? "🔊" : (root.currentVolume > 0 ? "🔉" : "🔇")
                            font.pixelSize: 18
                            color: "#FFFFFF"
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 180
                            height: 6
                            radius: 3
                            color: "#222332"

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * root.currentVolume
                                radius: 3
                                color: "#C084FC"
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(root.currentVolume * 100) + "%"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: "#FFFFFF"
                        }
                    }

                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }
            }
        }
    }

    // ── INITIAL STATE ────────────────────────────────────────────────────────
    Component.onCompleted: {
        islandContent.opacity = 0.0
        islandContent.scale = 0.85
        islandContent.y = -60
    }

    // ── OPEN ANIMATION (Springy Emerge from Top) ─────────────────────────────
    ParallelAnimation {
        id: openAnim

        NumberAnimation {
            target: islandContent
            property: "opacity"
            from: 0.0; to: 1.0
            duration: 150
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: islandContent
            property: "scale"
            from: 0.85; to: 1.0
            duration: 340
            easing.type: Easing.OutBack
            easing.overshoot: 1.05
        }

        NumberAnimation {
            target: islandContent
            property: "y"
            from: -50; to: 12
            duration: 340
            easing.type: Easing.OutBack
            easing.overshoot: 1.04
        }

        onFinished: Island.onOpenAnimationFinished()
    }

    // ── CLOSE ANIMATION (Retract to Top) ────────────────────────────────────
    ParallelAnimation {
        id: closeAnim

        NumberAnimation {
            target: islandContent
            property: "opacity"
            from: 1.0; to: 0.0
            duration: 180
            easing.type: Easing.InQuad
        }

        NumberAnimation {
            target: islandContent
            property: "scale"
            from: 1.0; to: 0.88
            duration: 220
            easing.type: Easing.InBack
            easing.overshoot: 0.8
        }

        NumberAnimation {
            target: islandContent
            property: "y"
            from: 12; to: -50
            duration: 220
            easing.type: Easing.InCubic
        }

        onFinished: {
            Island.onCloseAnimationFinished()
            root.visible = false
            islandContent.y = -60
            islandContent.scale = 0.85
        }
    }

    // ── STATE MACHINE CONNECTIONS ────────────────────────────────────────────
    Connections {
        target: Island

        function onRequestOpen() {
            closeAnim.stop()
            root.visible = true
            islandContent.y = -50
            islandContent.scale = 0.85
            islandContent.opacity = 0.0
            openAnim.start()
        }

        function onRequestClose() {
            openAnim.stop()
            closeAnim.start()
        }

        function onRequestExpand() {
            Island.onExpandAnimationFinished()
        }

        function onRequestCollapse() {
            Island.onCollapseAnimationFinished()
        }
    }
}
