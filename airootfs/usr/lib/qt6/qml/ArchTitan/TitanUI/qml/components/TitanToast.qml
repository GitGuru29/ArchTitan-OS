import QtQuick
import ArchTitan.TitanUI

/* TitanToast — non-blocking notification toast with tone indicators and auto-dismiss. */
Rectangle {
    id: root

    property string text: ""
    property string tone: "info" // info | success | warning | danger
    property string glyph: ""
    property int timeout: 3500
    property bool opened: false

    signal dismissed()

    readonly property color toneColor: {
        if (tone === "success") return TitanTheme.success
        if (tone === "warning") return TitanTheme.warning
        if (tone === "danger")  return TitanTheme.danger
        return TitanTheme.accent
    }

    readonly property string toneGlyph: {
        if (glyph !== "") return glyph
        if (tone === "success") return "\uF00C" // check
        if (tone === "warning") return "\uF071" // exclamation triangle
        if (tone === "danger")  return "\uF057" // times circle
        return "\uF05A"                         // info circle
    }

    function show(msg, toneType) {
        if (msg) root.text = msg
        if (toneType) root.tone = toneType
        root.opened = true
        dismissTimer.restart()
    }

    function dismiss() {
        root.opened = false
        dismissTimer.stop()
        root.dismissed()
    }

    implicitWidth: row.implicitWidth + TitanTheme.space4 * 2
    implicitHeight: 40
    radius: TitanTheme.radiusControl
    color: TitanTheme.glassCard
    border.width: 1
    border.color: TitanTheme.borderHover

    opacity: opened ? 1.0 : 0.0
    scale: opened ? 1.0 : 0.95
    visible: opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingStandard } }
    Behavior on scale { NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingStandard } }

    Timer {
        id: dismissTimer
        interval: root.timeout
        running: false
        repeat: false
        onTriggered: root.dismiss()
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: TitanTheme.space2

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.toneGlyph
            font.family: TitanTheme.monoFamily
            font.pixelSize: 14
            color: root.toneColor
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.family: TitanTheme.fontFamily
            font.pixelSize: TitanTheme.sizeBody
            font.weight: TitanTheme.weightMedium
            color: TitanTheme.textHigh
        }
    }
}
