import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * QuickToggleGrid — ArchTitan Control Center Modular Bento Dashboard.
 *
 * Implements macOS Control Center 2-column bento architecture:
 * - Row 1: Unified Connectivity Module + Display & Sound continuous sliders
 * - Row 2: Now Playing Media Module
 * - Row 3: Quick Action Tiles (2-column rounded rectangles)
 * - Row 4: Titan Pulse Hardware Intelligence & Power Profiles
 */
ColumnLayout {
    id: bentoRoot
    Layout.fillWidth: true
    spacing: 8

    property int revision: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.tileVisibilityRevision : 0

    readonly property var sectionOrder: {
        var rev = revision;
        return (typeof systemCtrl !== "undefined" && systemCtrl)
               ? systemCtrl.getSectionOrder()
               : ["topSplit", "nowPlaying", "actions", "pulse"];
    }

    // ── Modular Section Repeater ────────────────────────────────────────────
    Repeater {
        model: bentoRoot.sectionOrder

        delegate: Loader {
            Layout.fillWidth: true
            sourceComponent: {
                if (modelData === "topSplit" || modelData === "topRow") return topSplitComponent;
                if (modelData === "nowPlaying" || modelData === "music") return nowPlayingComponent;
                if (modelData === "actions") return actionsComponent;
                if (modelData === "pulse" || modelData === "performance" || modelData === "battery") return pulseComponent;
                if (modelData === "connectivity") return connectivityOnlyComponent;
                if (modelData === "sliders") return slidersOnlyComponent;
                return null;
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  SECTION COMPONENTS
    // ═════════════════════════════════════════════════════════════════════════

    // 1. Dual Columns: Unified Connectivity (Left) + Display/Sound (Right)
    Component {
        id: topSplitComponent
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Left Column: Unified Connectivity (Wi-Fi, Bluetooth, TitanDrop)
            UnifiedConnectivityModule {
                Layout.preferredWidth: (parent.width - 8) / 2
                Layout.fillWidth: true
                onOpenWifiRequested: {
                    if (typeof rootWindow !== "undefined" && rootWindow)
                        rootWindow.showWifiPage = true;
                }
            }

            // Right Column: Display Brightness & Sound Volume
            ColumnLayout {
                Layout.preferredWidth: (parent.width - 8) / 2
                Layout.fillWidth: true
                spacing: 8

                TitanSliderModule {
                    title: "Display"
                    iconGlyph: "\uf185" // sun
                    value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.brightness : 72
                    fillAccent: TitanTheme.accent
                    onChanged: (v) => {
                        if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setBrightness(v);
                    }
                }

                TitanSliderModule {
                    title: "Sound"
                    iconGlyph: "\uf028" // volume
                    value: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sinkVolume : 55
                    fillAccent: TitanTheme.accent
                    onChanged: (v) => {
                        if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.setVolume(v);
                    }
                }
            }
        }
    }

    // 2. Now Playing Module (Media)
    Component {
        id: nowPlayingComponent
        NowPlayingModule {
            Layout.fillWidth: true
        }
    }

    // 3. Quick Action Tiles Grid
    Component {
        id: actionsComponent
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "QUICK ACTIONS"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                    color: TitanTheme.textSubtle
                }

                Item { Layout.fillWidth: true }
            }

            TitanActionGrid {
                Layout.fillWidth: true
            }
        }
    }

    // 4. Titan Pulse: Hardware Intelligence & Power Profiles
    Component {
        id: pulseComponent
        TitanPulseModule {
            Layout.fillWidth: true
        }
    }

    // ── Standalone Fallbacks ────────────────────────────────────────────────
    Component {
        id: connectivityOnlyComponent
        UnifiedConnectivityModule {
            Layout.fillWidth: true
            onOpenWifiRequested: {
                if (typeof rootWindow !== "undefined" && rootWindow)
                    rootWindow.showWifiPage = true;
            }
        }
    }

    Component {
        id: slidersOnlyComponent
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            TitanSliderModule {
                title: "Display"
                iconGlyph: "\uf185"
                value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.brightness : 72
                fillAccent: TitanTheme.accent
                onChanged: (v) => {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setBrightness(v);
                }
            }

            TitanSliderModule {
                title: "Sound"
                iconGlyph: "\uf028"
                value: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sinkVolume : 55
                fillAccent: TitanTheme.accent
                onChanged: (v) => {
                    if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.setVolume(v);
                }
            }
        }
    }
}
