import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * QuickToggleGrid — ArchTitan macOS Control Center Bento Dashboard.
 *
 * Implements the authentic macOS Control Center layout:
 * - Row 1: 3-Row Connectivity Stack (Left) + Focus / Night Shift / Dark Mode Cluster (Right)
 * - Row 2: Display & Sound Embedded-Icon Capsule Sliders (Side-by-Side or Stacked)
 * - Row 3: Liquid Glass / Frosted Blur Capsule Slider
 * - Row 4: Now Playing Media Card (Left) + Titan Pulse Ring Gauges (Right)
 * - Row 5: Frameless Utility Squircles Grid
 * - Row 6: Collapsible Mini-Calendar Strip
 */
ColumnLayout {
    id: bentoRoot
    Layout.fillWidth: true
    spacing: 8

    property int revision: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.tileVisibilityRevision : 0
    property int dragSourceCardIndex: -1
    property int hoverTargetCardIndex: -1

    readonly property var rawSectionOrder: {
        var rev = revision;
        return (typeof systemCtrl !== "undefined" && systemCtrl)
               ? systemCtrl.getSectionOrder()
               : ["connectivity", "focusCluster", "sliders", "liquidGlass", "media", "pulse"];
    }

    readonly property var sectionOrder: {
        var list = [];
        for (var i = 0; i < rawSectionOrder.length; ++i) {
            var s = rawSectionOrder[i];
            // "actions" lives inside the stepped Bottleneck Dock at the bottom of the popover
            if (s !== "actions" && s !== "calendar") {
                list.push(s);
            }
        }
        return list;
    }

    function getDefaultSizeForSection(secKey) {
        if (secKey === "actions" || secKey === "liquidGlass" || secKey === "calendar" || secKey === "sliders")
            return "full";
        return "half";
    }

    function computeLayoutRows() {
        var order = sectionOrder;
        var rows = [];
        var i = 0;
        while (i < order.length) {
            var secKey = order[i];
            var defaultSize = getDefaultSizeForSection(secKey);
            var size = (typeof systemCtrl !== "undefined" && systemCtrl)
                       ? systemCtrl.getWidgetSize(secKey, defaultSize)
                       : defaultSize;

            if (size === "half" && (i + 1) < order.length) {
                var nextSecKey = order[i + 1];
                var nextDefaultSize = getDefaultSizeForSection(nextSecKey);
                var nextSize = (typeof systemCtrl !== "undefined" && systemCtrl)
                               ? systemCtrl.getWidgetSize(nextSecKey, nextDefaultSize)
                               : nextDefaultSize;
                if (nextSize === "half") {
                    rows.push({
                        isPair: true,
                        item1: secKey,
                        index1: i,
                        item2: nextSecKey,
                        index2: i + 1
                    });
                    i += 2;
                    continue;
                }
            }

            rows.push({
                isPair: false,
                item1: secKey,
                index1: i,
                isHalf: (size === "half")
            });
            i += 1;
        }
        return rows;
    }

    function getComponentForSection(key, isHalf) {
        switch (key) {
            case "connectivity": return connectivityComponent;
            case "focusCluster": return focusClusterComponent;
            case "sliders":      return isHalf ? slidersHalfComponent : slidersFullComponent;
            case "media":        return mediaComponent;
            case "pulse":        return pulseComponent;
            case "actions":      return actionsComponent;
            case "liquidGlass":  return liquidGlassComponent;
            case "calendar":     return calendarComponent;
            default:             return null;
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  SECTION COMPONENTS
    // ═════════════════════════════════════════════════════════════════════════

    Component {
        id: connectivityComponent
        UnifiedConnectivityModule {
            width: parent ? parent.width : undefined
            onOpenWifiRequested: {
                if (typeof rootWindow !== "undefined" && rootWindow)
                    rootWindow.showWifiPage = true;
            }
        }
    }

    Component {
        id: focusClusterComponent
        MacFocusClusterModule {
            width: parent ? parent.width : undefined
        }
    }

    Component {
        id: slidersHalfComponent
        ColumnLayout {
            width: parent ? parent.width : undefined
            spacing: 8

            TitanSliderModule {
                Layout.fillWidth: true
                title: "Display"
                iconGlyph: "\uf185" // sun
                value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.brightness : 75
                onChanged: (v) => {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setBrightness(v);
                }
            }

            TitanSliderModule {
                Layout.fillWidth: true
                title: "Sound"
                iconGlyph: "\uf028" // speaker
                showOutputButton: true
                value: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sinkVolume : 60
                onChanged: (v) => {
                    if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.setVolume(v);
                }
            }
        }
    }

    Component {
        id: slidersFullComponent
        RowLayout {
            width: parent ? parent.width : undefined
            implicitHeight: 64
            spacing: 8

            TitanSliderModule {
                Layout.preferredWidth: (parent.width - 8) / 2
                Layout.fillWidth: true
                title: "Display"
                iconGlyph: "\uf185" // sun
                value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.brightness : 75
                onChanged: (v) => {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setBrightness(v);
                }
            }

            TitanSliderModule {
                Layout.preferredWidth: (parent.width - 8) / 2
                Layout.fillWidth: true
                title: "Sound"
                iconGlyph: "\uf028" // speaker
                showOutputButton: true
                value: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sinkVolume : 60
                onChanged: (v) => {
                    if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.setVolume(v);
                }
            }
        }
    }

    Component {
        id: mediaComponent
        NowPlayingModule {
            width: parent ? parent.width : undefined
        }
    }

    Component {
        id: pulseComponent
        TitanPulseModule {
            width: parent ? parent.width : undefined
        }
    }

    Component {
        id: actionsComponent
        TitanActionGrid {
            width: parent ? parent.width : undefined
        }
    }

    Component {
        id: liquidGlassComponent
        RowLayout {
            width: parent ? parent.width : undefined
            implicitHeight: 50
            spacing: 8

            // Left Card: Headerless Capsule Slider (Contrast / Warmth — matches Row 3 left of mockup)
            TitanSliderModule {
                Layout.preferredWidth: (parent.width - 8) / 2
                Layout.fillWidth: true
                showHeader: false
                title: "Warmth"
                iconGlyph: "\uf042" // contrast / moon
                value: 75
            }

            // Right Card: Liquid Glass Thumb Slider (matches Row 3 right of mockup)
            TitanSliderModule {
                Layout.preferredWidth: (parent.width - 8) / 2
                Layout.fillWidth: true
                title: "Liquid Glass"
                thumbStyle: true
                value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.glassOpacity : 68
                onChanged: (v) => {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setGlassOpacity(v);
                }
            }
        }
    }

    Component {
        id: calendarComponent
        CalendarFooter {
            width: parent ? parent.width : undefined
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  DYNAMIC BENTO ROWS (Modular, Reorderable & Resizable)
    // ═════════════════════════════════════════════════════════════════════════
    Repeater {
        model: bentoRoot.computeLayoutRows()

        delegate: Item {
            Layout.fillWidth: true
            implicitHeight: (rowData && rowData.isPair) ? rowContent.implicitHeight : singleCard.implicitHeight

            readonly property var rowData: modelData

            // Single Row with 2 Paired Half-Width Cards
            RowLayout {
                id: rowContent
                anchors.fill: parent
                spacing: 8
                visible: (rowData && rowData.isPair)

                BentoSectionCard {
                    Layout.preferredWidth: (parent.width - 8) / 2
                    Layout.fillWidth: true
                    sectionKey: (rowData && rowData.item1) ? rowData.item1 : ""
                    orderIndex: (rowData && typeof rowData.index1 !== "undefined") ? rowData.index1 : -1
                    totalSections: bentoRoot.sectionOrder.length
                    isHalfWidth: true
                    sourceComponent: (rowData && rowData.item1) ? bentoRoot.getComponentForSection(rowData.item1, true) : null
                }

                BentoSectionCard {
                    Layout.preferredWidth: (parent.width - 8) / 2
                    Layout.fillWidth: true
                    sectionKey: (rowData && rowData.item2) ? rowData.item2 : ""
                    orderIndex: (rowData && typeof rowData.index2 !== "undefined") ? rowData.index2 : -1
                    totalSections: bentoRoot.sectionOrder.length
                    isHalfWidth: true
                    sourceComponent: (rowData && rowData.item2) ? bentoRoot.getComponentForSection(rowData.item2, true) : null
                }
            }

            // Single Row with 1 Full-Width Card (or single un-paired half card)
            Item {
                anchors.fill: parent
                implicitHeight: singleCard.implicitHeight
                visible: (rowData && !rowData.isPair)

                BentoSectionCard {
                    id: singleCard
                    width: parent.width
                    sectionKey: (rowData && rowData.item1) ? rowData.item1 : ""
                    orderIndex: (rowData && typeof rowData.index1 !== "undefined") ? rowData.index1 : -1
                    totalSections: bentoRoot.sectionOrder.length
                    isHalfWidth: (rowData && typeof rowData.isHalf !== "undefined") ? rowData.isHalf : false
                    sourceComponent: (rowData && rowData.item1) ? bentoRoot.getComponentForSection(rowData.item1, rowData.isHalf) : null
                }
            }
        }
    }
}
