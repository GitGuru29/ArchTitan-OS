import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * BentoSectionCard — macOS Control Center Zero-Jump Draggable & Corner-Resizable Module Container.
 *
 * Features:
 * - Zero height change between Normal mode and Edit Controls mode (no layout jump!)
 * - Top-Left floating drag pill (⋮⋮) + full-card drag-and-drop reordering
 * - Top-Right floating [▲] / [▼] instant reorder badges
 * - Bottom-Right Corner Resize Handle (◢) to resize cards in-place (Half 2x1 <-> Full 4x1)
 */
Item {
    id: sectionCardRoot
    Layout.fillWidth: true
    implicitHeight: (sectionLoader.item && sectionLoader.item.implicitHeight > 0)
                    ? sectionLoader.item.implicitHeight
                    : sectionLoader.implicitHeight

    property string sectionKey: ""
    property int orderIndex: -1
    property int totalSections: 7
    property bool isHalfWidth: false
    property Component sourceComponent: null

    readonly property bool editActive: (typeof rootWindow !== "undefined" && rootWindow && rootWindow.inPlaceEditMode)

    readonly property string sectionTitle: {
        switch (sectionKey) {
            case "connectivity": return "Connectivity";
            case "focusCluster": return "Focus & Appearance";
            case "sliders":      return "Display & Sound";
            case "media":        return "Now Playing";
            case "pulse":        return "Titan Pulse";
            case "actions":      return "Quick Actions";
            case "liquidGlass":  return "Liquid Glass";
            case "calendar":     return "Calendar";
            default:             return sectionKey;
        }
    }

    readonly property bool hasResizeOption: {
        return (sectionKey === "connectivity" || sectionKey === "focusCluster" ||
                sectionKey === "sliders" || sectionKey === "media" ||
                sectionKey === "pulse" || sectionKey === "actions" ||
                sectionKey === "calendar");
    }

    readonly property string resizeTooltip: {
        if (typeof systemCtrl === "undefined" || !systemCtrl) return "◢";
        if (sectionKey === "actions") {
            var sz = systemCtrl.getWidgetSize("actionGrid", "compact");
            return sz === "wide" ? "Compact ◢" : "Wide ◢";
        } else if (sectionKey === "calendar") {
            var isExp = (sectionLoader.item && sectionLoader.item.expanded) ? true : false;
            return isExp ? "Compact ◢" : "Expand ◢";
        } else {
            var cur = systemCtrl.getWidgetSize(sectionKey, "half");
            return cur === "full" ? "Half ◢" : "Full ◢";
        }
    }

    // ── DropArea for Reordering Whole Bento Modules ─────────────────────────
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

    // ── Main Module Content Loader ──────────────────────────────────────────
    Loader {
        id: sectionLoader
        width: parent.width
        sourceComponent: sectionCardRoot.sourceComponent
    }

    // ── Drop Target Highlight Ring in Edit Mode ─────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: TitanTheme.radiusCard
        color: (typeof bentoRoot !== "undefined" && bentoRoot && bentoRoot.hoverTargetCardIndex === sectionCardRoot.orderIndex)
               ? Qt.rgba(0.04, 0.52, 1.0, 0.22)
               : "transparent"
        border.color: TitanTheme.accent
        border.width: (typeof bentoRoot !== "undefined" && bentoRoot && bentoRoot.hoverTargetCardIndex === sectionCardRoot.orderIndex) ? 2 : 0
        visible: sectionCardRoot.editActive
        z: 40
    }

    // ── Top-Right Unified Floating Drag & Reorder Pill ([⋮⋮ Title] [▲] [▼]) ──
    RowLayout {
        visible: sectionCardRoot.editActive
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        spacing: 3
        z: 50

        Rectangle {
            height: 18
            width: dragRow.implicitWidth + 10
            radius: 9
            color: cardDragMa.pressed ? TitanTheme.accent : Qt.rgba(0.04, 0.08, 0.14, 0.90)
            border.color: TitanTheme.accent
            border.width: 1

            RowLayout {
                id: dragRow
                anchors.centerIn: parent
                spacing: 3

                Text {
                    text: "⋮⋮"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: TitanTheme.accent
                }

                Text {
                    text: sectionCardRoot.sectionTitle
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                }
            }

            MouseArea {
                id: cardDragMa
                anchors.fill: parent
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                drag.target: sectionCardRoot
                drag.axis: Drag.XAndYAxis

                onPressed: {
                    sectionCardRoot.z = 999;
                    sectionCardRoot.Drag.active = true;
                    sectionCardRoot.Drag.source = sectionCardRoot;
                    if (typeof bentoRoot !== "undefined" && bentoRoot) {
                        bentoRoot.dragSourceCardIndex = sectionCardRoot.orderIndex;
                    }
                }

                onReleased: {
                    sectionCardRoot.Drag.drop();
                    sectionCardRoot.Drag.active = false;
                    sectionCardRoot.z = 1;
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
                    sectionCardRoot.x = 0;
                    sectionCardRoot.y = 0;
                }

                onCanceled: {
                    sectionCardRoot.Drag.active = false;
                    sectionCardRoot.z = 1;
                    if (typeof bentoRoot !== "undefined" && bentoRoot) {
                        bentoRoot.dragSourceCardIndex = -1;
                        bentoRoot.hoverTargetCardIndex = -1;
                    }
                    sectionCardRoot.x = 0;
                    sectionCardRoot.y = 0;
                }
            }
        }

        Rectangle {
            width: 18
            height: 18
            radius: 9
            color: upMa.containsMouse ? TitanTheme.accent : Qt.rgba(0.04, 0.08, 0.14, 0.90)
            border.color: TitanTheme.accent
            border.width: 1
            visible: sectionCardRoot.orderIndex > 0

            Text {
                anchors.centerIn: parent
                text: "▲"
                font.pixelSize: 7
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

        Rectangle {
            width: 18
            height: 18
            radius: 9
            color: downMa.containsMouse ? TitanTheme.accent : Qt.rgba(0.04, 0.08, 0.14, 0.90)
            border.color: TitanTheme.accent
            border.width: 1
            visible: sectionCardRoot.orderIndex < (sectionCardRoot.totalSections - 1)

            Text {
                anchors.centerIn: parent
                text: "▼"
                font.pixelSize: 7
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

    // ── Bottom-Right Corner Resize Handle (◢) — macOS / iOS 18 Style ────────
    Rectangle {
        visible: sectionCardRoot.editActive && sectionCardRoot.hasResizeOption
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 4
        height: 18
        width: cornerLabel.implicitWidth + 12
        radius: 9
        color: cornerResizeMa.containsMouse ? TitanTheme.accent : Qt.rgba(0.04, 0.08, 0.14, 0.90)
        border.color: TitanTheme.accent
        border.width: 1
        z: 50

        Text {
            id: cornerLabel
            anchors.centerIn: parent
            text: sectionCardRoot.resizeTooltip
            font.family: TitanTheme.fontFamily
            font.pixelSize: 8
            font.weight: Font.Bold
            color: "#FFFFFF"
        }

        MouseArea {
            id: cornerResizeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            onClicked: {
                if (typeof systemCtrl !== "undefined" && systemCtrl) {
                    if (sectionCardRoot.sectionKey === "actions") {
                        var curAct = systemCtrl.getWidgetSize("actionGrid", "compact");
                        systemCtrl.setWidgetSize("actionGrid", (curAct === "compact" ? "wide" : "compact"));
                    } else if (sectionCardRoot.sectionKey === "calendar") {
                        if (sectionLoader.item && typeof sectionLoader.item.toggle === "function") {
                            sectionLoader.item.toggle();
                        }
                    } else {
                        systemCtrl.toggleWidgetSize(sectionCardRoot.sectionKey);
                    }
                }
            }
        }
    }

    Drag.keys: ["bento-section-card"]
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2
}
