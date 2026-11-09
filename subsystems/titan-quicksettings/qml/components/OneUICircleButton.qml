import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * OneUICircleButton — 100% Full-Circle Quick Action Toggle.
 *
 * 48px circle with centered glyph, spring bounce dynamics, and micro-label below.
 */
ColumnLayout {
    id: buttonRoot
    spacing: 5
    Layout.fillWidth: true

    property string iconGlyph: "\uf186"
    property string label: "Dark mode"
    property string statusText: ""
    property bool active: false
    property color activeColor: TitanTheme.accent
    property int diameter: 48

    signal clicked()

    Rectangle {
        id: circle
        Layout.preferredWidth: buttonRoot.diameter
        Layout.preferredHeight: buttonRoot.diameter
        Layout.alignment: Qt.AlignHCenter
        radius: buttonRoot.diameter / 2 // 100% Full Circle
        clip: true

        activeFocusOnTab: true
        Keys.onReturnPressed: (event) => { buttonRoot.clicked(); event.accepted = true }
        Keys.onEnterPressed:  (event) => { buttonRoot.clicked(); event.accepted = true }
        Keys.onSpacePressed:  (event) => { buttonRoot.clicked(); event.accepted = true }

        color: buttonRoot.active
               ? buttonRoot.activeColor
               : ((btnMa.containsMouse || activeFocus) ? TitanTheme.bgHover : TitanTheme.bgOneUIPill)

        border.color: activeFocus ? TitanTheme.accent
                      : buttonRoot.active ? TitanTheme.borderActive
                      : (btnMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass)
        border.width: activeFocus ? 2 : 1

        // Tactile Spring Bounce
        scale: btnMa.pressed ? 0.88 : (btnMa.containsMouse ? 1.08 : 1.0)
        Behavior on scale {
            NumberAnimation { duration: 130; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
        }
        Behavior on color { ColorAnimation { duration: 130 } }

        Text {
            anchors.centerIn: parent
            text: buttonRoot.iconGlyph
            font.family: TitanTheme.monoFamily
            font.pixelSize: Math.round(buttonRoot.diameter * 0.35)
            color: buttonRoot.active ? "#0F141C" : TitanTheme.textPrimary
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: buttonRoot.clicked()
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: buttonRoot.label
        font.family: TitanTheme.fontFamily
        font.pixelSize: Math.max(9, Math.round(buttonRoot.diameter * 0.21))
        font.weight: Font.Medium
        color: buttonRoot.active ? TitanTheme.textPrimary : TitanTheme.textSubtle
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        Layout.maximumWidth: Math.max(56, buttonRoot.diameter + 18)
    }

    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: buttonRoot.clicked()
}
