import QtQuick
import ArchTitan.TitanUI

/* TitanSwitch — animated pill toggle. */
Item {
    id: root

    property bool checked: false

    signal toggled(bool value)

    implicitWidth: 46
    implicitHeight: 26

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? TitanTheme.accent : TitanTheme.surface0
        border.width: 1
        border.color: root.checked ? TitanTheme.accent : TitanTheme.border
        Behavior on color { ColorAnimation { duration: TitanTheme.durBase } }

        Rectangle {
            id: knob
            width: 20
            height: 20
            radius: width / 2
            y: 3
            x: root.checked ? track.width - width - 3 : 3
            color: root.checked ? TitanTheme.accentFg : TitanTheme.textMid
            Behavior on x { NumberAnimation { duration: TitanTheme.durBase; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: TitanTheme.durBase } }
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
    TapHandler {
        enabled: root.enabled
        onTapped: { root.checked = !root.checked; root.toggled(root.checked) }
    }
}
