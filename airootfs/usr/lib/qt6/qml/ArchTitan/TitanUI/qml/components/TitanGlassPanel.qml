import QtQuick
import ArchTitan.TitanUI

/* TitanGlassPanel — frosted glass surface (blur supplied by Hyprland layer rules). */
Rectangle {
    id: root

    property bool strong: false
    default property alias content: inner.data

    radius: TitanTheme.radiusBento
    color: strong ? TitanTheme.glass : TitanTheme.glassAlt
    border.width: 1
    border.color: TitanTheme.borderSubtle

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: TitanTheme.space4
    }
}
