import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanActionGrid — ArchTitan 2-Column Symmetrical Quick Action Bento Card.
 *
 * Implements a balanced 2-column action grid:
 * - Header: "Quick Actions"
 * - Uniform symmetrical rows (Night Shift, Dark Mode, Mic Mute, Awake, Screenshot, Game Mode)
 * - Sapphire Cyan active indicators
 * - Perfectly aligned (no mismatched columns or layout gaps)
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

    ColumnLayout {
        id: actionCol
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // ── Card Header ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Quick Actions"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: TitanTheme.textPrimary
            }

            Item { Layout.fillWidth: true }
        }

        // ── Symmetrical 2-Column Grid (3 rows x 2 columns) ───────────────────
        GridLayout {
            id: actionsLayout
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 6

            // Row 1, Col 1: Night Shift
            TitanActionTile {
                tileKey: "night"
                iconGlyph: "\uf06e" // eye
                title: "Night Shift"
                active: (typeof nightLightCtrl !== "undefined" && nightLightCtrl) ? nightLightCtrl.active : false
                statusText: active ? "4500K Warm" : "Off"
                onClicked: {
                    if (typeof nightLightCtrl !== "undefined" && nightLightCtrl)
                        nightLightCtrl.toggleNightLight();
                }
            }

            // Row 1, Col 2: Dark Mode
            TitanActionTile {
                tileKey: "dark"
                iconGlyph: "\uf042" // contrast
                title: "Dark Mode"
                active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.themeDark : true
                statusText: active ? "Obsidian" : "Light"
                onClicked: {
                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                        systemCtrl.themeDark = !systemCtrl.themeDark;
                }
            }

            // Row 2, Col 1: Mic Mute
            TitanActionTile {
                tileKey: "mic"
                iconGlyph: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted) ? "\uf131" : "\uf130"
                title: "Mic Mute"
                active: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sourceMuted : false
                statusText: active ? "Muted" : "Active"
                onClicked: {
                    if (typeof audioCtrl !== "undefined" && audioCtrl)
                        audioCtrl.toggleSourceMute();
                }
            }

            // Row 2, Col 2: Stay Awake
            TitanActionTile {
                tileKey: "caffeine"
                iconGlyph: "\uf0f4" // coffee
                title: "Stay Awake"
                active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.caffeineActive : false
                statusText: active ? "Active" : "Off"
                onClicked: {
                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                        systemCtrl.caffeineActive = !systemCtrl.caffeineActive;
                }
            }

            // Row 3, Col 1: Screenshot
            TitanActionTile {
                tileKey: "capture"
                iconGlyph: "\uf030" // camera
                title: "Screenshot"
                active: false
                statusText: "Region"
                onClicked: {
                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                        systemCtrl.triggerScreenshot();
                }
            }

            // Row 3, Col 2: Game Mode
            TitanActionTile {
                tileKey: "gameMode"
                iconGlyph: "\uf11b" // gamepad
                title: "Game Mode"
                active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.gameModeActive : false
                statusText: active ? "Boosted" : "Off"
                onClicked: {
                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                        systemCtrl.gameModeActive = !systemCtrl.gameModeActive;
                }
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
