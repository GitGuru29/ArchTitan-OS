import QtQuick
import ArchTitan.TitanUI

/* TitanButton — the single button primitive.
 * variant: "primary" | "secondary" | "ghost" | "danger" */
Rectangle {
    id: root

    property string text: ""
    property string glyph: ""
    property string variant: "primary"

    signal clicked()

    readonly property bool _primary:   variant === "primary"
    readonly property bool _secondary: variant === "secondary"
    readonly property bool _ghost:     variant === "ghost"
    readonly property bool _danger:    variant === "danger"

    implicitWidth: row.implicitWidth + TitanTheme.space4 * 2
    implicitHeight: 36
    radius: TitanTheme.radiusControl
    opacity: enabled ? 1.0 : 0.42
    activeFocusOnTab: true

    color: {
        if (_primary)   return tap.pressed ? Qt.darker(TitanTheme.accent, 1.10)
                            : hover.hovered ? Qt.lighter(TitanTheme.accent, 1.08)
                            : TitanTheme.accent
        if (_danger)    return tap.pressed ? Qt.darker(TitanTheme.danger, 1.10)
                            : hover.hovered ? Qt.lighter(TitanTheme.danger, 1.08)
                            : TitanTheme.danger
        if (_secondary) return tap.pressed ? TitanTheme.surface1
                            : hover.hovered ? TitanTheme.surface0
                            : TitanTheme.bgInset
        return tap.pressed ? TitanTheme.statePressed : hover.hovered ? TitanTheme.stateHover : "transparent"
    }
    border.width: _ghost ? 1 : 0
    border.color: hover.hovered ? TitanTheme.borderHover : TitanTheme.border

    Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }

    scale: tap.pressed ? TitanTheme.pressScale : 1.0
    Behavior on scale { NumberAnimation { duration: TitanTheme.durFast; easing.type: TitanTheme.easingStandard } }

    // Focus ring is drawn outside the button so it never collapses the layout.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -TitanTheme.focusRingOffset
        radius: root.radius + TitanTheme.focusRingOffset
        color: "transparent"
        border.width: TitanTheme.focusRingWidth
        border.color: TitanTheme.focusRing
        visible: root.activeFocus
    }

    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()
    Accessible.role: Accessible.Button
    Accessible.name: root.text

    Row {
        id: row
        anchors.centerIn: parent
        spacing: TitanTheme.space2

        Text {
            visible: root.glyph !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            color: root._primary || root._danger ? TitanTheme.accentFg : TitanTheme.textHigh
            font.family: TitanTheme.monoFamily
            font.pixelSize: 15
        }
        Text {
            visible: root.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root._primary || root._danger ? TitanTheme.accentFg : TitanTheme.textHigh
            font.family: TitanTheme.fontFamily
            font.pixelSize: TitanTheme.sizeBody
            font.weight: TitanTheme.weightSemiBold
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler {
        id: tap
        enabled: root.enabled
        onTapped: {
            root.forceActiveFocus()
            root.clicked()
        }
    }
}
