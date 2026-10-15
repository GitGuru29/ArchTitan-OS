import QtQuick
import ArchTitan.TitanUI

/* TitanBadge — small status pill. tone: "neutral"|"success"|"warning"|"danger"|"info" */
Rectangle {
    id: root

    property string text: ""
    property string tone: "neutral"

    readonly property color _c: tone === "success" ? TitanTheme.success
                               : tone === "warning" ? TitanTheme.warning
                               : tone === "danger"  ? TitanTheme.danger
                               : tone === "info"    ? TitanTheme.info
                               : TitanTheme.textLow

    implicitWidth: label.implicitWidth + TitanTheme.space3 * 2
    implicitHeight: 22
    radius: height / 2
    color: Qt.rgba(_c.r, _c.g, _c.b, 0.16)
    border.width: 1
    border.color: Qt.rgba(_c.r, _c.g, _c.b, 0.45)

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root._c
        font.family: TitanTheme.fontFamily
        font.pixelSize: TitanTheme.sizeCaption + 1
        font.weight: TitanTheme.weightSemiBold
    }
}
