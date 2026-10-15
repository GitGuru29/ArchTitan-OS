import QtQuick
import ArchTitan.TitanUI

/* TitanSidebarItem — navigation row with icon, label and active indicator. */
Rectangle {
    id: root

    property string glyph: ""
    property string label: ""
    property bool active: false

    signal clicked()

    implicitWidth: 200
    implicitHeight: 42
    radius: TitanTheme.radiusMd
    color: active ? TitanTheme.accentSoft : (hover.hovered ? TitanTheme.bg4 : "transparent")
    Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }

    Rectangle {
        visible: root.active
        width: 3
        height: 18
        radius: 2
        color: TitanTheme.accent
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    }

    Row {
        anchors { left: parent.left; leftMargin: TitanTheme.space3; verticalCenter: parent.verticalCenter }
        spacing: TitanTheme.space3
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            color: root.active ? TitanTheme.accent : TitanTheme.textMid
            font.family: TitanTheme.monoFamily
            font.pixelSize: 17
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.active ? TitanTheme.textHigh : TitanTheme.textMid
            font.family: TitanTheme.fontFamily
            font.pixelSize: TitanTheme.sizeBody
            font.weight: root.active ? TitanTheme.weightSemiBold : TitanTheme.weightMedium
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.clicked() }
}
