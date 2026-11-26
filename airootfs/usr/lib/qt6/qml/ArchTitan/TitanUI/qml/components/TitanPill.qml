import QtQuick
import ArchTitan.TitanUI

/* TitanPill — capsule container for chips, tags and segmented controls. */
Rectangle {
    id: root

    property bool active: false
    property bool interactive: true
    default property alias content: row.data

    signal clicked()

    implicitWidth: row.implicitWidth + TitanTheme.space3 * 2
    implicitHeight: 28
    radius: height / 2
    color: active ? TitanTheme.accentSoft : (hover.hovered && interactive ? TitanTheme.stateHover : TitanTheme.bgInset)
    border.width: 1
    border.color: active ? TitanTheme.accentEdge : TitanTheme.border
    activeFocusOnTab: interactive
    Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: TitanTheme.space2
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -TitanTheme.focusRingOffset
        radius: root.radius + TitanTheme.focusRingOffset
        color: "transparent"
        border.width: TitanTheme.focusRingWidth
        border.color: TitanTheme.focusRing
        visible: root.activeFocus
    }

    HoverHandler { enabled: root.interactive; cursorShape: Qt.PointingHandCursor; id: hover }
    TapHandler {
        enabled: root.interactive
        onTapped: {
            root.forceActiveFocus()
            root.clicked()
        }
    }
    Keys.onReturnPressed: if (root.interactive) root.clicked()
    Keys.onSpacePressed: if (root.interactive) root.clicked()
}
