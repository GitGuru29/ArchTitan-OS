import QtQuick
import ArchTitan.TitanUI

/**
 * MenuRow — one row of the titan-menu list.
 *
 * `entry` is the map produced by MenuController: title, hint, icon, keys,
 * group (drills down), crumb (breadcrumb shown for global search results).
 */
Item {
    id: root

    required property var entry
    property bool current: false

    signal clicked()
    signal hovered()

    height: 52

    // ── Selection backdrop ──────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: TitanTheme.radiusMd
        color: root.current ? TitanTheme.accentSoft : "transparent"
        Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }

        // Accent edge on the selected row.
        Rectangle {
            width: 3
            height: root.current ? parent.height - 22 : 0
            radius: 2
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            color: TitanTheme.accent
            Behavior on height { NumberAnimation { duration: TitanTheme.durFast; easing.type: TitanTheme.easingEnter } }
        }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: TitanTheme.space4
        anchors.rightMargin: TitanTheme.space4
        spacing: TitanTheme.space3

        // ── Icon tile ───────────────────────────────────────────────────────
        Rectangle {
            width: 34
            height: 34
            radius: TitanTheme.radiusSm
            anchors.verticalCenter: parent.verticalCenter
            color: root.current ? TitanTheme.accentSoft : TitanTheme.glassCard

            TitanIcon {
                anchors.centerIn: parent
                glyph: root.entry.icon
                size: 16
                color: root.current ? TitanTheme.accent : TitanTheme.textMid
            }
        }

        // ── Title + hint ────────────────────────────────────────────────────
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 34 - trailing.width - parent.spacing * 2
            spacing: 1

            Text {
                width: parent.width
                text: root.entry.title
                elide: Text.ElideRight
                color: TitanTheme.textHigh
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeBody
                font.weight: TitanTheme.weightMedium
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: root.entry.crumb !== "" ? root.entry.crumb : root.entry.hint
                elide: Text.ElideRight
                color: TitanTheme.textLow
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeLabel
            }
        }

        // ── Shortcut pill / drill-down chevron ──────────────────────────────
        Item {
            id: trailing
            height: parent.height
            width: Math.max(keysPill.visible ? keysPill.width : 0, chevron.visible ? chevron.width : 0)

            Rectangle {
                id: keysPill
                visible: !root.entry.group && root.entry.keys !== ""
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                width: keysText.implicitWidth + 16
                height: 22
                radius: TitanTheme.radiusPill
                color: TitanTheme.glassCard
                border.width: 1
                border.color: TitanTheme.borderSubtle

                Text {
                    id: keysText
                    anchors.centerIn: parent
                    text: root.entry.keys
                    color: TitanTheme.textMid
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: TitanTheme.sizeCaption + 1
                }
            }

            TitanIcon {
                id: chevron
                visible: root.entry.group
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                glyph: "\uf054"
                size: 12
                color: root.current ? TitanTheme.accent : TitanTheme.textLow
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // positionChanged (not entered): scrolling the list under a parked
        // cursor must not steal the keyboard selection.
        onPositionChanged: root.hovered()
        onClicked: root.clicked()
    }
}
