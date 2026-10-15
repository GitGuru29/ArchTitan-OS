import QtQuick
import ArchTitan.TitanUI

/* TitanIcon — renders a Nerd Font glyph or an image at a fixed size.
 * `glyph` is preferred for system icons; `source` for branded SVGs/PNGs. */
Item {
    id: root

    property string glyph: ""
    property url source: ""
    property color color: TitanTheme.textHigh
    property int size: 16

    implicitWidth: size
    implicitHeight: size

    Text {
        anchors.centerIn: parent
        visible: root.source.toString() === ""
        text: root.glyph
        color: root.color
        font.family: TitanTheme.monoFamily
        font.pixelSize: root.size
        renderType: Text.NativeRendering
    }

    Image {
        anchors.fill: parent
        visible: root.source.toString() !== ""
        source: root.source
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
        fillMode: Image.PreserveAspectFit
        smooth: true
    }
}
