import QtQuick
import ArchTitan.TitanUI

/* TitanErrorState — failure placeholder with an optional retry action.
 * `glyph` is a Nerd Font codepoint (default: warning triangle). */
Item {
    id: root

    property string glyph: "\uf071"
    property string title: "Something went wrong"
    property string description: ""
    property string retryText: "Try again"
    signal retry()

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
            border.color: TitanTheme.danger

            TitanIcon {
                anchors.centerIn: parent
                glyph: root.glyph
                size: 26
                color: TitanTheme.danger
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
            visible: root.retryText !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.retryText
            variant: "secondary"
            onClicked: root.retry()
        }
    }
}
