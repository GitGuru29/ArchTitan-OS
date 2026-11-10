import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * BentoSectionCard — Draggable, Reorderable & Resizable Card Container
 * for ArchTitan Control Center.
 *
 * Provides:
 * - Dynamic position according to systemCtrl.getSectionOrder()
 * - Visual drag handle & DropArea for drag-and-drop reordering
 * - Instant 1-tap Move Up [▲] and Move Down [▼] reorder buttons
 * - In-place card resize toggle ([⬌ Half] vs [⤢ Full])
 * - Clean sapphire blue styling in edit mode; zero overhead in normal mode
 */
Item {
    id: sectionCardRoot
    Layout.fillWidth: true
    implicitHeight: cardCol.implicitHeight

    property string sectionKey: ""
    property int orderIndex: -1
    property int totalSections: 7
    property bool isHalfWidth: false
    property Component sourceComponent: null

    readonly property string sectionTitle: {
        switch (sectionKey) {
            case "connectivity": return "Connectivity";
            case "sliders":      return "Brightness & Volume";
            case "media":        return "Media Player";
            case "pulse":        return "Titan Pulse";
            case "actions":      return "Quick Actions";
            case "liquidGlass":  return "Liquid Glass";
            case "calendar":     return "Calendar";
            default:             return sectionKey;
        }
    }

    readonly property bool hasResizeOption: {
        return (sectionKey === "connectivity" || sectionKey === "sliders" ||
                sectionKey === "media" || sectionKey === "pulse" ||
                sectionKey === "actions" || sectionKey === "calendar");
    }

    readonly property string resizeLabel: {
        if (typeof systemCtrl === "undefined" || !systemCtrl) return "";
        if (sectionKey === "actions") {
            var sz = systemCtrl.getWidgetSize("actionGrid", "compact");
            return sz === "wide" ? "Compact" : "Wide";
        } else if (sectionKey === "calendar") {
            var calSz = systemCtrl.getWidgetSize("calendar", "compact");
            return calSz === "expanded" ? "Compact" : "Expand";
        } else {
            var cur = systemCtrl.getWidgetSize(sectionKey, "half");
            return cur === "full" ? "⬌ Half" : "⤢ Full";
        }
    }

    // ── DropArea for Reordering Bento Cards ─────────────────────────────────
    DropArea {
        id: cardDropArea
        anchors.fill: parent
        keys: ["bento-section-card"]
        onEntered: (drag) => {
            if (drag.source && typeof drag.source.orderIndex !== "undefined") {
                if (typeof bentoRoot !== "undefined" && bentoRoot) {
                    bentoRoot.hoverTargetCardIndex = sectionCardRoot.orderIndex;
                }
            }
        }
        onExited: {
            if (typeof bentoRoot !== "undefined" && bentoRoot && bentoRoot.hoverTargetCardIndex === sectionCardRoot.orderIndex) {
                bentoRoot.hoverTargetCardIndex = -1;
            }
        }
    }

    ColumnLayout {
        id: cardCol
        anchors.fill: parent
        spacing: 4

        // ── In-Place Edit Mode Toolbar ──────────────────────────────────────
        Rectangle {
            id: editBar
            Layout.fillWidth: true
            height: 22
            radius: 6
            color: Qt.rgba(0.04, 0.52, 1.0, 0.16)
            border.color: (typeof bentoRoot !== "undefined" && bentoRoot && bentoRoot.hoverTargetCardIndex === sectionCardRoot.orderIndex)
                          ? TitanTheme.accent
                          : Qt.rgba(0.04, 0.52, 1.0, 0.45)
            border.width: (typeof bentoRoot !== "undefined" && bentoRoot && bentoRoot.hoverTargetCardIndex === sectionCardRoot.orderIndex) ? 2 : 1
            visible: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 4

                // Drag Grip
                Item {
                    width: 12
                    height: 18

                    Text {
                        anchors.centerIn: parent
                        text: "⋮⋮"
                        font.pixelSize: 10
                        color: TitanTheme.accent
                    }

                    MouseArea {
                        id: cardDragMa
                        anchors.fill: parent
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        drag.target: sectionCardRoot
                        drag.axis: Drag.YAxis

                        onPressed: {
                            sectionCardRoot.Drag.active = true;
                            sectionCardRoot.Drag.source = sectionCardRoot;
                            if (typeof bentoRoot !== "undefined" && bentoRoot) {
                                bentoRoot.dragSourceCardIndex = sectionCardRoot.orderIndex;
                            }
                        }

                        onReleased: {
                            sectionCardRoot.Drag.drop();
                            sectionCardRoot.Drag.active = false;
                            if (typeof bentoRoot !== "undefined" && bentoRoot) {
                                var fromIdx = bentoRoot.dragSourceCardIndex;
                                var toIdx = bentoRoot.hoverTargetCardIndex;
                                if (fromIdx !== -1 && toIdx !== -1 && fromIdx !== toIdx) {
                                    if (typeof systemCtrl !== "undefined" && systemCtrl) {
                                        systemCtrl.moveSectionOrder(fromIdx, toIdx);
                                    }
                                }
                                bentoRoot.dragSourceCardIndex = -1;
                                bentoRoot.hoverTargetCardIndex = -1;
                            }
                            sectionCardRoot.y = 0;
                        }

                        onCanceled: {
                            sectionCardRoot.Drag.active = false;
                            if (typeof bentoRoot !== "undefined" && bentoRoot) {
                                bentoRoot.dragSourceCardIndex = -1;
                                bentoRoot.hoverTargetCardIndex = -1;
                            }
                            sectionCardRoot.y = 0;
                        }
                    }
                }

                // Section Label
                Text {
                    text: sectionCardRoot.sectionTitle
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: TitanTheme.textPrimary
                    elide: Text.ElideRight
                    Layout.maximumWidth: sectionCardRoot.isHalfWidth ? 65 : 120
                }

                Item { Layout.fillWidth: true }

                // In-Place Card Resize Pill Button
                Rectangle {
                    visible: sectionCardRoot.hasResizeOption
                    width: resizeText.implicitWidth + 8
                    height: 14
                    radius: 7
                    color: resizeBtnMa.containsMouse ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.1)

                    Text {
                        id: resizeText
                        anchors.centerIn: parent
                        text: sectionCardRoot.resizeLabel
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 7
                        font.weight: Font.Bold
                        color: resizeBtnMa.containsMouse ? "#FFFFFF" : TitanTheme.textPrimary
                    }

                    MouseArea {
                        id: resizeBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl) {
                                if (sectionCardRoot.sectionKey === "actions") {
                                    var curAct = systemCtrl.getWidgetSize("actionGrid", "compact");
                                    systemCtrl.setWidgetSize("actionGrid", (curAct === "compact" ? "wide" : "compact"));
                                } else if (sectionCardRoot.sectionKey === "calendar") {
                                    var curCal = systemCtrl.getWidgetSize("calendar", "compact");
                                    systemCtrl.setWidgetSize("calendar", (curCal === "compact" ? "expanded" : "compact"));
                                } else {
                                    systemCtrl.toggleWidgetSize(sectionCardRoot.sectionKey);
                                }
                            }
                        }
                    }
                }

                // Move Up Button [▲]
                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: upMa.containsMouse ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.1)
                    visible: sectionCardRoot.orderIndex > 0

                    Text {
                        anchors.centerIn: parent
                        text: "▲"
                        font.pixelSize: 6
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        id: upMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl && sectionCardRoot.orderIndex > 0) {
                                systemCtrl.moveSectionOrder(sectionCardRoot.orderIndex, sectionCardRoot.orderIndex - 1);
                            }
                        }
                    }
                }

                // Move Down Button [▼]
                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: downMa.containsMouse ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.1)
                    visible: sectionCardRoot.orderIndex < (sectionCardRoot.totalSections - 1)

                    Text {
                        anchors.centerIn: parent
                        text: "▼"
                        font.pixelSize: 6
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        id: downMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl && sectionCardRoot.orderIndex < (sectionCardRoot.totalSections - 1)) {
                                systemCtrl.moveSectionOrder(sectionCardRoot.orderIndex, sectionCardRoot.orderIndex + 1);
                            }
                        }
                    }
                }
            }
        }

        // ── Section Content Loader ──────────────────────────────────────────
        Loader {
            id: sectionLoader
            Layout.fillWidth: true
            sourceComponent: sectionCardRoot.sourceComponent
        }
    }

    Drag.keys: ["bento-section-card"]
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2
}
