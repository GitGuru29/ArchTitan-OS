import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanActionTile — ArchTitan In-Place Customizable Action Squircle Tile.
 *
 * Implements the approved mockup squircle action button:
 * - Compact 1x1 squircle (default) or wide 2x1 tile
 * - Centered icon + title label
 * - Glowing Titan Orange active state
 * - In-place corner resize handle [ ⤡ ] to resize directly on the screen
 * - In-place drag & drop reordering
 */
Rectangle {
    id: tileRoot
    radius: 12
    clip: true

    property string tileKey: "focus"
    property string iconGlyph: "\uf042" // contrast
    property string title: "Dark Mode"
    property string statusText: active ? "On" : "Off"
    property bool active: false
    property string sizeVariant: "compact" // "compact" (1x1) or "wide" (2x1)
    property int modelIndex: 0

    signal clicked()
    signal moveRequested(int fromIdx, int toIdx)

    // Sizing: Compact squircle vs Wide 2-column tile
    Layout.fillWidth: true
    Layout.columnSpan: (sizeVariant === "wide") ? 2 : 1
    implicitHeight: (sizeVariant === "wide") ? 46 : 56
    implicitWidth: (sizeVariant === "wide") ? 120 : 56

    color: active
           ? Qt.rgba(1.0, 0.42, 0.0, 0.14)
           : (tileMa.pressed ? TitanTheme.bgPressed : (tileMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgInset))

    border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                  ? TitanTheme.accent
                  : (active ? TitanTheme.borderActive : (tileMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline))
    border.width: 1

    scale: tileMa.pressed ? 0.94 : (tileMa.containsMouse ? 1.02 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
    }
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    // ── Layout 1: Compact Squircle (Default as shown in mockup) ─────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 2
        visible: tileRoot.sizeVariant !== "wide"

        Item { Layout.fillHeight: true }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: tileRoot.iconGlyph
            font.family: TitanTheme.monoFamily
            font.pixelSize: 15
            color: tileRoot.active ? TitanTheme.accent : TitanTheme.textSecondary
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: tileRoot.title
            font.family: TitanTheme.fontFamily
            font.pixelSize: 8
            font.weight: Font.DemiBold
            color: tileRoot.active ? TitanTheme.textPrimary : TitanTheme.textMuted
            elide: Text.ElideRight
            Layout.maximumWidth: parent.width - 6
        }

        Item { Layout.fillHeight: true }
    }

    // ── Layout 2: Wide 2x1 Tile (When resized by user) ──────────────────────
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8
        visible: tileRoot.sizeVariant === "wide"

        Rectangle {
            width: 26
            height: 26
            radius: 13
            color: tileRoot.active ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.07)

            Text {
                anchors.centerIn: parent
                text: tileRoot.iconGlyph
                font.family: TitanTheme.monoFamily
                font.pixelSize: 12
                color: tileRoot.active ? "#0D1017" : TitanTheme.textMuted
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: tileRoot.title
                font.family: TitanTheme.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: tileRoot.active ? TitanTheme.textPrimary : TitanTheme.textSecondary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: tileRoot.statusText
                font.family: TitanTheme.fontFamily
                font.pixelSize: 8
                color: tileRoot.active ? TitanTheme.accent : TitanTheme.textSubtle
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    // ── In-Place Corner Resize Handle [ ⤡ ] ─────────────────────────────────
    Rectangle {
        id: resizeHandle
        width: 14
        height: 14
        radius: 3
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 2
        color: resizeMa.containsMouse ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.12)
        visible: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
        z: 10

        Text {
            anchors.centerIn: parent
            text: "⤡"
            font.pixelSize: 9
            color: resizeMa.containsMouse ? "#0D1017" : TitanTheme.accent
        }

        MouseArea {
            id: resizeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            onClicked: {
                var nextSize = (tileRoot.sizeVariant === "wide") ? "compact" : "wide";
                tileRoot.sizeVariant = nextSize;
                if (typeof systemCtrl !== "undefined" && systemCtrl) {
                    systemCtrl.setActionSize(tileRoot.tileKey, nextSize);
                }
            }
        }
    }

    // ── Mouse Area with In-Place Drag & Drop ────────────────────────────────
    MouseArea {
        id: tileMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) ? Qt.OpenHandCursor : Qt.PointingHandCursor

        drag.target: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) ? tileRoot : undefined
        drag.axis: Drag.XAndYAxis

        onClicked: {
            if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) {
                // In edit mode, clicking tile toggles size variant
                var nextSize = (tileRoot.sizeVariant === "wide") ? "compact" : "wide";
                tileRoot.sizeVariant = nextSize;
                if (typeof systemCtrl !== "undefined" && systemCtrl)
                    systemCtrl.setActionSize(tileRoot.tileKey, nextSize);
            } else {
                tileRoot.clicked();
            }
        }
    }
}
