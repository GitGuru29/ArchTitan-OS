import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * QuickToggleGrid — ArchTitan Control Center Modular Bento Dashboard.
 *
 * Implements a balanced macOS-inspired bento layout:
 * - Cluster 1 (140px): Unified Connectivity (Left) balanced with Brightness & Volume (Right)
 * - Cluster 2 (110px): Media Player (Left) balanced with Titan Pulse Hardware Telemetry (Right)
 * - Cluster 3: Symmetrical 2-Column Quick Actions Grid
 * - Cluster 4: Dedicated Liquid Glass / Transparency Capsule Slider Controller
 *
 * Uses the macOS Sapphire Cyan/Blue palette for a calm, premium desktop OS aesthetic.
 */
ColumnLayout {
    id: bentoRoot
    Layout.fillWidth: true
    spacing: 8

    // ── In-Place Edit Mode Banner ───────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        height: 28
        radius: 14
        color: Qt.rgba(0.04, 0.52, 1.0, 0.16)
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
                text: "CUSTOMIZING CONTROL CENTER"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 9
                font.weight: Font.DemiBold
                color: TitanTheme.textPrimary
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 48
                height: 20
                radius: 10
                color: TitanTheme.accent

                Text {
                    anchors.centerIn: parent
                    text: "Done"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: "#FFFFFF"
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

    // ═════════════════════════════════════════════════════════════════════════
    //  CLUSTER 1 (Height: 140px): Connectivity (Left) & Sliders (Right)
    // ═════════════════════════════════════════════════════════════════════════
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Left: Unified Connectivity (140px)
        UnifiedConnectivityModule {
            Layout.preferredWidth: (parent.width - 8) / 2
            Layout.fillWidth: true
            onOpenWifiRequested: {
                if (typeof rootWindow !== "undefined" && rootWindow)
                    rootWindow.showWifiPage = true;
            }
        }

        // Right: Display Brightness (66px) + Sound Volume (66px) = 140px total
        ColumnLayout {
            Layout.preferredWidth: (parent.width - 8) / 2
            Layout.fillWidth: true
            spacing: 8

            TitanSliderModule {
                Layout.fillWidth: true
                title: "Display Brightness"
                iconGlyph: "\uf185" // sun
                value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.brightness : 72
                fillAccent: TitanTheme.accent
                onChanged: (v) => {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setBrightness(v);
                }
            }

            TitanSliderModule {
                Layout.fillWidth: true
                title: "Sound Volume"
                iconGlyph: "\uf028" // volume
                value: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sinkVolume : 55
                fillAccent: TitanTheme.accent
                onChanged: (v) => {
                    if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.setVolume(v);
                }
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  CLUSTER 2 (Height: 110px): Media Player (Left) & Titan Pulse (Right)
    // ═════════════════════════════════════════════════════════════════════════
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Left: Now Playing Media Player (110px)
        NowPlayingModule {
            Layout.preferredWidth: (parent.width - 8) / 2
            Layout.fillWidth: true
        }

        // Right: Titan Pulse Telemetry (110px)
        TitanPulseModule {
            Layout.preferredWidth: (parent.width - 8) / 2
            Layout.fillWidth: true
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  CLUSTER 3: Symmetrical Quick Actions Grid
    // ═════════════════════════════════════════════════════════════════════════
    TitanActionGrid {
        Layout.fillWidth: true
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  CLUSTER 4: Liquid Glass / Transparency Controller
    // ═════════════════════════════════════════════════════════════════════════
    TitanSliderModule {
        Layout.fillWidth: true
        title: "Liquid Glass / Frosted Blur"
        iconGlyph: "\uf043" // droplet / glass tint
        value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.glassOpacity : 35
        fillAccent: TitanTheme.accent
        onChanged: (v) => {
            if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setGlassOpacity(v);
        }
    }
}
