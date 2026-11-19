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

    color: TitanTheme.isDark ? TitanTheme.alphaColor(TitanTheme.surface0, 0.78)
                             : TitanTheme.alphaColor(TitanTheme.base, 0.90)
    radius: TitanTheme.radiusCard
    border.width: 1
    border.color: TitanTheme.borderSubtle
    clip: true

    implicitWidth: 0
    implicitHeight: layout.implicitHeight + TitanTheme.space4 * 2
    Layout.fillWidth: true
    Layout.minimumWidth: 0

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
            Layout.minimumWidth: 0
            Layout.maximumWidth: layout.width
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
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                visible: root.subtitle !== ""
                text: root.subtitle
                color: TitanTheme.textMid
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeCaption
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                Layout.minimumWidth: 0
                Layout.maximumWidth: Math.max(80, layout.width * 0.48)
                Layout.alignment: Qt.AlignVCenter
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.maximumWidth: layout.width
            spacing: TitanTheme.space3
        }
    }
}
