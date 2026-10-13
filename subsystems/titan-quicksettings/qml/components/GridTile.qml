import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../style"

/**
 * GridTile — quick-action button for the tool grid.
 *
 * Squircle-shaped, flexible-width control with a Nerd Font glyph, hover /
 * press feedback and an optional "active" filled state.
 */
Rectangle {
    id: tileRoot

    Layout.fillWidth: true
    implicitHeight: 46

    property string source: "\uf059"
    property string tip: ""
    property int glyphSize: 16
    property bool active: false

    signal activated()

    radius: 23
    color: {
        if (ma.pressed) return TitanTheme.bgPressed;
        if (active) return TitanTheme.accent;
        if (ma.containsMouse) return TitanTheme.bgHover;
        return TitanTheme.bgSurfaceAlt;
    }
    border.color: active ? TitanTheme.borderActive
                          : (ma.containsMouse ? TitanTheme.borderHover : TitanTheme.borderSubtle)
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    // Subtle "lift" on hover
    scale: ma.containsMouse ? 1.02 : 1.0
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    HavenIcon {
        anchors.centerIn: parent
        source: tileRoot.source
        tint: tileRoot.active ? TitanTheme.accentText
                              : (tileRoot.ma.containsMouse ? TitanTheme.textPrimary : TitanTheme.textMuted)
        glyphSize: tileRoot.glyphSize
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tileRoot.activated()
    }

    ToolTip.visible: ma.containsMouse && tip.length > 0
    ToolTip.text: tip
    ToolTip.delay: 450
    ToolTip.toolTip.background: Rectangle {
        color: TitanTheme.bgWindow
        border.color: TitanTheme.borderSubtle
        width: 1
        radius: 8
    }
    ToolTip.toolTip.contentItem: Text {
        text: tileRoot.tip
        color: TitanTheme.textPrimary
        font.family: TitanTheme.fontFamily
        font.pixelSize: TitanTheme.sizeSmall
        padding: 6
    }

    Accessible.role: Accessible.Button
    Accessible.name: tip.length > 0 ? tip : "quick action"
    Accessible.onPressAction: tileRoot.activated()
}