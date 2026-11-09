import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * QuickToggleGrid — Super-Round Apple macOS / iOS 18 Bento Grid.
 *
 * Architecture:
 * - Row 1: Dual Pebble Squares (172x168, radius: 28px)
 *          Left: Square Connectivity Widget (Wi-Fi, Bluetooth, TitanDrop)
 *          Right: Square Music Player Widget (Artwork, Track info, Circular Playback)
 * - Row 2: Display Brightness Pebble Card (radius: 24px) with 28px Capsule Slider
 * - Row 3: Sound Volume Pebble Card (radius: 24px) with 28px Capsule Slider
 * - Row 4: 8x Full-Circle Action Grid (radius: 24px) with 48px circular buttons
 * - Row 5: Liquid Glass Opacity Pebble Card (radius: 24px) with 28px Capsule Slider
 */
ColumnLayout {
    id: bentoRoot
    Layout.fillWidth: true
    spacing: 10

    // ── 1. Top Section: Dual Pebble Squares (Connectivity + Music Player) ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // Left Square: Connectivity Widget (radius: 28px)
        SquareConnectivityWidget {
            Layout.fillWidth: true
            onOpenWifiRequested: {
                if (typeof rootWindow !== "undefined" && rootWindow) {
                    rootWindow.showWifiPage = true;
                }
            }
        }

        // Right Square: Music Player Widget (radius: 28px)
        SquareMusicWidget {
            Layout.fillWidth: true
            visible: (typeof systemCtrl === "undefined" || !systemCtrl) || ((systemCtrl.tileVisibilityRevision >= 0) && systemCtrl.getTileVisible("deviceMedia", true))
        }
    }

    // ── 2. Display Brightness Bento Card (Super-Round Capsule Slider) ───────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: displayCol.implicitHeight + 20
        radius: TitanTheme.radiusCard // 24px super-round
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true
        visible: (typeof systemCtrl === "undefined" || !systemCtrl) || ((systemCtrl.tileVisibilityRevision >= 0) && systemCtrl.getTileVisible("sliders", true))

        ColumnLayout {
            id: displayCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            OneUISlider {
                title: "Display"
                iconGlyph: "\uf185" // sun
                from: 0
                to: 100
                value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.brightness : 80
                fillAccent: TitanTheme.accent
                onChanged: (v) => {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setBrightness(v)
                }
            }
        }
    }

    // ── 3. Sound Volume Bento Card (Super-Round Capsule Slider) ─────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: soundCol.implicitHeight + 20
        radius: TitanTheme.radiusCard // 24px super-round
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true
        visible: (typeof systemCtrl === "undefined" || !systemCtrl) || ((systemCtrl.tileVisibilityRevision >= 0) && systemCtrl.getTileVisible("sliders", true))

        ColumnLayout {
            id: soundCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            OneUISlider {
                title: "Sound"
                iconGlyph: {
                    if (muted) return "\uf026";
                    if (value <= 30) return "\uf027";
                    return "\uf028";
                }
                from: 0
                to: 100
                value: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sinkVolume : 60
                muted: typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sinkMuted
                fillAccent: TitanTheme.accent
                onChanged: (v) => {
                    if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.setVolume(v)
                }
            }
        }
    }

    // ── 4. 8x Full-Circle Quick Action Grid (Super-Round Pebble Card) ──────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: actionGrid.implicitHeight + 28
        radius: TitanTheme.radiusCard // 24px super-round
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true

        CircularActionGrid {
            id: actionGrid
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
        }
    }

    // ── 5. Liquid Glass Opacity Bento Card (ArchTitan Exclusive) ───────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: glassCol.implicitHeight + 20
        radius: TitanTheme.radiusCard // 24px super-round
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true

        ColumnLayout {
            id: glassCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            OneUISlider {
                title: "Liquid Glass"
                iconGlyph: "\uf043" // water droplet
                from: 10
                to: 95
                value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.glassOpacity : 35
                suffix: "%"
                fillAccent: TitanTheme.cyan
                onChanged: (v) => {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) {
                        if (typeof systemCtrl.setGlassOpacity === "function") {
                            systemCtrl.setGlassOpacity(v)
                        } else {
                            systemCtrl.glassOpacity = v
                        }
                    }
                }
            }
        }
    }
}
