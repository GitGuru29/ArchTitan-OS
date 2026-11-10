import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanActionGrid — ArchTitan 3-Column Squircle Quick Action Bento Card.
 *
 * Implements the approved mockup Quick Action card:
 * - Header: "Quick Action"
 * - 3x2 Squircle Action Grid (Night Shift, Dark Mode, Mic Mute, Awake, Screenshot, Game Mode)
 * - Dynamic Action Order from systemCtrl
 * - In-place corner resize & reordering
 */
Rectangle {
    id: gridCardRoot
    Layout.fillWidth: true
    implicitHeight: actionCol.implicitHeight + 20
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                  ? TitanTheme.accent
                  : (cardMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)
    border.width: 1

    property int revision: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.tileVisibilityRevision : 0

    ColumnLayout {
        id: actionCol
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // ── Card Header ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Quick Action"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: TitanTheme.textPrimary
            }

            Item { Layout.fillWidth: true }
        }

        // ── 3-Column Squircle Grid ──────────────────────────────────────────
        GridLayout {
            id: actionsLayout
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 6
            rowSpacing: 6

            // Tile 1: Night Shift
            TitanActionTile {
                tileKey: "night"
                iconGlyph: "\uf06e" // eye
                title: "Night Shift"
                active: (typeof nightLightCtrl !== "undefined" && nightLightCtrl) ? nightLightCtrl.active : false
                statusText: active ? "4500K" : "Off"
                sizeVariant: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.getActionSize("night") : "compact"
                onClicked: {
                    if (typeof nightLightCtrl !== "undefined" && nightLightCtrl)
                        nightLightCtrl.toggleNightLight();
                }
            }

            // Tile 2: Dark Mode
            TitanActionTile {
                tileKey: "dark"
                iconGlyph: "\uf042" // contrast
                title: "Dark Mode"
                active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.themeDark : true
                statusText: active ? "Obsidian" : "Light"
                sizeVariant: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.getActionSize("dark") : "compact"
                onClicked: {
                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                        systemCtrl.themeDark = !systemCtrl.themeDark;
                }
            }

            // Tile 3: Mic Mute
            TitanActionTile {
                tileKey: "mic"
                iconGlyph: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted) ? "\uf131" : "\uf130"
                title: "Mic Mute"
                active: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sourceMuted : false
                statusText: active ? "Muted" : "Active"
                sizeVariant: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.getActionSize("mic") : "compact"
                onClicked: {
                    if (typeof audioCtrl !== "undefined" && audioCtrl)
                        audioCtrl.toggleSourceMute();
                }
            }

            // Tile 4: Stay Awake
            TitanActionTile {
                tileKey: "caffeine"
                iconGlyph: "\uf0f4" // coffee
                title: "Stay Awake"
                active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.caffeineActive : false
                statusText: active ? "Active" : "Off"
                sizeVariant: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.getActionSize("caffeine") : "compact"
                onClicked: {
                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                        systemCtrl.caffeineActive = !systemCtrl.caffeineActive;
                }
            }

            // Tile 5: Screenshot
            TitanActionTile {
                tileKey: "capture"
                iconGlyph: "\uf030" // camera
                title: "Screenshot"
                active: false
                statusText: "Ready"
                sizeVariant: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.getActionSize("capture") : "compact"
                onClicked: {
                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                        systemCtrl.triggerScreenshot();
                }
            }

            // Tile 6: Game Mode
            TitanActionTile {
                tileKey: "gameMode"
                iconGlyph: "\uf11b" // gamepad
                title: "Game Mode"
                active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.gameModeActive : false
                statusText: active ? "Boosted" : "Off"
                sizeVariant: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.getActionSize("gameMode") : "compact"
                onClicked: {
                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                        systemCtrl.gameModeActive = !systemCtrl.gameModeActive;
                }
            }
        }
    }

    // ── In-Place Corner Resize Handle ───────────────────────────────────────
    Rectangle {
        id: resizeHandle
        width: 18
        height: 18
        radius: 4
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 3
        color: resizeMa.containsMouse ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.12)
        visible: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
        z: 10

        Text {
            anchors.centerIn: parent
            text: "⤡"
            font.pixelSize: 12
            color: resizeMa.containsMouse ? "#0D1017" : TitanTheme.accent
        }

        MouseArea {
            id: resizeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            onClicked: {
                if (typeof systemCtrl !== "undefined" && systemCtrl)
                    systemCtrl.toggleWidgetSize("actions");
            }
        }
    }

    MouseArea {
        id: cardMa
        anchors.fill: parent
        hoverEnabled: true
        z: -1
    }
}
