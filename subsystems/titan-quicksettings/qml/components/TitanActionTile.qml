import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanActionTile — ArchTitan macOS-style Quick Action Bento Tile.
 *
 * Implements a uniform, perfectly aligned action button:
 * - Icon + Title + Status
 * - Active state glows Sapphire Cyan
 * - Uniform symmetrical sizing (no layout breakage or gaps)
 * - In-place reordering support
 */
Rectangle {
    id: tileRoot
    Layout.fillWidth: true
    implicitHeight: 50
    radius: 12
    clip: true

    property string tileKey: "focus"
    property string iconGlyph: "\uf042" // contrast
    property string title: "Dark Mode"
    property string statusText: active ? "On" : "Off"
    property bool active: false

    signal clicked()

    color: active
           ? Qt.rgba(0.04, 0.52, 1.0, 0.16)
           : (tileMa.pressed ? TitanTheme.bgPressed : (tileMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgInset))

    border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                  ? TitanTheme.accent
                  : (active ? TitanTheme.accent : (tileMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline))
    border.width: 1

    scale: tileMa.pressed ? 0.95 : (tileMa.containsMouse ? 1.02 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
    }
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        // Icon Medallion
        Rectangle {
            width: 28
            height: 28
            radius: 14
            color: tileRoot.active ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.08)

            Text {
                anchors.centerIn: parent
                text: tileRoot.iconGlyph
                font.family: TitanTheme.monoFamily
                font.pixelSize: 13
                color: tileRoot.active ? "#FFFFFF" : TitanTheme.textMuted
            }
        }

        // Title and Status
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

    MouseArea {
        id: tileMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tileRoot.clicked()
    }
}
