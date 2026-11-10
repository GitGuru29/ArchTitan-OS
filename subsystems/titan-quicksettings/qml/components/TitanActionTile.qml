import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanActionTile — macOS-style Rounded Rectangular Action Bento Tile.
 *
 * Compact 46px tile with integrated circular glyph badge, title,
 * dynamic status text, and subtle Titan Orange active glow.
 */
Rectangle {
    id: tileRoot
    Layout.fillWidth: true
    implicitHeight: 46
    radius: TitanTheme.radiusTile
    clip: true

    property string iconGlyph: "\uf042" // contrast
    property string title: "Dark Mode"
    property string statusText: active ? "On" : "Off"
    property bool active: false

    signal clicked()

    color: active
           ? Qt.rgba(1.0, 0.42, 0.0, 0.12)
           : (tileMa.containsMouse ? TitanTheme.bgTitaniumHover : TitanTheme.bgTitanium)

    border.color: active
                  ? TitanTheme.borderActive
                  : (tileMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)
    border.width: 1

    scale: tileMa.pressed ? 0.94 : (tileMa.containsMouse ? 1.02 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
    }
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 9

        // 28px Icon Medallion
        Rectangle {
            width: 28
            height: 28
            radius: 14
            color: tileRoot.active ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.07)
            border.color: tileRoot.active ? TitanTheme.borderActive : TitanTheme.borderHairline
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: tileRoot.iconGlyph
                font.family: TitanTheme.monoFamily
                font.pixelSize: 12
                color: tileRoot.active ? "#0D1017" : TitanTheme.textMuted
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        // Title and Status
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: tileRoot.title
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: tileRoot.active ? TitanTheme.textPrimary : TitanTheme.textSecondary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: tileRoot.statusText
                font.family: TitanTheme.fontFamily
                font.pixelSize: 9
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

