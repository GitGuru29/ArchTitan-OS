import QtQuick
import QtQuick.Window
import ArchTitan.TitanUI

/* TitanGallery — live preview of every ArchTitan.TitanUI component. */
Window {
    id: win
    width: 900
    height: 820
    visible: true
    color: TitanTheme.bg0
    title: "ArchTitan · TitanUI Gallery"

    TitanGalleryBody { anchors.fill: parent }
}
