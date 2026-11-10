import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * QuickToggleGrid — ArchTitan Control Center Modular Bento Dashboard.
 *
 * Implements the approved macOS-inspired 2-column bento layout:
 * - Row 1 Left:  Unified Connectivity (Wi-Fi, Bluetooth, TitanDrop)
 * - Row 1 Right: Media Player (Solaris album art, animated soundwave, controls)
 * - Row 2 Left:  Brightness Capsule Slider Module
 * - Row 2 Right: Volume Capsule Slider Module
 * - Row 3 Left:  Quick Action 3x2 Squircle Grid
 * - Row 3 Right: Titan Pulse Hardware Telemetry (Horseshoe Gauges + Profiles)
 * - Row 4 Full:  Liquid Glass / Transparency Capsule Slider Controller
 *
 * All modules feature in-place corner resizing [ ⤡ ] and in-place customization
 * directly on the live dashboard.
 */
ColumnLayout {
    id: bentoRoot
    Layout.fillWidth: true
    spacing: 8

    property int revision: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.tileVisibilityRevision : 0

    // ── In-Place Edit Mode Banner ───────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        height: 28
        radius: 14
        color: Qt.rgba(1.0, 0.42, 0.0, 0.15)
        border.color: TitanTheme.accent
        border.width: 1
        visible: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 6
            spacing: 8

            Text {
                text: "\uf044"
                font.family: TitanTheme.monoFamily
                font.pixelSize: 11
                color: TitanTheme.accent
            }

            Text {
                text: "CUSTOMIZING · Drag corners [ ⤡ ] to resize"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 9
                font.weight: Font.DemiBold
                color: TitanTheme.textPrimary
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 46
                height: 20
                radius: 10
                color: TitanTheme.accent

                Text {
                    anchors.centerIn: parent
                    text: "Done"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: "#0D1017"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof rootWindow !== "undefined" && rootWindow)
                            rootWindow.inPlaceEditMode = false;
                    }
                }
            }
        }
    }

    // ── Symmetrical 2-Column Bento Dashboard (Approved Mockup Layout) ───────
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // ═════════════════════════════════════════════════════════════════════
        //  LEFT COLUMN
        // ═════════════════════════════════════════════════════════════════════
        ColumnLayout {
            Layout.preferredWidth: (parent.width - 8) / 2
            Layout.fillWidth: true
            spacing: 8

            // 1. Connectivity Card
            UnifiedConnectivityModule {
                Layout.fillWidth: true
                onOpenWifiRequested: {
                    if (typeof rootWindow !== "undefined" && rootWindow)
                        rootWindow.showWifiPage = true;
                }
            }

            // 2. Brightness Slider Card
            TitanSliderModule {
                Layout.fillWidth: true
                title: "Brightness"
                iconGlyph: "\uf185" // sun
                value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.brightness : 72
                fillAccent: TitanTheme.accent
                onChanged: (v) => {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setBrightness(v);
                }
            }

            // 3. Quick Action Grid Card
            TitanActionGrid {
                Layout.fillWidth: true
            }
        }

        // ═════════════════════════════════════════════════════════════════════
        //  RIGHT COLUMN
        // ═════════════════════════════════════════════════════════════════════
        ColumnLayout {
            Layout.preferredWidth: (parent.width - 8) / 2
            Layout.fillWidth: true
            spacing: 8

            // 1. Media Player Card
            NowPlayingModule {
                Layout.fillWidth: true
            }

            // 2. Volume Slider Card
            TitanSliderModule {
                Layout.fillWidth: true
                title: "Volume"
                iconGlyph: "\uf028" // volume
                value: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sinkVolume : 55
                fillAccent: TitanTheme.accent
                onChanged: (v) => {
                    if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.setVolume(v);
                }
            }

            // 3. Titan Pulse Telemetry Card
            TitanPulseModule {
                Layout.fillWidth: true
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  ROW 4: Liquid Glass / Transparency Controller (User Mandatory Feature)
    // ═════════════════════════════════════════════════════════════════════════
    TitanSliderModule {
        Layout.fillWidth: true
        title: "Liquid Glass / Transparency"
        iconGlyph: "\uf043" // droplet / glass
        value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.glassOpacity : 35
        fillAccent: TitanTheme.accent
        onChanged: (v) => {
            if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setGlassOpacity(v);
        }
    }
}
