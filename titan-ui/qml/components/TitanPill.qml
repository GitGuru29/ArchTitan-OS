import QtQuick
import ArchTitan.TitanUI

/* TitanPill — capsule container for chips, tags and segmented controls. */
Rectangle {
    id: root

    property bool active: false
    property bool interactive: true
    default property alias content: row.data

    implicitWidth: row.implicitWidth + TitanTheme.space3 * 2
    implicitHeight: 30
    radius: height / 2
    color: active ? TitanTheme.accentSoft : (hover.hovered && interactive ? TitanTheme.bg4 : TitanTheme.bgInset)
    border.width: 1
    border.color: active ? TitanTheme.accentEdge : TitanTheme.border
    Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: TitanTheme.space2
    }

    HoverHandler { enabled: root.interactive; cursorShape: Qt.PointingHandCursor; id: hover }
}
