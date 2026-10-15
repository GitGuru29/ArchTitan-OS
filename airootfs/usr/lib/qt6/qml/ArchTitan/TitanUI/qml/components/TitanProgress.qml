import QtQuick
import ArchTitan.TitanUI

/* TitanProgress — thin accent progress track. */
Item {
    id: root

    property real value: 0.0          // 0.0 .. 1.0
    property color fillColor: TitanTheme.accent

    implicitWidth: 200
    implicitHeight: 8

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: TitanTheme.bgInset
        border.width: 1
        border.color: TitanTheme.border

        Rectangle {
            width: Math.max(0, Math.min(1, root.value)) * (parent.width - 2)
            height: parent.height - 2
            x: 1; y: 1
            radius: height / 2
            color: root.fillColor
            Behavior on width { NumberAnimation { duration: TitanTheme.durBase; easing.type: Easing.OutCubic } }
        }
    }
}
