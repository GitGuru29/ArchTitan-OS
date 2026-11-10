import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * QuickToggleGrid — ArchTitan Control Center Dynamic Modular Bento Dashboard.
 *
 * Implements a fully customizable macOS-inspired bento layout:
 * - Dynamic Section Order from systemCtrl.getSectionOrder()
 * - Move the places of whole cards (drag-and-drop or ▲ / ▼ 1-tap reorder buttons)
 * - Resize cards on the same screen ([⬌ Half] vs [⤢ Full], Compact vs Wide, etc.)
 * - Automatic paired row grouping for adjacent half-width cards
 * - Frameless Quick Actions (outer border completely removed)
 * - macOS Sapphire Blue palette
 */
ColumnLayout {
    id: bentoRoot
    Layout.fillWidth: true
    spacing: 8

    property int revision: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.tileVisibilityRevision : 0
    property int dragSourceCardIndex: -1
    property int hoverTargetCardIndex: -1

    readonly property var sectionOrder: {
        var rev = revision;
        return (typeof systemCtrl !== "undefined" && systemCtrl)
               ? systemCtrl.getSectionOrder()
               : ["connectivity", "sliders", "media", "pulse", "actions", "liquidGlass", "calendar"];
    }

    function computeLayoutRows() {
        var order = sectionOrder;
        var rows = [];
        var i = 0;
        while (i < order.length) {
            var secKey = order[i];
            var defaultSize = (secKey === "actions" || secKey === "liquidGlass" || secKey === "calendar") ? "full" : "half";
            var size = (typeof systemCtrl !== "undefined" && systemCtrl)
                       ? systemCtrl.getWidgetSize(secKey, defaultSize)
                       : defaultSize;

            if (size === "half" && (i + 1) < order.length) {
                var nextSecKey = order[i + 1];
                var nextDefaultSize = (nextSecKey === "actions" || nextSecKey === "liquidGlass" || nextSecKey === "calendar") ? "full" : "half";
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
            case "sliders":      return isHalf ? slidersHalfComponent : slidersFullComponent;
            case "media":        return mediaComponent;
            case "pulse":        return pulseComponent;
            case "actions":      return actionsComponent;
            case "liquidGlass":  return liquidGlassComponent;
            case "calendar":     return calendarComponent;
            default:             return null;
        }
    }

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
                text: "CUSTOMIZING CONTROL CENTER · Drag or use ▲▼ to reorder · Toggle size"
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
        id: slidersHalfComponent
        ColumnLayout {
            width: parent ? parent.width : undefined
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

    Component {
        id: slidersFullComponent
        RowLayout {
            width: parent ? parent.width : undefined
            spacing: 8

            TitanSliderModule {
                Layout.preferredWidth: (parent.width - 8) / 2
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
                Layout.preferredWidth: (parent.width - 8) / 2
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
        TitanSliderModule {
            width: parent ? parent.width : undefined
            title: "Liquid Glass / Frosted Blur"
            iconGlyph: "\uf043" // droplet
            value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.glassOpacity : 35
            fillAccent: TitanTheme.accent
            onChanged: (v) => {
                if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setGlassOpacity(v);
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
            implicitHeight: rowContent.implicitHeight

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
