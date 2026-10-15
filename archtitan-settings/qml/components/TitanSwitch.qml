import QtQuick
import QtQuick.Controls.Basic
import ArchTitanSettings
import ArchTitan.TitanUI

Switch {
    id: root

    property color onColor:  TitanTheme.accent
    property color offColor: TitanTheme.surface0

    implicitWidth: 44
    implicitHeight: 24

    indicator: Rectangle {
        width: root.implicitWidth
        height: root.implicitHeight
        radius: height / 2
        color: root.checked ? root.onColor : root.offColor
        border.width: 1
        border.color: root.checked ? "transparent" : TitanTheme.border

        Behavior on color { ColorAnimation { duration: TitanTheme.durBase } }

        // Knob
        Rectangle {
            width: 18; height: 18
            radius: 9
            color: root.checked ? TitanTheme.accentFg : TitanTheme.textHigh
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3
            Behavior on x { NumberAnimation { duration: TitanTheme.durBase; easing.type: Easing.OutCubic } }

            // Subtle drop shadow imitation
            Rectangle {
                anchors { fill: parent; margins: 1 }
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(0, 0, 0, 0.13)
            }
        }
    }

    contentItem: Item {}
}
