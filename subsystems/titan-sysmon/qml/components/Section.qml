import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

/**
 * Section — frosted bento card with an optional icon/title header.
 * Children are placed in a ColumnLayout, so `Layout.*` works on them.
 */
Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property string glyph: ""

    default property alias content: body.data

    color: TitanTheme.glassCard
    radius: TitanTheme.radiusCard
    border.width: 1
    border.color: TitanTheme.borderSubtle

    implicitHeight: layout.implicitHeight + TitanTheme.space4 * 2
    Layout.fillWidth: true

    ColumnLayout {
        id: layout
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: TitanTheme.space4
        }
        spacing: TitanTheme.space3

        RowLayout {
            Layout.fillWidth: true
            visible: root.title !== ""
            spacing: TitanTheme.space2

            TitanIcon {
                visible: root.glyph !== ""
                glyph: root.glyph
                size: 15
                color: TitanTheme.accent
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                text: root.title
                color: TitanTheme.textHigh
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeBody
                font.weight: TitanTheme.weightSemiBold
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.subtitle
                color: TitanTheme.textLow
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeLabel
                elide: Text.ElideLeft
                horizontalAlignment: Text.AlignRight
                Layout.maximumWidth: layout.width * 0.55
                Layout.alignment: Qt.AlignVCenter
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: TitanTheme.space3
        }
    }
}
