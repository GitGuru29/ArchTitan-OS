import QtQuick
import ArchTitan.TitanUI

/* TitanSlider — pill track with accent fill and draggable knob. */
Item {
    id: root

    property real value: 0.5          // 0.0 .. 1.0
    property color fillColor: TitanTheme.accent

    signal moved(real value)

    implicitWidth: 220
    implicitHeight: 26

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 8
        radius: height / 2
        color: TitanTheme.bgInset
        border.width: 1
        border.color: TitanTheme.border

        Rectangle {
            width: Math.max(height, track.width * Math.max(0, Math.min(1, root.value)))
            height: parent.height
            radius: height / 2
            color: root.enabled ? root.fillColor : TitanTheme.surface2
            Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }
        }
    }

    Rectangle {
        id: handle
        width: 20
        height: 20
        radius: width / 2
        color: TitanTheme.textHigh
        border.width: 2
        border.color: root.fillColor
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(track.width - width, track.width * Math.max(0, Math.min(1, root.value)) - width / 2))
        scale: drag.active ? 1.12 : 1.0
        Behavior on scale { NumberAnimation { duration: TitanTheme.durFast } }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
    MouseArea {
        id: drag
        anchors.fill: parent
        enabled: root.enabled
        property bool active: pressed
        onPositionChanged: if (pressed) _apply(mouse.x)
        onPressed: _apply(mouse.x)
        function _apply(px) {
            const v = Math.max(0, Math.min(1, px / track.width))
            root.value = v
            root.moved(v)
        }
    }
}
