import QtQuick
import ArchTitan.TitanUI

/* TitanCard — bento card container with an optional title header. */
Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool glass: true
    default property alias content: body.data

    implicitWidth: 260
    implicitHeight: body.implicitHeight + (header.visible ? header.implicitHeight + TitanTheme.space3 : 0) + TitanTheme.space4 * 2
    radius: TitanTheme.radiusCard
    color: glass ? TitanTheme.glassCard : TitanTheme.bg2
    border.width: 1
    border.color: TitanTheme.borderSubtle

    Column {
        id: header
        visible: root.title !== ""
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: TitanTheme.space4 }
        spacing: 2

        Text {
            text: root.title
            color: TitanTheme.textHigh
            font.family: TitanTheme.fontFamily
            font.pixelSize: TitanTheme.sizeTitle
            font.weight: TitanTheme.weightSemiBold
        }
        Text {
            visible: root.subtitle !== ""
            text: root.subtitle
            color: TitanTheme.textLow
            font.family: TitanTheme.fontFamily
            font.pixelSize: TitanTheme.sizeLabel
        }
    }

    Column {
        id: body
        spacing: TitanTheme.space3
        anchors {
            left: parent.left; right: parent.right; bottom: parent.bottom
            top: header.visible ? header.bottom : parent.top
            margins: TitanTheme.space4
            topMargin: header.visible ? TitanTheme.space3 : TitanTheme.space4
        }
    }
}
