import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * OneUICircleButton — Samsung One UI 9.0 round quick action toggle.
 *
 * 52px circular button with centered glyph and descriptive label below.
 */
ColumnLayout {
    id: buttonRoot
    spacing: 6
    Layout.alignment: Qt.AlignHCenter

    property string iconGlyph: "\uf186"
    property string label: "Dark mode"
    property string statusText: ""
    property bool active: false
    property color activeColor: TitanTheme.accentBlue

    signal clicked()

    Rectangle {
        id: circle
        Layout.preferredWidth: 50
        Layout.preferredHeight: 50
        Layout.alignment: Qt.AlignHCenter
        radius: 25
        clip: true
        color: buttonRoot.active ? buttonRoot.activeColor : (btnMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill)
        border.color: buttonRoot.active ? TitanTheme.borderActive : (btnMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass)
        border.width: 1

        // Tactile Liquid Touch: spring bounce on press and hover
        scale: btnMa.pressed ? 0.91 : (btnMa.containsMouse ? 1.07 : 1.0)
        Behavior on scale {
            NumberAnimation { duration: 140; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
        }

        Behavior on color { ColorAnimation { duration: 130 } }

        Text {
            anchors.centerIn: parent
            text: buttonRoot.iconGlyph
            font.family: TitanTheme.fontFamily
            font.pixelSize: 18
            color: buttonRoot.active ? "#FFFFFF" : TitanTheme.textPrimary
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: buttonRoot.clicked()
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 1

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: buttonRoot.label
            font.family: TitanTheme.fontFamily
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: buttonRoot.active ? TitanTheme.textPrimary : TitanTheme.textSubtle
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            visible: buttonRoot.statusText.length > 0
            Layout.alignment: Qt.AlignHCenter
            text: buttonRoot.statusText
            font.family: TitanTheme.fontFamily
            font.pixelSize: 9
            color: buttonRoot.active ? TitanTheme.cyan : TitanTheme.textSubtle
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: label
}
