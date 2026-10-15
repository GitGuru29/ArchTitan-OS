import QtQuick
import ArchTitan.TitanUI

/* TitanEmptyState — neutral placeholder shown when a collection has no items.
 * `glyph` is a Nerd Font codepoint (default: inbox). */
Item {
    id: root

    property string glyph: "\uf01c"
    property string title: "Nothing here yet"
    property string description: ""
    property string actionText: ""
    signal actionClicked()

    implicitWidth: 280
    implicitHeight: col.implicitHeight

    Column {
        id: col
        anchors.centerIn: parent
        width: root.width
        spacing: TitanTheme.space3

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 64
            height: 64
            radius: TitanTheme.radiusLg
            color: TitanTheme.bgInset
            border.width: 1
            border.color: TitanTheme.border

            TitanIcon {
                anchors.centerIn: parent
                glyph: root.glyph
                size: 26
                color: TitanTheme.textLow
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.title
            color: TitanTheme.textHigh
            font.family: TitanTheme.fontFamily
            font.pixelSize: TitanTheme.sizeTitle
            font.weight: TitanTheme.weightSemiBold
            wrapMode: Text.WordWrap
        }

        Text {
            visible: root.description !== ""
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.description
            color: TitanTheme.textLow
            font.family: TitanTheme.fontFamily
            font.pixelSize: TitanTheme.sizeBody
            wrapMode: Text.WordWrap
        }

        TitanButton {
            visible: root.actionText !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.actionText
            variant: "secondary"
            onClicked: root.actionClicked()
        }
    }
}
