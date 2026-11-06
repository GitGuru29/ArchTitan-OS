import QtQuick
import ArchTitan.TitanUI

/* TitanFlyout — lightweight popup and flyout panel surface. */
Rectangle {
    id: root

    property bool opened: false
    default property alias content: inner.data

    signal closed()

    function open() { root.opened = true }
    function close() {
        root.opened = false
        root.closed()
    }

    radius: TitanTheme.radiusCard
    color: TitanTheme.glassCard
    border.width: 1
    border.color: TitanTheme.borderHover

    opacity: opened ? 1.0 : 0.0
    scale: opened ? 1.0 : 0.96
    visible: opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: TitanTheme.durFast; easing.type: TitanTheme.easingStandard } }
    Behavior on scale { NumberAnimation { duration: TitanTheme.durFast; easing.type: TitanTheme.easingStandard } }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: TitanTheme.space3
    }
}

