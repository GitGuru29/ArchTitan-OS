import QtQuick
import ArchTitan.TitanUI

/* TitanGalleryBody — the component showcase content, without a Window.
 * Reused by TitanGallery (interactive) and the offscreen screenshot harness. */
Item {
    id: root

    Rectangle { anchors.fill: parent; color: TitanTheme.bg0 }

    Column {
        anchors.fill: parent
        anchors.margins: TitanTheme.space6
        spacing: TitanTheme.space4

        Text {
            text: "TITAN DESIGN LANGUAGE"
            color: TitanTheme.textHigh
            font.family: TitanTheme.monoFamily
            font.pixelSize: TitanTheme.sizeDisplay
            font.bold: true
        }
        Row {
            spacing: TitanTheme.space2
            TitanBadge { text: "Design system"; tone: "info" }
            TitanBadge { text: "One UI 9.0"; tone: "success" }
            TitanBadge { text: "Catppuccin Mocha"; tone: "neutral" }
        }

        TitanCard {
            width: parent.width
            title: "Buttons & badges"
            subtitle: "TitanButton · TitanBadge"
            Row {
                spacing: TitanTheme.space3
                TitanButton { text: "Primary"; glyph: "" }
                TitanButton { text: "Secondary"; variant: "secondary" }
                TitanButton { text: "Ghost"; variant: "ghost" }
                TitanButton { text: "Danger"; variant: "danger" }
            }
        }

        TitanCard {
            width: parent.width
            title: "Controls"
            subtitle: "TitanSwitch · TitanSlider · TitanProgress"
            Column {
                spacing: TitanTheme.space3
                Row {
                    spacing: TitanTheme.space3
                    TitanSwitch { checked: true }
                    TitanSwitch { checked: false }
                }
                TitanSlider { width: 320; value: 0.62 }
                TitanProgress { width: 320; value: 0.4 }
            }
        }

        TitanCard {
            width: parent.width
            title: "Tiles & pills"
            subtitle: "TitanToggleTile · TitanPill"
            Row {
                spacing: TitanTheme.space3
                TitanToggleTile { glyph: "\uF1EB"; label: "Wi-Fi"; checked: true }
                TitanToggleTile { glyph: "\uF293"; label: "Bluetooth"; checked: false }
                TitanToggleTile { glyph: "\uF028"; label: "Audio"; checked: true }
                Column {
                    spacing: TitanTheme.space2
                    TitanPill { active: true; Text { text: "Active"; color: TitanTheme.accent; font.family: TitanTheme.fontFamily; font.pixelSize: TitanTheme.sizeBody } }
                    TitanPill { Text { text: "Idle"; color: TitanTheme.textMid; font.family: TitanTheme.fontFamily; font.pixelSize: TitanTheme.sizeBody } }
                }
            }
        }

        TitanGlassPanel {
            width: parent.width
            implicitHeight: 56
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: TitanTheme.space3
                TitanSidebarItem { width: 180; glyph: "\uF013"; label: "Appearance"; active: true }
                TitanSidebarItem { width: 180; glyph: "\uF108"; label: "Display"; active: false }
            }
        }

        TitanCard {
            width: parent.width
            title: "States & feedback"
            subtitle: "TitanSpinner · TitanSkeleton · TitanEmptyState · TitanErrorState"
            Row {
                spacing: TitanTheme.space4
                Column {
                    spacing: TitanTheme.space2
                    TitanSpinner { size: 28 }
                    TitanSkeleton { width: 160; height: 14 }
                    TitanSkeleton { width: 110; height: 14 }
                }
                TitanEmptyState {
                    width: 240
                    title: "No notifications"
                    description: "You're all caught up."
                }
                TitanErrorState {
                    width: 240
                    description: "Check your connection and retry."
                }
            }
        }
    }
}
